package com.minhtrung.social_app.interfaces;

import java.util.UUID;

public interface UserPayrollProjection {
    UUID getUserId();
    Double getBaseSalary();
    String getAttendances();
    String getOvertimes();
}