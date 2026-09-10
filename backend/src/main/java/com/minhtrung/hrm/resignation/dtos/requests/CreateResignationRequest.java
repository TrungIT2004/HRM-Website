package com.minhtrung.hrm.resignation.dtos.requests;

import java.time.LocalDate;

import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Getter;

@AllArgsConstructor
@Getter
public class CreateResignationRequest {
    @NotNull(message = "Ngày làm việc cuối cùng không được để trống")
    @Future(message = "Ngày làm việc cuối cùng phải là một ngày trong tương lai")
    private LocalDate lastWorkingDate;

    @NotBlank(message = "Lý do xin thôi việc không được để trống")
    @Size(max = 500, message = "Lý do thôi việc không được vượt quá 500 ký tự")
    private String reason;

}
