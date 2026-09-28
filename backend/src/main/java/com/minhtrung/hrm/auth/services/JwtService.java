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
import java.util.List;
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

    // 🔹 Access Token (short-lived)
    public String generateAccessToken(TokenPayload tokenPayload) {
        UUID userId = tokenPayload.getUserId();
        UUID sessionId = tokenPayload.getSessionId();
        UUID deviceId = tokenPayload.getDeviceId();
        String email = tokenPayload.getEmail();
        String fullName = tokenPayload.getFullName();
        String profilePicUrl = tokenPayload.getProfilePicUrl();
        String department = tokenPayload.getDepartment();
        String job = tokenPayload.getJob();
        List<String> permissions = tokenPayload.getPermissions() != null
                ? new ArrayList<>(tokenPayload.getPermissions()) : List.of();

        return Jwts.builder()
                .setSubject(userId.toString())
                .claim("sessionId", sessionId.toString())
                .claim("deviceId", deviceId)
                .claim("email", email)
                .claim("fullName", fullName)
                .claim("profilePicUrl", profilePicUrl)
                .claim("department", department)
                .claim("job", job)
                .claim("permissions", permissions)
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + 1000 * 60 * 15)) // 15 min
                .signWith(getSignKey(accessSecret), SignatureAlgorithm.HS256)
                .compact();
    }

    // 🔹 Refresh Token (long-lived)
    public String generateRefreshToken(TokenPayload tokenPayload) {
        UUID userId = tokenPayload.getUserId();
        UUID sessionId = tokenPayload.getSessionId();
        UUID deviceId = tokenPayload.getDeviceId();
        String fullName = tokenPayload.getFullName();
        String email = tokenPayload.getEmail();
        String profilePicUrl = tokenPayload.getProfilePicUrl();
        String department = tokenPayload.getDepartment();
        String job = tokenPayload.getJob();

        return Jwts.builder()
                .setSubject(userId.toString())
                .claim("sessionId", sessionId.toString())
                .claim("deviceId", deviceId)
                .claim("email", email)
                .claim("fullnName", fullName)
                .claim("profilePicUrl", profilePicUrl)
                .claim("department", department)
                .claim("job", job)
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + 1000L * 60 * 60 * 24 * 7)) // 7 days
                .signWith(getSignKey(refreshSecret), SignatureAlgorithm.HS256)
                .compact();
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