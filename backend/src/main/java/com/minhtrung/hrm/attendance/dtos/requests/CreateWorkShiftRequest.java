package com.minhtrung.hrm.attendance.dtos.requests;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonProperty;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
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
public class CreateWorkShiftRequest {

    @NotBlank(message = "Tên ca làm việc không được để trống")
    private String name;

    @Valid
    @NotEmpty(message = "Danh sách lịch trình các ngày trong tuần không được để trống")
    private List<DailyScheduleRequest> schedules;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class DailyScheduleRequest {
        @NotNull(message = "Thứ trong tuần (dayOfWeek: 1..7) không được để trống")
        @Min(value = 1, message = "dayOfWeek phải từ 1 (Thứ 2) đến 7 (Chủ nhật)")
        @Max(value = 7, message = "dayOfWeek phải từ 1 (Thứ 2) đến 7 (Chủ nhật)")
        private Integer dayOfWeek;

        @JsonProperty("isWorking")
        @Builder.Default
        private boolean isWorking = true;

        // String thay vì LocalTime: MVC dùng Jackson 3 (tools.jackson) nên annotation
        // com.fasterxml bị ngó lơ — parse "HH:mm" từ <input type=time> rớt thành 500.
        // Nhận raw string rồi parse lenient trong service, sai thì trả 400 kèm msg tiếng Việt.
        private String startTime;

        private String endTime;

        private String restStartTime;

        private String restEndTime;
    }
}
