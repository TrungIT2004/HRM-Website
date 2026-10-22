package com.minhtrung.hrm.documents.services;

import java.io.IOException;
import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import com.minhtrung.hrm.documents.dtos.requests.UpsertDocumentRequest;
import com.minhtrung.hrm.documents.dtos.responses.DocumentResponse;
import com.minhtrung.hrm.documents.entities.Document;
import com.minhtrung.hrm.documents.enums.DocumentCategory;
import com.minhtrung.hrm.documents.enums.DocumentErrorCode;
import com.minhtrung.hrm.documents.enums.DocumentFileType;
import com.minhtrung.hrm.documents.exceptions.DocumentException;
import com.minhtrung.hrm.documents.repositories.DocumentRepository;
import com.minhtrung.hrm.permissions.enums.PermissionKey;
import com.minhtrung.hrm.permissions.services.PermissionService;
import com.minhtrung.hrm.services.FileStorageService;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class DocumentService {

    private static final long MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB

    private final DocumentRepository documentRepository;
    private final FileStorageService fileStorageService;
    private final PermissionService permissionService;

    @Transactional(readOnly = true)
    public List<DocumentResponse> list(DocumentCategory category) {
        List<Document> docs = category == null
                ? documentRepository.findByIsActiveTrueOrderByCreatedAtDesc()
                : documentRepository.findByIsActiveTrueAndCategoryOrderByCreatedAtDesc(category);
        return docs.stream().map(DocumentResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public DocumentResponse get(UUID documentId) {
        return DocumentResponse.from(findActive(documentId));
    }

    @Transactional
    public DocumentResponse upload(MultipartFile file, UpsertDocumentRequest meta, UUID uploaderId, String uploaderName) {
        requireManage(uploaderId);
        Stored stored = store(file);
        Document saved = documentRepository.save(Document.builder()
                .category(meta.getCategory())
                .documentName(file.getOriginalFilename())
                .documentTitle(meta.getDocumentTitle().trim())
                .fileUrl("/uploads/templates/" + stored.fileName())
                .filePath("templates/" + stored.fileName())
                .fileType(stored.fileType())
                .fileSize(file.getSize())
                .summary(meta.getSummary())
                .uploaderId(uploaderId)
                .uploaderName(uploaderName)
                .build());
        return DocumentResponse.from(saved);
    }

    @Transactional
    public DocumentResponse update(UUID documentId, MultipartFile file, UpsertDocumentRequest meta, UUID userId) {
        requireManage(userId);
        Document doc = findActive(documentId);
        doc.setDocumentTitle(meta.getDocumentTitle().trim());
        doc.setCategory(meta.getCategory());
        doc.setSummary(meta.getSummary());
        if (file != null && !file.isEmpty()) {
            Stored stored = store(file);
            fileStorageService.deleteFile(doc.getFilePath());
            doc.setDocumentName(file.getOriginalFilename());
            doc.setFileUrl("/uploads/templates/" + stored.fileName());
            doc.setFilePath("templates/" + stored.fileName());
            doc.setFileType(stored.fileType());
            doc.setFileSize(file.getSize());
        }
        return DocumentResponse.from(documentRepository.save(doc));
    }

    @Transactional
    public void delete(UUID documentId, UUID userId) {
        requireManage(userId);
        Document doc = findActive(documentId);
        // ponytail: soft-delete, giữ file trên đĩa để link cũ không gãy — xóa cứng khi chính sách lưu trữ yêu cầu
        doc.setIsActive(false);
        documentRepository.save(doc);
    }

    private Document findActive(UUID documentId) {
        return documentRepository.findByDocumentIdAndIsActiveTrue(documentId)
                .orElseThrow(() -> new DocumentException(DocumentErrorCode.DOCUMENT_NOT_FOUND, "Không tìm thấy mẫu đơn"));
    }

    private Stored store(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new DocumentException(DocumentErrorCode.DOCUMENT_NOT_FOUND, "File không được để trống");
        }
        if (file.getSize() > MAX_FILE_SIZE) {
            throw new DocumentException(DocumentErrorCode.FILE_TOO_LARGE, "File vượt quá giới hạn 10MB");
        }
        DocumentFileType type = DocumentFileType.fromFilename(file.getOriginalFilename());
        if (type == null) {
            throw new DocumentException(DocumentErrorCode.INVALID_FILE_TYPE, "Chỉ chấp nhận file .docx, .doc, .pdf, .xlsx, .xls, .ppt, .pptx");
        }
        try {
            return new Stored(fileStorageService.storeFile(file, "templates"), type);
        } catch (IOException e) {
            throw new DocumentException(DocumentErrorCode.DOCUMENT_NOT_FOUND, "Không thể lưu file: " + e.getMessage());
        }
    }

    // ponytail: chỉ xét grant DOCUMENT_UPLOAD (HR/Exec/SysAdmin đã được backfill).
    // Trưởng phòng thường cần thì admin tick thêm ở /admin — không hardcode dept/job ở đây.
    private void requireManage(UUID userId) {
        if (userId == null) {
            throw new DocumentException(DocumentErrorCode.UNAUTHORIZED_ACTION, "Yêu cầu đăng nhập trước khi thực hiện thao tác!");
        }
        if (permissionService.hasPermission(userId, PermissionKey.DOCUMENT_UPLOAD)) return;
        throw new DocumentException(DocumentErrorCode.UNAUTHORIZED_ACTION, "Bạn không có quyền đăng tải mẫu đơn!");
    }

    private record Stored(String fileName, DocumentFileType fileType) {
    }
}
