package com.minhtrung.hrm.interfaces;

import java.util.UUID;

public interface UserPayrollProjection {
    UUID getUserId();
    Double getBaseSalary();
    String getAttendances();
    String getOvertimes();
}