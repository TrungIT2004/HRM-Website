package com.minhtrung.hrm.admin.dtos.requests;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProvisionAccountRequest {

    @NotBlank(message = "Email công ty không được để trống")
    @Email(message = "Email không đúng định dạng")
    private String corporateEmail;

    @NotBlank(message = "Mật khẩu khởi tạo không được để trống")
    @Size(min = 8, message = "Mật khẩu phải có tối thiểu 8 ký tự")
    private String temporaryPassword;

    private String employeeCode;
}
