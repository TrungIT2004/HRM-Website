package com.minhtrung.hrm.admin.dtos.responses;

import java.time.LocalDateTime;
import java.util.UUID;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class UserPermissionResponse {
    private String key;
    private String label;
    private UUID grantedBy;
    private String grantedByName;
    private LocalDateTime grantedAt;
}
