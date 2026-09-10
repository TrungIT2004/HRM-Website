package com.minhtrung.hrm.employees.dtos.requests;

import java.util.UUID;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
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
public class CreateJobRequest {

    @NotBlank(message = "Tiêu đề chức danh không được để trống")
    private String title;

    @NotNull(message = "Phòng ban không được để trống")
    private UUID departmentId;
}
