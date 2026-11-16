package com.minhtrung.hrm.performance.dtos.requests;

import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ManagerScoreRequest {
    @NotEmpty(message = "Phải chấm đủ 10 tiêu chí")
    @Valid
    private List<ScoreItemRequest> scores;
    private String overallSummary;
    private String nextGoals;
}
