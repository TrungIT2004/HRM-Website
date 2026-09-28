package com.minhtrung.hrm.permissions.services;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.minhtrung.hrm.permissions.entities.PermissionGrant;
import com.minhtrung.hrm.permissions.enums.PermissionKey;
import com.minhtrung.hrm.permissions.repositories.PermissionGrantRepository;

import lombok.RequiredArgsConstructor;

/**
 * Nguồn sự thật cho grants. Bảng rỗng = hành vi cũ (mọi hasPermission false).
 * Enforcement dùng repo trực tiếp (luôn tươi); JWT chỉ snapshot cho frontend gating.
 */
@Service
@RequiredArgsConstructor
public class PermissionService {

    private final PermissionGrantRepository repository;

    @Transactional(readOnly = true)
    public boolean hasPermission(UUID userId, PermissionKey key) {
        if (userId == null || key == null) return false;
        return repository.existsByUserIdAndPermission(userId, key);
    }

    @Transactional(readOnly = true)
    public Set<String> findKeysByUserId(UUID userId) {
        if (userId == null) return Set.of();
        return repository.findByUserId(userId).stream()
                .map(g -> g.getPermission().name())
                .collect(Collectors.toSet());
    }

    @Transactional(readOnly = true)
    public List<PermissionGrant> listByUserId(UUID userId) {
        if (userId == null) return List.of();
        return repository.findByUserId(userId);
    }

    /** Replace-set: keys lạ bị bỏ qua, untick = xóa dòng (quyền gốc không ảnh hưởng). */
    @Transactional
    public List<PermissionGrant> replaceGrants(UUID targetUserId, List<String> keys, UUID grantedBy) {
        repository.deleteByUserId(targetUserId);
        if (keys == null || keys.isEmpty()) return List.of();
        List<PermissionGrant> grants = keys.stream()
                .map(k -> {
                    try {
                        return new PermissionGrant(targetUserId, PermissionKey.valueOf(k), grantedBy, LocalDateTime.now());
                    } catch (IllegalArgumentException e) {
                        return null;
                    }
                })
                .filter(g -> g != null)
                .collect(Collectors.toList());
        return repository.saveAll(grants);
    }
}
