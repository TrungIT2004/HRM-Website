package com.minhtrung.social_app.attendance.dtos.requests;

import java.time.LocalTime;

import com.minhtrung.social_app.attendance.enums.AttendanceStatus;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

@AllArgsConstructor
@NoArgsConstructor
@Getter
public class EditAttendanceRequest {
    private LocalTime editedClockInTime;
    private LocalTime editedClockOutTime;

    @Size(max = 500, message = "Lý do chỉnh sửa không được vượt quá 500 ký tự")
    private String editedReason;

    @NotNull(message = "Trạng thái chỉnh sửa (editedStatus) không được để trống")
    private AttendanceStatus editedStatus;
}
