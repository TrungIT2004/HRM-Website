package com.minhtrung.hrm.overtime.dtos.requests;

import com.minhtrung.hrm.overtime.enums.OvertimeRecordStatus;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class HandleOvertimeReqApiRequest {
    @NotNull(message = "Status cannot be null")
    private OvertimeRecordStatus status;

    private String rejectionReason;
}