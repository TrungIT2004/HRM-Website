package com.minhtrung.hrm.attendance.dtos.response;

import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

import com.fasterxml.jackson.annotation.JsonProperty;

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
public class WorkShiftResponse {
    private UUID shiftId;
    private String name;
    private List<WorkShiftScheduleItemDto> schedules;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class WorkShiftScheduleItemDto {
        private UUID scheduleId;
        private Integer dayOfWeek;
        private String dayName;

        @JsonProperty("isWorking")
        private boolean isWorking;
        private LocalTime startTime;
        private LocalTime endTime;
        private LocalTime restStartTime;
        private LocalTime restEndTime;
    }
}
