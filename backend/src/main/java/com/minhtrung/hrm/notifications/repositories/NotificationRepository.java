package com.minhtrung.hrm.notifications.repositories;

import java.time.LocalDateTime;
import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.minhtrung.hrm.notifications.entities.Notification;
import com.minhtrung.hrm.notifications.entities.NotificationType;

public interface NotificationRepository extends JpaRepository<Notification, UUID> {

    @Query(value = "SELECT n FROM Notification n " +
                   "WHERE n.user.userId = :userId " +
                   "AND (:type IS NULL OR n.type = :type) " +
                   "AND (:readStatus IS NULL OR " +
                   "     (:readStatus = 'UNREAD' AND n.readAt IS NULL) " +
                   "     OR (:readStatus = 'READ' AND n.readAt IS NOT NULL)) " +
                   "ORDER BY n.createdAt DESC")
    Page<Notification> findByUserIdWithFilters(
            @Param("userId") UUID userId,
            @Param("type") NotificationType type,
            @Param("readStatus") String readStatus,
            Pageable pageable);

    @Query(value = "SELECT COUNT(n) FROM Notification n " +
                   "WHERE n.user.userId = :userId AND n.readAt IS NULL")
    long countUnreadByUserId(@Param("userId") UUID userId);

    @Query(value = "SELECT n FROM Notification n " +
                   "WHERE n.user.userId = :userId AND n.readAt IS NULL " +
                   "ORDER BY n.createdAt DESC")
    Page<Notification> findUnreadByUserId(@Param("userId") UUID userId, Pageable pageable);
}