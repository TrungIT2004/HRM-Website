package com.minhtrung.hrm.permissions.entities;

import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.UUID;

import com.minhtrung.hrm.permissions.enums.PermissionKey;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "user_permission_grants")
// ponytail: composite PK thay surrogate id — bảng chỉ có vài chục dòng, khỏi join User entity
@IdClass(PermissionGrant.PermissionGrantId.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class PermissionGrant {

    @Id
    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Id
    @Enumerated(EnumType.STRING)
    @Column(name = "permission", nullable = false, length = 40)
    private PermissionKey permission;

    @Column(name = "granted_by", nullable = false)
    private UUID grantedBy;

    // ponytail: set lúc construct (replaceGrants) thay vì @CreationTimestamp — Hibernate gán lúc flush nên DTO đọc ra null
    @Column(name = "granted_at", nullable = false, updatable = false)
    private LocalDateTime grantedAt;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PermissionGrantId implements Serializable {
        private UUID userId;
        private PermissionKey permission;
    }
}
