package com.minhtrung.hrm.overtime.dtos.requests;

import java.time.LocalDate;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class OvertimeFilterRequest {
    private String status;
    private LocalDate fromDate;
    private LocalDate toDate;
    private String keyword;
}