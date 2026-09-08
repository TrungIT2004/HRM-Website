package com.minhtrung.social_app.leave.dtos.requests;

import java.time.LocalDate;
import java.util.UUID;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
public class CreateLeaveReqRequest {
    private UUID requestorId;

    @NotNull(message = "Ngày bắt đầu nghỉ (fromDate) không được để trống")
    private LocalDate fromDate;

    @NotNull(message = "Ngày kết thúc nghỉ (toDate) không được để trống")
    private LocalDate toDate;

    @NotBlank(message = "Lý do xin nghỉ phép không được để trống")
    @Size(max = 500, message = "Lý do xin nghỉ không được vượt quá 500 ký tự")
    private String reason;

    @Min(value = 0, message = "Số ngày nghỉ có lương (paidLeaveDays) không được là số âm")
    private int paidLeaveDays;
}
