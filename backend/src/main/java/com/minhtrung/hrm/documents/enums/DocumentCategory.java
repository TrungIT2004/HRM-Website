package com.minhtrung.hrm.documents.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum DocumentCategory {
    HANDOVER("Biên bản bàn giao công việc"),
    MEETING("Biên bản cuộc họp"),
    RECRUITMENT("Đơn xin bổ sung nhân sự"),
    LEAVE("Đơn xin nghỉ"),
    RESIGN("Đơn xin nghỉ việc"),
    HDLD("Hợp đồng lao động");

    private final String label;
}
