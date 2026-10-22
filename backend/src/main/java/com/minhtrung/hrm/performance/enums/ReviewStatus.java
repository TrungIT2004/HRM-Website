package com.minhtrung.hrm.performance.enums;

public enum ReviewStatus {
    DRAFT,           // Vua tao, nhan vien dang tu cham
    SELF_SUBMITTED, // Nhan vien da nop -> cho manager cham
    MANAGER_SCORED, // Manager da cham -> cho HR lock
    LOCKED           // HR da khoa, lam lich su
}
