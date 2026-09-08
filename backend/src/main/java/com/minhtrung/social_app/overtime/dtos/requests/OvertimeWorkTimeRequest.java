package com.minhtrung.social_app.overtime.dtos.requests;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
public class OvertimeWorkTimeRequest {
    @NotNull(message = "Thời gian bắt đầu tăng ca (approvedStartTime) không được để trống")
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm")
    private LocalDateTime approvedStartTime;

    @NotNull(message = "Thời gian kết thúc tăng ca (approvedEndTime) không được để trống")
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm")
    private LocalDateTime approvedEndTime;

    private String reason;
}