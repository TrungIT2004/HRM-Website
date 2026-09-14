package com.minhtrung.hrm.admin.dtos.requests;

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
public class AdminUpdateStatusRequest {

    @NotNull(message = "Trạng thái hoạt động không được để trống")
    private Boolean isActive;

    private String reason;
}
