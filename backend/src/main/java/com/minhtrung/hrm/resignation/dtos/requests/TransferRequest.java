package com.minhtrung.hrm.resignation.dtos.requests;

import java.util.UUID;

import com.minhtrung.hrm.resignation.enums.ResignationStatus;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Getter;

@AllArgsConstructor
@Getter
public class TransferRequest {
    @NotNull(message = "ID của đơn xin nghỉ việc không được để trống")
    private UUID resignationId;

    @NotNull(message = "Trạng thái không được để trống")
    private ResignationStatus status;

    @Size(max = 500, message = "Lý do thôi việc không được vượt quá 500 ký tự")
    private String managerComment;
}
