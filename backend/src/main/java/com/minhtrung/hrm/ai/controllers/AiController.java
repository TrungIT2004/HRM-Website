package com.minhtrung.hrm.ai.controllers;

import java.io.IOException;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.minhtrung.hrm.ai.dtos.requests.ChatQueryRequest;
import com.minhtrung.hrm.ai.dtos.responses.ChatQueryResponse;
import com.minhtrung.hrm.ai.services.AiServiceClient;
import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;
import com.minhtrung.hrm.common.context.RequestContextHolder;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
@Slf4j
public class AiController {

    private final AiServiceClient aiServiceClient;

    /**
     * Nhân viên hỏi đáp với Chatbot RAG.
     * POST /api/ai/chat
     */
    @PostMapping("/chat")
    public ResponseEntity<ChatQueryResponse> chatWithBot(@Valid @RequestBody ChatQueryRequest request) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        log.info("User {} ({}) đặt câu hỏi cho AI RAG", currentUser.getUserId(), currentUser.getFullName());

        ChatQueryResponse response = aiServiceClient.queryChatbot(
                request.getQuestion(),
                request.getTopK(),
                currentUser
        );
        return ResponseEntity.ok(response);
    }

    /**
     * Lấy danh sách tài liệu công ty đã nạp.
     * GET /api/ai/documents
     */
    @GetMapping("/documents")
    public ResponseEntity<Object> listDocuments(
            @RequestParam(value = "status", required = false) String status,
            @RequestParam(value = "search", required = false) String search
    ) {
        return ResponseEntity.ok(aiServiceClient.listDocuments(status, search));
    }

    /**
     * Xem các chunk và câu hỏi giả định của 1 tài liệu.
     * GET /api/ai/documents/{documentId}/chunks
     */
    @GetMapping("/documents/{documentId}/chunks")
    public ResponseEntity<Object> getDocumentChunks(@PathVariable String documentId) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        checkAdminOrHrPermission(currentUser);
        return ResponseEntity.ok(aiServiceClient.getDocumentChunks(documentId));
    }

    /**
     * Tải lên tài liệu mới (Word, PDF, Excel).
     * Chỉ dành cho HR, Ban Giám Đốc hoặc Quản trị viên hệ thống.
     * POST /api/ai/documents/upload
     */
    @PostMapping(value = "/documents/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Object> uploadDocument(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "allowedRoles", required = false) String allowedRoles,
            @RequestParam(value = "allowedDepartments", required = false) String allowedDepartments,
            @RequestParam(value = "overwrite", defaultValue = "false") boolean overwrite
    ) throws IOException {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        checkAdminOrHrPermission(currentUser);
        log.info("User {} ({}) đang upload tài liệu: {}", currentUser.getUserId(), currentUser.getFullName(), file.getOriginalFilename());

        Object result = aiServiceClient.uploadDocument(
                file,
                allowedRoles,
                allowedDepartments,
                currentUser,
                overwrite
        );
        return ResponseEntity.ok(result);
    }

    /**
     * Cập nhật / Thay thế file tài liệu cũ (In-Place Replacement).
     * Chỉ dành cho HR, Ban Giám Đốc hoặc Quản trị viên hệ thống.
     * PUT /api/ai/documents/{documentId}
     */
    @PutMapping(value = "/documents/{documentId}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Object> updateDocument(
            @PathVariable String documentId,
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "allowedRoles", required = false) String allowedRoles,
            @RequestParam(value = "allowedDepartments", required = false) String allowedDepartments
    ) throws IOException {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        checkAdminOrHrPermission(currentUser);
        log.info("User {} ({}) đang cập nhật tài liệu ID: {}", currentUser.getUserId(), currentUser.getFullName(), documentId);

        Object result = aiServiceClient.updateDocument(
                documentId,
                file,
                allowedRoles,
                allowedDepartments,
                currentUser
        );
        return ResponseEntity.ok(result);
    }

    /**
     * Xóa tài liệu khỏi hệ thống và CSDL Vector.
     * Chỉ dành cho HR, Ban Giám Đốc hoặc Quản trị viên hệ thống.
     * DELETE /api/ai/documents/{documentId}
     */
    @DeleteMapping("/documents/{documentId}")
    public ResponseEntity<Object> deleteDocument(@PathVariable String documentId) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        checkAdminOrHrPermission(currentUser);
        log.info("User {} ({}) đang xóa tài liệu ID: {}", currentUser.getUserId(), currentUser.getFullName(), documentId);

        Object result = aiServiceClient.deleteDocument(documentId);
        return ResponseEntity.ok(result);
    }

    /**
     * Kiểm tra phân quyền: Chỉ HR (Human Resources), Ban Giám Đốc (Executive Leadership)
     * hoặc Quản trị viên (IT System Admin) mới có quyền quản lý tài liệu.
     */
    private void checkAdminOrHrPermission(TokenPayload currentUser) {
        if (currentUser == null) {
            throw new AccessDeniedException("Yêu cầu đăng nhập trước khi thực hiện thao tác!");
        }
        boolean isExecutive = "Executive Leadership".equalsIgnoreCase(currentUser.getDepartment());
        boolean isHR = "Human Resources".equalsIgnoreCase(currentUser.getDepartment());
        boolean isSysAdmin = "Information Technology".equalsIgnoreCase(currentUser.getDepartment())
                && currentUser.getJob() != null
                && (currentUser.getJob().contains("System Administrator") || currentUser.getJob().contains("Admin"));

        if (!isExecutive && !isHR && !isSysAdmin) {
            throw new AccessDeniedException("Chỉ có Phòng Nhân sự (HR), Ban Giám Đốc hoặc Quản trị viên hệ thống mới có quyền quản lý tài liệu quy chế!");
        }
    }
}
