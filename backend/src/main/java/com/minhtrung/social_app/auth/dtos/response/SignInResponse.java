package com.minhtrung.social_app.auth.dtos.response;

import com.fasterxml.jackson.annotation.JsonIgnore;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@NoArgsConstructor
@Setter
@Getter
public class SignInResponse {
    private String accessToken;

    @JsonIgnore
    private String refreshToken;
    
    private String email;
    private String fullName;
    private String profilePicUrl;
    private String department;
    private String job;
}
