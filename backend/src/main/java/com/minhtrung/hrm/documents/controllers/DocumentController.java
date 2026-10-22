package com.minhtrung.hrm.documents.controllers;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;
import com.minhtrung.hrm.common.context.RequestContextHolder;
import com.minhtrung.hrm.documents.dtos.requests.UpsertDocumentRequest;
import com.minhtrung.hrm.documents.dtos.responses.DocumentResponse;
import com.minhtrung.hrm.documents.enums.DocumentCategory;
import com.minhtrung.hrm.documents.enums.DocumentErrorCode;
import com.minhtrung.hrm.documents.exceptions.DocumentException;
import com.minhtrung.hrm.documents.services.DocumentService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/documents")
@RequiredArgsConstructor
public class DocumentController {

    private final DocumentService documentService;

    private TokenPayload currentUser() {
        return RequestContextHolder.get().getTokenPayload();
    }

    // ponytail: SecurityConfig permitAll toàn cục, filter không set context khi thiếu/hết hạn token —
    // controller tự chặn thay vì NPE 500.
    private TokenPayload requireUser() {
        TokenPayload p = currentUser();
        if (p == null || p.getUserId() == null) {
            throw new DocumentException(DocumentErrorCode.UNAUTHORIZED_ACTION, "Phiên đăng nhập hết hạn, vui lòng đăng nhập lại!");
        }
        return p;
    }

    @GetMapping
    public ResponseEntity<List<DocumentResponse>> list(
            @RequestParam(required = false) DocumentCategory category) {
        return ResponseEntity.ok(documentService.list(category));
    }

    @GetMapping("/{documentId}")
    public ResponseEntity<DocumentResponse> get(@PathVariable UUID documentId) {
        return ResponseEntity.ok(documentService.get(documentId));
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<DocumentResponse> upload(
            @RequestParam("file") MultipartFile file,
            @Valid @ModelAttribute UpsertDocumentRequest meta) {
        TokenPayload p = requireUser();
        return ResponseEntity.status(HttpStatus.CREATED).body(documentService.upload(
                file, meta, p.getUserId(), p.getFullName()));
    }

    @PutMapping(value = "/{documentId}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<DocumentResponse> update(
            @PathVariable UUID documentId,
            @RequestParam(value = "file", required = false) MultipartFile file,
            @Valid @ModelAttribute UpsertDocumentRequest meta) {
        return ResponseEntity.ok(documentService.update(documentId, file, meta, requireUser().getUserId()));
    }

    @DeleteMapping("/{documentId}")
    public ResponseEntity<Map<String, String>> delete(@PathVariable UUID documentId) {
        documentService.delete(documentId, requireUser().getUserId());
        return ResponseEntity.ok(Map.of("message", "Đã xóa mẫu đơn thành công"));
    }
}
