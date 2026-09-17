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

    private String question;
    private String answer;
    private List<CitationResponse> citations;

    @JsonProperty("retrieved_chunks_count")
    private Integer retrievedChunksCount;

    private String confidence;
}
