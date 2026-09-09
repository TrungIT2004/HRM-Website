package com.minhtrung.hrm.overtime.dtos.requests;

import java.time.LocalDate;
import java.util.UUID;

import com.minhtrung.hrm.overtime.enums.OvertimeRecordStatus;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@AllArgsConstructor
@Getter
@Setter
public class OTRecordParamsRequest {
    private LocalDate startDateTime;
    private LocalDate EndDateTime;
    private OvertimeRecordStatus status;
    private UUID departmentId;
}
