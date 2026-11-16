package com.minhtrung.hrm.notifications.repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.minhtrung.hrm.notifications.dtos.NotificationDTO;
import com.minhtrung.hrm.notifications.entity.Notification;
import com.minhtrung.hrm.notifications.enums.NotificationType;

public interface NotificationRepository extends JpaRepository<Notification, UUID> {

    // Find all notifications for a recipient, ordered by createdAt desc
    Page<Notification> findByRecipient_UserIdOrderByCreatedAtDesc(UUID recipientId, Pageable pageable);

    // Find unread notifications for a recipient
    Page<Notification> findByRecipient_UserIdAndIsReadFalseOrderByCreatedAtDesc(UUID recipientId, Pageable pageable);

    // Count unread notifications for a recipient
    long countByRecipient_UserIdAndIsReadFalse(UUID recipientId);

    // Find by request type and request id
    List<Notification> findByRequestTypeAndRequestId(NotificationType requestType, UUID requestId);

    // Mark single notification as read
    @org.springframework.data.jpa.repository.Modifying
    @Query("UPDATE Notification n SET n.isRead = true, n.updatedAt = :now WHERE n.notificationId = :notificationId")
    void markAsRead(@Param("notificationId") UUID notificationId, @Param("now") LocalDateTime now);

    // Mark all notifications as read for a recipient
    @org.springframework.data.jpa.repository.Modifying
    @Query("UPDATE Notification n SET n.isRead = true, n.updatedAt = :now WHERE n.recipient.userId = :recipientId")
    void markAllAsRead(@Param("recipientId") UUID recipientId, @Param("now") LocalDateTime now);

    // Fetch DTO projection for frontend
    @Query("""
        SELECT new com.minhtrung.hrm.notifications.dtos.NotificationDTO(
            n.notificationId,
            n.recipient.userId,
            n.sender.userId,
            n.requestType,
            n.requestId,
            n.action,
            n.title,
            n.message,
            n.priority,
            n.metadata,
            n.isRead,
            n.isSeen,
            n.count,
            n.createdAt,
            n.updatedAt
        )
        FROM Notification n
        WHERE n.recipient.userId = :recipientId
        ORDER BY n.createdAt DESC
    """)
    Page<NotificationDTO> findDTOsByRecipientId(@Param("recipientId") UUID recipientId, Pageable pageable);

    // Fetch unread DTOs
    @Query("""
        SELECT new com.minhtrung.hrm.notifications.dtos.NotificationDTO(
            n.notificationId,
            n.recipient.userId,
            n.sender.userId,
            n.requestType,
            n.requestId,
            n.action,
            n.title,
            n.message,
            n.priority,
            n.metadata,
            n.isRead,
            n.isSeen,
            n.count,
            n.createdAt,
            n.updatedAt
        )
        FROM Notification n
        WHERE n.recipient.userId = :recipientId AND n.isRead = false
        ORDER BY n.createdAt DESC
    """)
    Page<NotificationDTO> findUnreadDTOsByRecipientId(@Param("recipientId") UUID recipientId, Pageable pageable);
}