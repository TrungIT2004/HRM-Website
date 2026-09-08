package com.minhtrung.social_app.auth.dtos.internals;

import java.util.UUID;

import lombok.Data;

@Data
public class TokenPayload {
    private UUID userId, deviceId, sessionId;
    private String email;
    private String fullName;
    private String profilePicUrl;
    private String department;
    private String  job;
    public class builder {
    }
}
