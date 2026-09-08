package com.minhtrung.social_app.auth.dtos.requests;

import java.util.UUID;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
public class AutoSignInRequest {
    private String token;
    private UUID deviceId;
}
