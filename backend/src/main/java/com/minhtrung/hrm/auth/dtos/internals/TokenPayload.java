package com.minhtrung.hrm.auth.dtos.internals;

import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TokenPayload {
    private UUID userId, deviceId, sessionId;
    private String email;
    private String fullName;
    private String profilePicUrl;
    private String department;
    private String  job;
    // ponytail: snapshot grants cho frontend gating; enforcement backend đọc repo (luôn tươi)
    private Set<String> permissions = new HashSet<>();
}
