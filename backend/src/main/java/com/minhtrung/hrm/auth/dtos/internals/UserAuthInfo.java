package com.minhtrung.hrm.auth.dtos.internals;

import java.util.UUID;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class UserAuthInfo {
    private UUID userId;
    private String email;
    private String password;
    private String fullName;
    private String profilePicUrl;
    private String department;
    private String job;
}
