package com.minhtrung.hrm.leave.dtos.requests;

import com.minhtrung.hrm.leave.enums.LeaveRequestStatus;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
public class HandleLeaveReqApiRequest {
    @NotNull(message = "Trạng thái phê duyệt (status) không được để trống")
    private LeaveRequestStatus status;

    private String rejectionReason;
}
