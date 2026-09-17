package com.minhtrung.hrm.ai;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;
import org.springframework.web.client.RestTemplate;

import com.minhtrung.hrm.ai.configs.AiClientConfig;
import com.minhtrung.hrm.ai.dtos.responses.ChatQueryResponse;
import com.minhtrung.hrm.ai.services.AiServiceClient;
import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;

public class AiServiceClientTest {

    @Test
    void testCallingFastApiFromJava() {
        AiClientConfig config = new AiClientConfig();
        RestTemplate restTemplate = config.aiRestTemplate();
        AiServiceClient client = new AiServiceClient(restTemplate, config);

        TokenPayload mockUser = new TokenPayload();
        mockUser.setFullName("Nguyễn Văn A");
        mockUser.setJob("ROLE_EMPLOYEE");
        mockUser.setDepartment("ALL");

        System.out.println("\n🚀 Đang gửi câu hỏi từ Java sang FastAPI (Port 8000)...");
        ChatQueryResponse response = client.queryChatbot("Tôi kết hôn được nghỉ mấy ngày?", 2, mockUser);

        assertNotNull(response, "Response không được null");
        assertNotNull(response.getAnswer(), "Câu trả lời không được null");

        System.out.println("\n🤖 [AI Trả Lời Qua Java Service Client]:");
        System.out.println(response.getAnswer());
        System.out.println("\n📚 Độ tin cậy: " + response.getConfidence());

        assertTrue(response.getAnswer().contains("3 ngày") || response.getAnswer().contains("03 ngày"));
        System.out.println("\n🎉 TEST KẾT NỐI JAVA (SPRING BOOT) -> FASTAPI THÀNH CÔNG 100%!");
    }
}
