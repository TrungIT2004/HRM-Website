package com.minhtrung.hrm.ai.dtos.requests;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChatQueryRequest {

    @NotBlank(message = "Câu hỏi không được để trống")
    private String question;

    private String conversationId;

    @Builder.Default
    private Integer topK = 3;
}
