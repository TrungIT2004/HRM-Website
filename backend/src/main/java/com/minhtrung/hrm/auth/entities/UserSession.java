package com.minhtrung.hrm.auth.entities;

import java.time.LocalDate;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import com.minhtrung.hrm.auth.dtos.internals.ClientMetaData;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
@Entity
@Table(name = "user_sessions")
public class UserSession {
    @Id
    private UUID sessionId;
    
    @Column(nullable = false)
    private UUID userId;

    @Column(nullable = false)
    private UUID deviceId;
    
    @Column(nullable = false, columnDefinition = "TEXT")
    private String token;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(nullable = false, columnDefinition = "jsonb")
    private ClientMetaData metaData;

    @Column(nullable = false, columnDefinition = "BOOLEAN DEFAULT FALSE")
    private boolean revoked = false;

    @CreationTimestamp
    @Column(nullable = false)
    private LocalDate createdAt;
}
