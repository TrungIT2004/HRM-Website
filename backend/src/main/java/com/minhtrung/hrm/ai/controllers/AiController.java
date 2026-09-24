package com.minhtrung.hrm.ai.controllers;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import com.minhtrung.hrm.employees.enums.DepartmentName;

import org.springframework.http.HttpHeaders;
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
import org.springframework.web.servlet.mvc.method.annotation.ResponseBodyEmitter;

import com.minhtrung.hrm.ai.dtos.requests.ChatQueryRequest;
import com.minhtrung.hrm.ai.dtos.requests.UpdateConversationTitleRequest;
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
     * Nhân viên hỏi đáp với Chatbot RAG (hỗ trợ lưu lịch sử & Multi-turn Memory).
     * POST /api/ai/chat
     */
    @PostMapping("/chat")
    public ResponseEntity<ChatQueryResponse> chatWithBot(@Valid @RequestBody ChatQueryRequest request) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        log.info("User {} ({}) đặt câu hỏi cho AI RAG (ConvId: {})",
                currentUser.getUserId(), currentUser.getFullName(), request.getConversationId());

        ChatQueryResponse response = aiServiceClient.queryChatbot(
                request.getQuestion(),
                request.getConversationId(),
                request.getTopK(),
                currentUser
        );
        return ResponseEntity.ok(response);
    }

    /**
     * Nhân viên hỏi đáp với Chatbot RAG ở chế độ Streaming (Server-Sent Events - SSE).
     * 
     * Endpoint: POST /api/ai/chat/stream
     * Content-Type: application/json
     * Produces: text/event-stream;charset=UTF-8
     * 
     * Luồng hoạt động:
     * - Trích xuất thông tin nhân viên (User ID, Vai trò, Phòng ban) từ JWT Token thông qua RequestContextHolder.
     * - Khởi tạo ResponseBodyEmitter với thời gian chờ (timeout) 3 phút.
     * - Chuyển tiếp request sang AI Service (FastAPI) bất đồng bộ và truyền từng dòng token SSE về cho giao diện người dùng.
     * 
     * @param request DTO chứa câu hỏi (question), ID cuộc trò chuyện (conversationId) và topK
     * @return ResponseBodyEmitter truyền luồng dữ liệu thời gian thực
     */
    @PostMapping(value = "/chat/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public ResponseBodyEmitter streamChatWithBot(@Valid @RequestBody ChatQueryRequest request) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        log.info("User {} ({}) đặt câu hỏi streaming cho AI RAG (ConvId: {})",
                currentUser.getUserId(), currentUser.getFullName(), request.getConversationId());

        ResponseBodyEmitter emitter = new ResponseBodyEmitter(180_000L); // 3 phút timeout
        aiServiceClient.streamChatbot(
                request.getQuestion(),
                request.getConversationId(),
                request.getTopK(),
                currentUser,
                emitter
        );
        return emitter;
    }

    /**
     * Lấy danh sách các cuộc hội thoại của nhân viên hiện tại.
     * GET /api/ai/conversations
     */
    @GetMapping("/conversations")
    public ResponseEntity<Object> listMyConversations() {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        String userId = currentUser.getUserId() != null ? currentUser.getUserId().toString() : "ANONYMOUS";
        return ResponseEntity.ok(aiServiceClient.listConversations(userId));
    }

    /**
     * Lấy chi tiết toàn bộ tin nhắn trong một cuộc hội thoại.
     * GET /api/ai/conversations/{conversationId}/messages
     */
    @GetMapping("/conversations/{conversationId}/messages")
    public ResponseEntity<Object> getConversationMessages(@PathVariable String conversationId) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        String userId = currentUser.getUserId() != null ? currentUser.getUserId().toString() : "ANONYMOUS";
        return ResponseEntity.ok(aiServiceClient.getConversationMessages(conversationId, userId));
    }

    /**
     * Xóa một cuộc trò chuyện.
     * DELETE /api/ai/conversations/{conversationId}
     */
    @DeleteMapping("/conversations/{conversationId}")
    public ResponseEntity<Object> deleteMyConversation(@PathVariable String conversationId) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        String userId = currentUser.getUserId() != null ? currentUser.getUserId().toString() : "ANONYMOUS";
        return ResponseEntity.ok(aiServiceClient.deleteConversation(conversationId, userId));
    }

    /**
     * Đổi tên tiêu đề cuộc trò chuyện thủ công.
     * PUT /api/ai/conversations/{conversationId}
     */
    @PutMapping("/conversations/{conversationId}")
    public ResponseEntity<Object> updateMyConversationTitle(
            @PathVariable String conversationId,
            @Valid @RequestBody UpdateConversationTitleRequest request
    ) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        String userId = currentUser.getUserId() != null ? currentUser.getUserId().toString() : "ANONYMOUS";
        return ResponseEntity.ok(aiServiceClient.updateConversationTitle(conversationId, request.getTitle(), userId));
    }

    /**
     * Kích hoạt AI tự động sinh lại tiêu đề 3-5 từ cho cuộc trò chuyện.
     * POST /api/ai/conversations/{conversationId}/generate-title
     */
    @PostMapping("/conversations/{conversationId}/generate-title")
    public ResponseEntity<Object> regenerateMyConversationTitle(@PathVariable String conversationId) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        String userId = currentUser.getUserId() != null ? currentUser.getUserId().toString() : "ANONYMOUS";
        return ResponseEntity.ok(aiServiceClient.regenerateConversationTitle(conversationId, userId));
    }

    /**
     * Lấy danh sách tài liệu công ty đã nạp.
     * Áp dụng phân quyền:
     * - Ban Giám Đốc (Executive Leadership) & Admin: Có thể xem tất cả tài liệu hoặc lọc theo bất kỳ phòng ban nào.
     * - Trưởng phòng & Nhân viên: Chỉ có thể xem tài liệu toàn công ty ('ALL') hoặc tài liệu thuộc phòng ban của mình.
     * GET /api/ai/documents
     */
    @GetMapping("/documents")
    public ResponseEntity<Object> listDocuments(
            @RequestParam(value = "status", required = false) String status,
            @RequestParam(value = "search", required = false) String search,
            @RequestParam(value = "department", required = false) String department
    ) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        String userDept = currentUser != null ? currentUser.getDepartment() : null;

        boolean isExecutive = currentUser != null && (
                "Executive Leadership".equalsIgnoreCase(currentUser.getDepartment())
                || (currentUser.getJob() != null && (currentUser.getJob().contains("CEO") || currentUser.getJob().contains("Director") || currentUser.getJob().contains("Chairman")))
                || ("Information Technology".equalsIgnoreCase(currentUser.getDepartment()) && currentUser.getJob() != null && currentUser.getJob().contains("Admin"))
        );

        // Ban Giám Đốc hoặc Quản trị viên không bị giới hạn phòng ban truy cập
        String enforcementUserDept = isExecutive ? null : userDept;

        // Chuẩn hóa bộ lọc department nếu người dùng truyền lên (nếu là "ALL" hoặc để trống -> xem tất cả tài liệu có quyền xem)
        String filterDepartment = null;
        if (department != null && !department.isBlank() && !department.equalsIgnoreCase("ALL")) {
            if (!DepartmentName.isValid(department)) {
                throw new IllegalArgumentException("Phòng ban lọc không hợp lệ: " + department);
            }
            filterDepartment = DepartmentName.fromString(department);
        }

        return ResponseEntity.ok(aiServiceClient.listDocuments(status, search, filterDepartment, enforcementUserDept));
    }

    /**
     * Tải xuống tài liệu gốc qua Spring Boot Gateway (áp dụng kiểm tra phân quyền PBAC).
     * GET /api/ai/documents/{documentId}/download
     */
    @GetMapping("/documents/{documentId}/download")
    public ResponseEntity<byte[]> downloadDocument(@PathVariable String documentId) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        String userDept = currentUser != null ? currentUser.getDepartment() : null;

        boolean isExecutive = currentUser != null && (
                "Executive Leadership".equalsIgnoreCase(currentUser.getDepartment())
                || (currentUser.getJob() != null && (currentUser.getJob().contains("CEO") || currentUser.getJob().contains("Director") || currentUser.getJob().contains("Chairman")))
                || ("Information Technology".equalsIgnoreCase(currentUser.getDepartment()) && currentUser.getJob() != null && currentUser.getJob().contains("Admin"))
        );

        String enforcementUserDept = isExecutive ? null : userDept;

        try {
            ResponseEntity<byte[]> response = aiServiceClient.downloadDocument(documentId, enforcementUserDept);

            HttpHeaders responseHeaders = new HttpHeaders();
            if (response.getHeaders().getContentType() != null) {
                responseHeaders.setContentType(response.getHeaders().getContentType());
            } else {
                responseHeaders.setContentType(MediaType.APPLICATION_OCTET_STREAM);
            }
            if (response.getHeaders().getContentDisposition() != null) {
                responseHeaders.setContentDisposition(response.getHeaders().getContentDisposition());
            }

            return new ResponseEntity<>(response.getBody(), responseHeaders, response.getStatusCode());
        } catch (org.springframework.web.client.HttpStatusCodeException ex) {
            return ResponseEntity.status(ex.getStatusCode()).body(ex.getResponseBodyAsByteArray());
        }
    }

    /**
     * Xem các chunk và câu hỏi giả định của 1 tài liệu.
     * GET /api/ai/documents/{documentId}/chunks
     */
    @GetMapping("/documents/{documentId}/chunks")
    public ResponseEntity<Object> getDocumentChunks(@PathVariable String documentId) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        checkAdminOrHrOrDeptHeadPermission(currentUser);
        return ResponseEntity.ok(aiServiceClient.getDocumentChunks(documentId));
    }

    /**
     * Tải lên tài liệu mới (Word, PDF, Excel).
     * Phân quyền:
     * - Ban Giám Đốc (Executive Leadership) / Admin: Toàn quyền (upload cho ALL hoặc bất kỳ phòng ban nào).
     * - Phòng Nhân Sự (Human Resources): Upload cho ALL hoặc phòng ban Human Resources.
     * - Trưởng phòng chức năng: CHỈ được upload tài liệu cho chính phòng ban của mình.
     * - Nhân viên thường: Không có quyền upload.
     * POST /api/ai/documents/upload
     */
    @PostMapping(value = "/documents/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Object> uploadDocument(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "allowedDepartments", required = false) String allowedDepartments,
            @RequestParam(value = "overwrite", defaultValue = "false") boolean overwrite
    ) throws IOException {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        String effectiveDepartments = validateAndAuthorizeDepartmentScope(currentUser, allowedDepartments);

        log.info("User {} ({}) đang upload tài liệu: {} (Phòng ban áp dụng: {})",
                currentUser.getUserId(), currentUser.getFullName(), file.getOriginalFilename(), effectiveDepartments);

        Object result = aiServiceClient.uploadDocument(
                file,
                effectiveDepartments,
                currentUser,
                overwrite
        );
        return ResponseEntity.ok(result);
    }

    /**
     * Cập nhật / Thay thế file tài liệu cũ (In-Place Replacement).
     * PUT /api/ai/documents/{documentId}
     */
    @PutMapping(value = "/documents/{documentId}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Object> updateDocument(
            @PathVariable String documentId,
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "allowedDepartments", required = false) String allowedDepartments
    ) throws IOException {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        String effectiveDepartments = validateAndAuthorizeDepartmentScope(currentUser, allowedDepartments);

        log.info("User {} ({}) đang cập nhật tài liệu ID: {} (Phòng ban áp dụng: {})",
                currentUser.getUserId(), currentUser.getFullName(), documentId, effectiveDepartments);

        Object result = aiServiceClient.updateDocument(
                documentId,
                file,
                effectiveDepartments,
                currentUser
        );
        return ResponseEntity.ok(result);
    }

    /**
     * Xóa tài liệu khỏi hệ thống và CSDL Vector.
     * DELETE /api/ai/documents/{documentId}
     */
    @DeleteMapping("/documents/{documentId}")
    public ResponseEntity<Object> deleteDocument(@PathVariable String documentId) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        checkAdminOrHrOrDeptHeadPermission(currentUser);
        log.info("User {} ({}) đang xóa tài liệu ID: {}", currentUser.getUserId(), currentUser.getFullName(), documentId);

        Object result = aiServiceClient.deleteDocument(documentId);
        return ResponseEntity.ok(result);
    }

    /**
     * Kiểm tra phân quyền quản lý tài liệu (Executive Leadership, HR, IT Admin, hoặc Trưởng phòng).
     */
    private void checkAdminOrHrOrDeptHeadPermission(TokenPayload currentUser) {
        if (currentUser == null) {
            throw new AccessDeniedException("Yêu cầu đăng nhập trước khi thực hiện thao tác!");
        }
        String userDept = currentUser.getDepartment();
        String userJob = currentUser.getJob() != null ? currentUser.getJob() : "";

        boolean isExecutive = "Executive Leadership".equalsIgnoreCase(userDept)
                || userJob.contains("CEO") || userJob.contains("Director") || userJob.contains("Chairman");
        boolean isSysAdmin = "Information Technology".equalsIgnoreCase(userDept)
                && (userJob.contains("System Administrator") || userJob.contains("Admin"));
        boolean isHR = "Human Resources".equalsIgnoreCase(userDept);
        boolean isDeptHead = userJob.startsWith("Department Head")
                || userJob.contains("Head") || userJob.contains("Manager") || userJob.contains("Trưởng");

        if (!isExecutive && !isSysAdmin && !isHR && !isDeptHead) {
            throw new AccessDeniedException("Chỉ có Trưởng phòng, Phòng Nhân sự (HR), Ban Giám Đốc hoặc Quản trị viên hệ thống mới có quyền quản lý tài liệu!");
        }
    }

    /**
     * Xác thực quyền hạn và kiểm tra tính hợp lệ của danh sách phòng ban được phép xem tài liệu.
     * Quy tắc:
     * - Ban Giám Đốc (Executive Leadership) / Admin: Toàn quyền, upload cho ALL hoặc bất kỳ phòng ban nào.
     * - Phòng Nhân Sự (Human Resources): Upload cho ALL hoặc phòng ban Human Resources.
     * - Trưởng phòng chức năng (Department Head): CHỈ được upload cho chính phòng ban của mình.
     * - Nhân viên thường: Không có quyền upload/chỉnh sửa tài liệu.
     */
    private String validateAndAuthorizeDepartmentScope(TokenPayload currentUser, String requestedDepartments) {
        if (currentUser == null) {
            throw new AccessDeniedException("Yêu cầu đăng nhập trước khi thực hiện thao tác!");
        }

        String userDept = currentUser.getDepartment();
        String userJob = currentUser.getJob() != null ? currentUser.getJob() : "";

        boolean isExecutive = "Executive Leadership".equalsIgnoreCase(userDept)
                || userJob.contains("CEO") || userJob.contains("Director") || userJob.contains("Chairman");
        boolean isSysAdmin = "Information Technology".equalsIgnoreCase(userDept)
                && (userJob.contains("System Administrator") || userJob.contains("Admin"));
        boolean isHR = "Human Resources".equalsIgnoreCase(userDept);
        boolean isDeptHead = userJob.startsWith("Department Head")
                || userJob.contains("Head") || userJob.contains("Manager") || userJob.contains("Trưởng");

        if (!isExecutive && !isSysAdmin && !isHR && !isDeptHead) {
            throw new AccessDeniedException("Bạn không có quyền đăng tải hoặc quản lý tài liệu quy chế!");
        }

        // Trường hợp Trưởng phòng chức năng (không phải HR, không phải Executive/Admin)
        if (isDeptHead && !isExecutive && !isSysAdmin && !isHR) {
            String officialDept = DepartmentName.fromString(userDept);
            if (officialDept == null) {
                throw new AccessDeniedException("Phòng ban của bạn (" + userDept + ") không hợp lệ trong hệ thống!");
            }

            if (requestedDepartments != null && !requestedDepartments.isBlank()) {
                String[] parts = requestedDepartments.split(",");
                for (String part : parts) {
                    String trimmed = part.trim();
                    if (trimmed.equalsIgnoreCase("ALL") || !trimmed.equalsIgnoreCase(userDept)) {
                        throw new AccessDeniedException("Trưởng phòng chỉ có quyền đăng tài liệu nội bộ cho chính phòng ban của mình (" + officialDept + "), không được chọn 'ALL' hoặc phòng ban khác!");
                    }
                }
            }
            return officialDept;
        }

        // Trường hợp Nhân sự (HR): Được phép upload cho ALL hoặc phòng ban Human Resources
        if (isHR && !isExecutive && !isSysAdmin) {
            if (requestedDepartments == null || requestedDepartments.isBlank()) {
                return DepartmentName.ALL.getValue();
            }
            String[] parts = requestedDepartments.split(",");
            List<String> validList = new ArrayList<>();
            for (String part : parts) {
                String trimmed = part.trim();
                if (!DepartmentName.isValid(trimmed)) {
                    throw new IllegalArgumentException("Tên phòng ban không hợp lệ: " + trimmed);
                }
                String normalized = DepartmentName.fromString(trimmed);
                if (!normalized.equalsIgnoreCase(DepartmentName.ALL.getValue())
                        && !normalized.equalsIgnoreCase(DepartmentName.HUMAN_RESOURCES.getValue())) {
                    throw new AccessDeniedException("Phòng Nhân sự chỉ có quyền đăng tài liệu toàn công ty ('ALL') hoặc tài liệu nội bộ Phòng Nhân sự!");
                }
                validList.add(normalized);
            }
            return String.join(",", validList);
        }

        // Trường hợp Ban Giám Đốc (Executive Leadership) hoặc IT Admin: Toàn quyền
        if (requestedDepartments == null || requestedDepartments.isBlank()) {
            return DepartmentName.ALL.getValue();
        }

        String[] parts = requestedDepartments.split(",");
        List<String> validList = new ArrayList<>();
        for (String part : parts) {
            String trimmed = part.trim();
            if (!DepartmentName.isValid(trimmed)) {
                throw new IllegalArgumentException("Tên phòng ban không hợp lệ: " + trimmed);
            }
            validList.add(DepartmentName.fromString(trimmed));
        }
        return String.join(",", validList);
    }
}
