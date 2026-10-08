package com.minhtrung.hrm.ai.services;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.method.annotation.ResponseBodyEmitter;
import org.springframework.web.util.UriComponentsBuilder;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.minhtrung.hrm.ai.configs.AiClientConfig;
import com.minhtrung.hrm.ai.dtos.responses.ChatQueryResponse;
import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class AiServiceClient {

    private final RestTemplate aiRestTemplate;
    private final AiClientConfig aiConfig;
    private final ObjectMapper objectMapper;

    private final HttpClient httpClient = HttpClient.newBuilder()
            .version(HttpClient.Version.HTTP_1_1)
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    private HttpHeaders createSecureHeaders() {
        HttpHeaders headers = new HttpHeaders();
        headers.set("X-Internal-Secret", aiConfig.getInternalSecret());
        return headers;
    }

    /**
     * Gửi câu hỏi của nhân viên sang FastAPI để truy vấn Hybrid Search + Multi-turn Memory + LLM Reasoning.
     */
    public ChatQueryResponse queryChatbot(String question, String conversationId, Integer topK, TokenPayload currentUser) {
        String url = aiConfig.getBaseUrl() + "/api/v1/chat/query";

        HttpHeaders headers = createSecureHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("question", question);
        if (conversationId != null && !conversationId.isBlank()) {
            requestBody.put("conversation_id", conversationId);
        }
        String userIdStr = (currentUser != null && currentUser.getUserId() != null)
                ? currentUser.getUserId().toString()
                : "ANONYMOUS";
        requestBody.put("user_id", userIdStr);
        requestBody.put("top_k", topK != null ? topK : 3);

        // Trích xuất chức danh và phòng ban thực tế của nhân viên (PBAC)
        String currentJob = (currentUser != null && currentUser.getJob() != null && !currentUser.getJob().isBlank())
                ? currentUser.getJob().trim()
                : "ALL";
        String currentDept = (currentUser != null && currentUser.getDepartment() != null && !currentUser.getDepartment().isBlank())
                ? currentUser.getDepartment().trim()
                : "ALL";

        List<String> userJobs = List.of(currentJob, "ALL");
        requestBody.put("user_jobs", userJobs);
        requestBody.put("user_roles", userJobs);
        requestBody.put("department", currentDept);

        log.info("[AiServiceClient] Gửi câu hỏi sang AI Service: '{}' (Conv: {}, User: {}, Job: {}, Dept: {})",
                question, conversationId, (currentUser != null ? currentUser.getUserId() : "null"), currentJob, currentDept);

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);
        return aiRestTemplate.postForObject(url, entity, ChatQueryResponse.class);
    }

    /**
     * Gửi câu hỏi của nhân viên sang FastAPI ở chế độ Streaming (Server-Sent Events - SSE).
     * 
     * Quy trình xử lý luồng (SSE Flow):
     * 1. Chuẩn bị payload JSON chứa câu hỏi, mã phiên hội thoại (nếu có), quyền hạn và phòng ban của nhân viên.
     * 2. Sử dụng java.net.http.HttpClient không đồng bộ (sendAsync) gửi POST request tới FastAPI (/api/v1/chat/stream).
     * 3. Sử dụng HttpResponse.BodyHandlers.ofLines() để đọc dữ liệu trả về theo từng dòng (reactive stream) ngay khi gói tin vừa tới từ socket.
     * 4. Đẩy trực tiếp từng dòng dữ liệu vào ResponseBodyEmitter của Spring MVC để chuyển tiếp tới trình duyệt web mà không cần chờ toàn bộ câu trả lời hoàn tất.
     * 5. Quản lý ngoại lệ và ngắt kết nối an toàn: Nếu người dùng đóng trình duyệt hoặc ngắt kết nối giữa chừng, hệ thống bắt IOException để tránh spam stack trace.
     *
     * @param question       Câu hỏi mới của nhân viên
     * @param conversationId Mã ID cuộc hội thoại (UUID dạng chuỗi, null nếu là câu hỏi đầu tiên)
     * @param topK           Số lượng đoạn văn bản trích dẫn tối đa cần tìm kiếm
     * @param currentUser    Thông tin nhân viên đang đăng nhập (trích xuất từ JWT Token)
     * @param emitter        Đối tượng ResponseBodyEmitter truyền luồng dữ liệu tới client
     */
    public void streamChatbot(
            String question,
            String conversationId,
            Integer topK,
            TokenPayload currentUser,
            ResponseBodyEmitter emitter
    ) {
        String url = aiConfig.getBaseUrl() + "/api/v1/chat/stream";

        // Bước 1: Thu thập metadata của người dùng và đóng gói request body
        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("question", question);
        if (conversationId != null && !conversationId.isBlank()) {
            requestBody.put("conversation_id", conversationId);
        }
        String userIdStr = (currentUser != null && currentUser.getUserId() != null)
                ? currentUser.getUserId().toString()
                : "ANONYMOUS";
        requestBody.put("user_id", userIdStr);
        requestBody.put("top_k", topK != null ? topK : 3);

        // PBAC: Trích xuất chức danh và phòng ban thực tế từ Token
        String currentStreamJob = (currentUser != null && currentUser.getJob() != null && !currentUser.getJob().isBlank())
                ? currentUser.getJob().trim()
                : "ALL";
        String currentStreamDept = (currentUser != null && currentUser.getDepartment() != null && !currentUser.getDepartment().isBlank())
                ? currentUser.getDepartment().trim()
                : "ALL";

        List<String> streamUserJobs = List.of(currentStreamJob, "ALL");
        requestBody.put("user_jobs", streamUserJobs);
        requestBody.put("user_roles", streamUserJobs);
        requestBody.put("department", currentStreamDept);

        try {
            // Bước 2: Chuyển đổi payload thành chuỗi JSON và tạo HttpRequest
            String jsonBody = objectMapper.writeValueAsString(requestBody);

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .version(HttpClient.Version.HTTP_1_1)
                    .timeout(Duration.ofMinutes(3)) // Hạn mức thời gian cho luồng sinh câu hỏi dài
                    .header("Content-Type", "application/json")
                    .header("X-Internal-Secret", aiConfig.getInternalSecret()) // Khóa bảo mật nội bộ
                    .POST(HttpRequest.BodyPublishers.ofString(jsonBody, StandardCharsets.UTF_8))
                    .build();

            log.info("[AiServiceClient] Bắt đầu stream SSE sang AI Service: '{}' (User: {})", question, userIdStr);

            // Bước 3: Gửi request bất đồng bộ (Non-blocking I/O)
            httpClient.sendAsync(request, HttpResponse.BodyHandlers.ofLines())
                    .thenAccept(response -> {
                        // Kiểm tra mã trạng thái HTTP từ FastAPI
                        if (response.statusCode() != 200) {
                            log.error("[AiServiceClient] AI Service trả về mã lỗi: {}", response.statusCode());
                            try {
                                emitter.send("data: {\"type\": \"error\", \"message\": \"AI Service gặp sự cố (HTTP " + response.statusCode() + ")\"}\n\n");
                                emitter.complete();
                            } catch (Exception e) {
                                emitter.completeWithError(e);
                            }
                            return;
                        }

                        // Bước 4: Đọc từng dòng SSE từ FastAPI và chuyển tiếp ngay sang Spring Boot emitter
                        try {
                            response.body().forEach(line -> {
                                try {
                                    // Gửi từng dòng kèm ký tự xuống dòng để đảm bảo đúng quy cách Server-Sent Events (SSE)
                                    emitter.send(line + "\n");
                                } catch (IOException e) {
                                    // Xảy ra khi client đóng tab hoặc hủy kết nối mạng (Broken pipe / Connection abort)
                                    log.debug("[AiServiceClient] Client đã ngắt kết nối khi đang nhận stream: {}", e.getMessage());
                                }
                            });
                            // Hoàn tất luồng truyền dữ liệu khi phía AI kết thúc
                            emitter.complete();
                        } catch (Exception e) {
                            log.warn("[AiServiceClient] Lỗi trong quá trình đọc luồng SSE: {}", e.getMessage());
                            emitter.completeWithError(e);
                        }
                    })
                    .exceptionally(ex -> {
                        // Bước 5: Bắt lỗi kết nối mạng (ví dụ FastAPI chưa khởi động hoặc timeout)
                        log.error("[AiServiceClient] Lỗi kết nối tới AI Service: {}", ex.getMessage());
                        try {
                            emitter.send("data: {\"type\": \"error\", \"message\": \"Không thể kết nối đến AI Service: " + ex.getMessage() + "\"}\n\n");
                            emitter.complete();
                        } catch (Exception ignored) {
                            emitter.completeWithError(ex);
                        }
                        return null;
                    });

        } catch (Exception e) {
            log.error("[AiServiceClient] Lỗi chuẩn bị request streaming: {}", e.getMessage());
            emitter.completeWithError(e);
        }
    }

    /**
     * Tải tài liệu lên FastAPI để xử lý nạp ngầm (Background Task).
     */
    public Object uploadDocument(
            MultipartFile file,
            String allowedDepartments,
            TokenPayload currentUser
    ) throws IOException {
        String url = aiConfig.getBaseUrl() + "/api/v1/documents/upload";

        HttpHeaders headers = createSecureHeaders();
        headers.setContentType(MediaType.MULTIPART_FORM_DATA);

        MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();

        ByteArrayResource fileResource = new ByteArrayResource(file.getBytes()) {
            @Override
            public String getFilename() {
                return file.getOriginalFilename();
            }
        };

        body.add("file", fileResource);
        body.add("allowed_departments", allowedDepartments != null ? allowedDepartments : "ALL");
        body.add("uploaded_by", currentUser != null ? currentUser.getFullName() : "ADMIN");

        log.info("[AiServiceClient] Forward file upload: {} (Size: {} bytes, Depts: {})",
                file.getOriginalFilename(), file.getSize(), allowedDepartments);

        HttpEntity<MultiValueMap<String, Object>> entity = new HttpEntity<>(body, headers);
        return aiRestTemplate.postForObject(url, entity, Object.class);
    }

    /**
     * Cập nhật / Thay thế file cũ bằng file mới (In-Place Update).
     */
    public Object updateDocument(
            String documentId,
            MultipartFile file,
            String allowedDepartments,
            TokenPayload currentUser
    ) throws IOException {
        String url = aiConfig.getBaseUrl() + "/api/v1/documents/" + documentId;

        HttpHeaders headers = createSecureHeaders();
        headers.setContentType(MediaType.MULTIPART_FORM_DATA);

        MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();

        ByteArrayResource fileResource = new ByteArrayResource(file.getBytes()) {
            @Override
            public String getFilename() {
                return file.getOriginalFilename();
            }
        };

        body.add("file", fileResource);
        if (allowedDepartments != null && !allowedDepartments.isBlank()) {
            body.add("allowed_departments", allowedDepartments);
        }
        body.add("updated_by", currentUser != null ? currentUser.getFullName() : "ADMIN");

        log.info("[AiServiceClient] Forward file update for document ID: {}, Depts: {}", documentId, allowedDepartments);

        HttpEntity<MultiValueMap<String, Object>> entity = new HttpEntity<>(body, headers);
        ResponseEntity<Object> response = aiRestTemplate.exchange(url, HttpMethod.PUT, entity, Object.class);
        return response.getBody();
    }

    /**
     * Lấy danh sách tài liệu hiện có kèm trạng thái xử lý và bộ lọc phòng ban.
     */
    public Object listDocuments(String status, String search, String department, String userDept, String ownerName) {
        String baseUrl = aiConfig.getBaseUrl() + "/api/v1/documents";
        UriComponentsBuilder builder = UriComponentsBuilder.fromUriString(baseUrl);
        if (status != null && !status.isBlank()) {
            builder.queryParam("status", status);
        }
        if (search != null && !search.isBlank()) {
            builder.queryParam("search", search);
        }
        if (department != null && !department.isBlank()) {
            builder.queryParam("department", department);
        }
        if (userDept != null && !userDept.isBlank()) {
            builder.queryParam("user_dept", userDept);
        }
        if (ownerName != null && !ownerName.isBlank()) {
            builder.queryParam("owner_name", ownerName);
        }

        HttpHeaders headers = createSecureHeaders();
        HttpEntity<?> entity = new HttpEntity<>(headers);

        java.net.URI targetUri = builder.build().encode().toUri();
        log.info("[AiServiceClient] Fetch documents from URL: {}", targetUri);

        ResponseEntity<Object> response = aiRestTemplate.exchange(
                targetUri,
                HttpMethod.GET,
                entity,
                Object.class
        );
        return response.getBody();
    }

    /**
     * Tải xuống file tài liệu gốc từ FastAPI (bảo mật với Secret & PBAC).
     */
    public ResponseEntity<byte[]> downloadDocument(String documentId, String userDept) {
        String baseUrl = aiConfig.getBaseUrl() + "/api/v1/documents/" + documentId + "/download";
        UriComponentsBuilder builder = UriComponentsBuilder.fromUriString(baseUrl);
        if (userDept != null && !userDept.isBlank()) {
            builder.queryParam("user_dept", userDept);
        }

        HttpHeaders headers = createSecureHeaders();
        HttpEntity<?> entity = new HttpEntity<>(headers);

        java.net.URI targetUri = builder.build().encode().toUri();
        return aiRestTemplate.exchange(
                targetUri,
                HttpMethod.GET,
                entity,
                byte[].class
        );
    }

    /**
     * Lấy chi tiết 1 tài liệu (để kiểm tra uploaded_by trước khi cho sửa/xóa).
     */
    public Object getDocumentDetail(String documentId) {
        String url = aiConfig.getBaseUrl() + "/api/v1/documents/" + documentId;
        HttpHeaders headers = createSecureHeaders();
        HttpEntity<?> entity = new HttpEntity<>(headers);

        ResponseEntity<Object> response = aiRestTemplate.exchange(url, HttpMethod.GET, entity, Object.class);
        return response.getBody();
    }

    /**
     * Xem chi tiết các chunk đã bóc tách của 1 tài liệu để kiểm duyệt.
     */
    public Object getDocumentChunks(String documentId) {
        String url = aiConfig.getBaseUrl() + "/api/v1/documents/" + documentId + "/chunks";
        HttpHeaders headers = createSecureHeaders();
        HttpEntity<?> entity = new HttpEntity<>(headers);

        ResponseEntity<Object> response = aiRestTemplate.exchange(url, HttpMethod.GET, entity, Object.class);
        return response.getBody();
    }

    /**
     * Xóa vĩnh viễn tài liệu và toàn bộ các vector liên quan.
     */
     public Object deleteDocument(String documentId) {
         String url = aiConfig.getBaseUrl() + "/api/v1/documents/" + documentId;
         HttpHeaders headers = createSecureHeaders();
         HttpEntity<?> entity = new HttpEntity<>(headers);

         ResponseEntity<Object> response = aiRestTemplate.exchange(url, HttpMethod.DELETE, entity, Object.class);
         return response.getBody();
     }

    /**
     * Lấy danh sách các cuộc hội thoại của nhân viên.
     */
    public Object listConversations(String userId) {
        String url = aiConfig.getBaseUrl() + "/api/v1/chat/conversations?user_id=" + userId;
        HttpHeaders headers = createSecureHeaders();
        HttpEntity<?> entity = new HttpEntity<>(headers);

        ResponseEntity<Object> response = aiRestTemplate.exchange(url, HttpMethod.GET, entity, Object.class);
        return response.getBody();
    }

    /**
     * Lấy toàn bộ lịch sử tin nhắn trong 1 cuộc trò chuyện.
     */
    public Object getConversationMessages(String conversationId, String userId) {
        String url = aiConfig.getBaseUrl() + "/api/v1/chat/conversations/" + conversationId;
        if (userId != null && !userId.isBlank()) {
            url += "?user_id=" + userId;
        }
        HttpHeaders headers = createSecureHeaders();
        HttpEntity<?> entity = new HttpEntity<>(headers);

        ResponseEntity<Object> response = aiRestTemplate.exchange(url, HttpMethod.GET, entity, Object.class);
        return response.getBody();
    }

    /**
     * Xóa 1 cuộc trò chuyện (và toàn bộ tin nhắn bên trong).
     */
    public Object deleteConversation(String conversationId, String userId) {
        String url = aiConfig.getBaseUrl() + "/api/v1/chat/conversations/" + conversationId;
        if (userId != null && !userId.isBlank()) {
            url += "?user_id=" + userId;
        }
        HttpHeaders headers = createSecureHeaders();
        HttpEntity<?> entity = new HttpEntity<>(headers);

        ResponseEntity<Object> response = aiRestTemplate.exchange(url, HttpMethod.DELETE, entity, Object.class);
        return response.getBody();
    }

    /**
     * Đổi tên tiêu đề cuộc hội thoại thủ công.
     */
    public Object updateConversationTitle(String conversationId, String newTitle, String userId) {
        String url = aiConfig.getBaseUrl() + "/api/v1/chat/conversations/" + conversationId;
        HttpHeaders headers = createSecureHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        Map<String, String> body = new HashMap<>();
        body.put("title", newTitle);
        if (userId != null && !userId.isBlank()) {
            body.put("user_id", userId);
        }

        HttpEntity<Map<String, String>> entity = new HttpEntity<>(body, headers);
        ResponseEntity<Object> response = aiRestTemplate.exchange(url, HttpMethod.PUT, entity, Object.class);
        return response.getBody();
    }

    /**
     * Yêu cầu AI tự động sinh lại tiêu đề thông minh từ câu hỏi đầu tiên.
     */
    public Object regenerateConversationTitle(String conversationId, String userId) {
        String url = aiConfig.getBaseUrl() + "/api/v1/chat/conversations/" + conversationId + "/generate-title";
        if (userId != null && !userId.isBlank()) {
            url += "?user_id=" + userId;
        }
        HttpHeaders headers = createSecureHeaders();
        HttpEntity<?> entity = new HttpEntity<>(headers);

        ResponseEntity<Object> response = aiRestTemplate.exchange(url, HttpMethod.POST, entity, Object.class);
        return response.getBody();
    }

    /**
     * Ghim hoặc bỏ ghim một cuộc hội thoại.
     */
    public Object pinConversation(String conversationId, String userId, Boolean isPinned) {
        String url = aiConfig.getBaseUrl() + "/api/v1/chat/conversations/" + conversationId + "/pin";
        HttpHeaders headers = createSecureHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        Map<String, Object> body = new HashMap<>();
        if (userId != null && !userId.isBlank()) {
            body.put("user_id", userId);
        }
        if (isPinned != null) {
            body.put("is_pinned", isPinned);
        }

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);
        ResponseEntity<Object> response = aiRestTemplate.exchange(url, HttpMethod.PUT, entity, Object.class);
        return response.getBody();
    }
}
