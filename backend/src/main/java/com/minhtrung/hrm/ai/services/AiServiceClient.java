package com.minhtrung.hrm.ai.services;

import java.io.IOException;
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
import org.springframework.web.util.UriComponentsBuilder;

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

    private HttpHeaders createSecureHeaders() {
        HttpHeaders headers = new HttpHeaders();
        headers.set("X-Internal-Secret", aiConfig.getInternalSecret());
        return headers;
    }

    /**
     * Gửi câu hỏi của nhân viên sang FastAPI để truy vấn Hybrid Search + LLM Reasoning.
     */
    public ChatQueryResponse queryChatbot(String question, Integer topK, TokenPayload currentUser) {
        String url = aiConfig.getBaseUrl() + "/api/v1/chat/query";

        HttpHeaders headers = createSecureHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("question", question);
        requestBody.put("top_k", topK != null ? topK : 3);

        // Trích xuất vai trò và phòng ban của user đang đăng nhập
        String role = currentUser.getJob() != null ? currentUser.getJob() : "ROLE_EMPLOYEE";
        String dept = currentUser.getDepartment() != null ? currentUser.getDepartment() : "ALL";

        requestBody.put("user_roles", List.of(role, "ROLE_EMPLOYEE"));
        requestBody.put("department", dept);

        log.info("[AiServiceClient] Gửi câu hỏi sang AI Service: '{}' (User: {}, Role: {}, Dept: {})",
                question, currentUser.getUserId(), role, dept);

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);
        return aiRestTemplate.postForObject(url, entity, ChatQueryResponse.class);
    }

    /**
     * Tải tài liệu lên FastAPI để xử lý nạp ngầm (Background Task).
     */
    public Object uploadDocument(
            MultipartFile file,
            String allowedRoles,
            String allowedDepartments,
            TokenPayload currentUser,
            boolean overwrite
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
        body.add("allowed_roles", allowedRoles != null ? allowedRoles : "ROLE_EMPLOYEE,ROLE_MANAGER");
        body.add("allowed_departments", allowedDepartments != null ? allowedDepartments : "ALL");
        body.add("uploaded_by", currentUser != null ? currentUser.getFullName() : "ADMIN");
        body.add("overwrite", String.valueOf(overwrite));

        log.info("[AiServiceClient] Forward file upload: {} (Size: {} bytes)", file.getOriginalFilename(), file.getSize());

        HttpEntity<MultiValueMap<String, Object>> entity = new HttpEntity<>(body, headers);
        return aiRestTemplate.postForObject(url, entity, Object.class);
    }

    /**
     * Cập nhật / Thay thế file cũ bằng file mới (In-Place Update).
     */
    public Object updateDocument(
            String documentId,
            MultipartFile file,
            String allowedRoles,
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
        if (allowedRoles != null) {
            body.add("allowed_roles", allowedRoles);
        }
        if (allowedDepartments != null) {
            body.add("allowed_departments", allowedDepartments);
        }
        body.add("updated_by", currentUser != null ? currentUser.getFullName() : "ADMIN");

        log.info("[AiServiceClient] Forward file update for document ID: {}", documentId);

        HttpEntity<MultiValueMap<String, Object>> entity = new HttpEntity<>(body, headers);
        ResponseEntity<Object> response = aiRestTemplate.exchange(url, HttpMethod.PUT, entity, Object.class);
        return response.getBody();
    }

    /**
     * Lấy danh sách tài liệu hiện có kèm trạng thái xử lý.
     */
    public Object listDocuments(String status, String search) {
        String baseUrl = aiConfig.getBaseUrl() + "/api/v1/documents";
        UriComponentsBuilder builder = UriComponentsBuilder.fromUriString(baseUrl);
        if (status != null && !status.isBlank()) {
            builder.queryParam("status", status);
        }
        if (search != null && !search.isBlank()) {
            builder.queryParam("search", search);
        }

        HttpHeaders headers = createSecureHeaders();
        HttpEntity<?> entity = new HttpEntity<>(headers);

        ResponseEntity<Object> response = aiRestTemplate.exchange(
                builder.toUriString(),
                HttpMethod.GET,
                entity,
                Object.class
        );
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
}
