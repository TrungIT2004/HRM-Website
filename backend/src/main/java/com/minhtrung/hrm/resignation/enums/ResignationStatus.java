package com.minhtrung.hrm.resignation.enums;

public enum ResignationStatus {
    PENDING, // Nhân viên vừa nộp đơn, chờ Trưởng phòng duyệt bàn giao
    MANAGER_APPROVED,
    MANAGER_REJECTED, // Trưởng phòng đã duyệt bàn giao, chờ HR/BGĐ chốt ngày & quyết toán
    APPROVED, // HR/BGĐ đã duyệt chính thức (trong thời gian chờ đến ngày nghỉ)
    REJECTED, // Bị từ chối
    CANCELLED, // Nhân viên tự rút đơn
    COMPLETED // Đã đến ngày làm việc cuối, thu hồi tài sản, quyết toán lương & khóa tài khoản
}
