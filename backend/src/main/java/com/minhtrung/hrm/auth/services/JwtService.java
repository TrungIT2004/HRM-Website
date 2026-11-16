package com.minhtrung.hrm.auth.services;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;

import java.security.Key;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Service
public class JwtService {

    @Value("${jwt.secret.access}")
    private String accessSecret;

    @Value("${jwt.secret.refresh}")
    private String refreshSecret;

    private Key getSignKey(String secret) {
        return Keys.hmacShaKeyFor(secret.getBytes());
    }

    private String buildToken(TokenPayload tokenPayload, Map<String, Object> extraClaims, String secret, long ttlMillis) {
        Map<String, Object> claims = new LinkedHashMap<>();
        claims.put("sessionId", tokenPayload.getSessionId().toString());
        claims.put("deviceId", tokenPayload.getDeviceId());
        claims.put("email", tokenPayload.getEmail());
        claims.put("profilePicUrl", tokenPayload.getProfilePicUrl());
        claims.put("department", tokenPayload.getDepartment());
        claims.put("job", tokenPayload.getJob());
        claims.putAll(extraClaims);

        var builder = Jwts.builder()
                .setSubject(tokenPayload.getUserId().toString())
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + ttlMillis));
        claims.forEach(builder::claim);
        return builder.signWith(getSignKey(secret), SignatureAlgorithm.HS256).compact();
    }

    // 🔹 Access Token (short-lived)
    public String generateAccessToken(TokenPayload tokenPayload) {
        List<String> permissions = tokenPayload.getPermissions() != null
                ? new ArrayList<>(tokenPayload.getPermissions()) : List.of();

        Map<String, Object> extraClaims = new LinkedHashMap<>();
        extraClaims.put("fullName", tokenPayload.getFullName());
        extraClaims.put("permissions", permissions);
        return buildToken(tokenPayload, extraClaims, accessSecret, 1000 * 60 * 15); // 15 min
    }

    // 🔹 Refresh Token (long-lived)
    public String generateRefreshToken(TokenPayload tokenPayload) {
        // ponytail: giữ nguyên key "fullnName" (typo cũ) để không đổi behavior token đang lưu
        Map<String, Object> extraClaims = new LinkedHashMap<>();
        extraClaims.put("fullnName", tokenPayload.getFullName());
        return buildToken(tokenPayload, extraClaims, refreshSecret, 1000L * 60 * 60 * 24 * 7); // 7 days
    }

    public TokenPayload extractAll(String token, String secret) {
        Claims claims = Jwts.parserBuilder()
                .setSigningKey(getSignKey(secret)) 
                .build()
                .parseClaimsJws(token)
                .getBody();

        UUID userId = UUID.fromString((String) claims.get("sub"));
        UUID sessionId = UUID.fromString((String) claims.get("sessionId"));
        UUID deviceIdFromToken = UUID.fromString((String) claims.get("deviceId"));
        String email = (String) claims.get("email");
        String fullName = (String) claims.get("fullName");
        String profilePicUrl = (String) claims.get("profilePicUrl");
        String department = (String) claims.get("department");
        String job = (String) claims.get("job");
        Object permissionsClaim = claims.get("permissions");

        TokenPayload tokenPayload = new TokenPayload();
        tokenPayload.setUserId(userId);
        tokenPayload.setDeviceId(deviceIdFromToken);
        tokenPayload.setSessionId(sessionId);
        tokenPayload.setEmail(email);
        tokenPayload.setFullName(fullName);
        tokenPayload.setProfilePicUrl(profilePicUrl);
        tokenPayload.setDepartment(department);
        tokenPayload.setJob(job);
        if (permissionsClaim instanceof List) {
            Set<String> permissions = new HashSet<>();
            for (Object p : (List<?>) permissionsClaim) {
                if (p != null) permissions.add(p.toString());
            }
            tokenPayload.setPermissions(permissions);
        }

        return tokenPayload;
    }
    
    // 🔹 Validate token
    public boolean isTokenValid(String token, String secret) {
        try {
            Jwts.parserBuilder()
                    .setSigningKey(getSignKey(secret))
                    .build()
                    .parseClaimsJws(token);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}