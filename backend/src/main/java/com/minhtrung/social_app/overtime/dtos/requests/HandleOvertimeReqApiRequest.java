package com.minhtrung.social_app.overtime.dtos.requests;

import com.minhtrung.social_app.overtime.enums.OvertimeRecordStatus;
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