package com.minhtrung.hrm.ai;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.UUID;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;
import org.springframework.web.client.RestTemplate;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.minhtrung.hrm.ai.configs.AiClientConfig;
import com.minhtrung.hrm.ai.dtos.responses.ChatQueryResponse;
import com.minhtrung.hrm.ai.services.AiServiceClient;
import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;

@Disabled("Integration test - yêu cầu server FastAPI AI và LLM thật đang chạy")
public class AiServiceClientTest {

    @Test
    void testCallingFastApiFromJava() {
        AiClientConfig config = new AiClientConfig();
        RestTemplate restTemplate = config.aiRestTemplate();
        ObjectMapper objectMapper = new ObjectMapper();
        AiServiceClient client = new AiServiceClient(restTemplate, config, objectMapper);

        TokenPayload mockUser = new TokenPayload();
        mockUser.setUserId(UUID.randomUUID());
        mockUser.setFullName("Nguyễn Văn A");
        mockUser.setJob("ROLE_EMPLOYEE");
        mockUser.setDepartment("ALL");

        System.out.println("\n🚀 [Lượt 1] Đang gửi câu hỏi từ Java sang FastAPI (Port 8000)...");
        ChatQueryResponse response1 = client.queryChatbot("Tôi kết hôn được nghỉ mấy ngày?", null, 2, mockUser);

        assertNotNull(response1, "Response 1 không được null");
        assertNotNull(response1.getConversationId(), "ConversationId không được null");
        assertNotNull(response1.getAnswer(), "Câu trả lời không được null");

        System.out.println("\n🤖 [Lượt 1 - AI Trả Lời]: " + response1.getAnswer());
        System.out.println("🆔 Conversation ID: " + response1.getConversationId());

        System.out.println("\n🚀 [Lượt 2] Gửi câu hỏi nối tiếp (Test Memory)...");
        ChatQueryResponse response2 = client.queryChatbot(
                "Vậy tiền mừng của công ty cho trường hợp này là bao nhiêu?",
                response1.getConversationId(),
                2,
                mockUser
        );

        assertNotNull(response2, "Response 2 không được null");
        System.out.println("🔄 Rewritten Query: " + response2.getRewrittenQuery());
        System.out.println("🤖 [Lượt 2 - AI Trả Lời]: " + response2.getAnswer());

        assertTrue(response2.getAnswer().contains("2.000.000") || response2.getAnswer().contains("tiền mừng"));
        
        // Clean up
        client.deleteConversation(response1.getConversationId(), mockUser.getUserId().toString());
        System.out.println("\n🎉 TEST MULTI-TURN MEMORY JAVA -> FASTAPI THÀNH CÔNG 100%!");
    }
}
