package com.minhtrung.hrm.ai.dtos.responses;

import java.util.List;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChatQueryResponse {

    @JsonProperty("conversation_id")
    private String conversationId;

    private String title;

    private String question;

    @JsonProperty("rewritten_query")
    private String rewrittenQuery;

    private String answer;
    private List<CitationResponse> citations;

    @JsonProperty("retrieved_chunks_count")
    private Integer retrievedChunksCount;

    private String confidence;
}
