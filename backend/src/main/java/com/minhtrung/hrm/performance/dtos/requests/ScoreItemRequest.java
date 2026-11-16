package com.minhtrung.hrm.performance.dtos.requests;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ScoreItemRequest {
    @NotBlank(message = "Thiếu mã tiêu chí")
    private String criterionCode;

    @Min(value = 1, message = "Điểm từ 1-5")
    @Max(value = 5, message = "Điểm từ 1-5")
    private Integer score;

    private String note;
}
