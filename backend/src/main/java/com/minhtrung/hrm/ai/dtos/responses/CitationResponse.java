package com.minhtrung.hrm.ai.dtos.responses;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CitationResponse {

    @JsonProperty("document_name")
    private String documentName;

    @JsonProperty("breadcrumb")
    private String breadcrumb;

    @JsonProperty("page_number")
    private Integer pageNumber;

    @JsonProperty("file_url")
    private String fileUrl;

    @JsonProperty("chunk_type")
    private String chunkType;

    @JsonProperty("relevance_score")
    private Double relevanceScore;
}
