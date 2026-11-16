package com.minhtrung.hrm.notifications.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.minhtrung.hrm.employees.entities.User;
import com.minhtrung.hrm.notifications.enums.NotificationAction;
import com.minhtrung.hrm.notifications.enums.NotificationPriority;
import com.minhtrung.hrm.notifications.enums.NotificationType;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.Index;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.annotations.UuidGenerator;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@NoArgsConstructor
@Getter
@Setter
@Entity
@Table(
    name = "notifications",
    indexes = {
        @Index(name = "idx_notifications_recipient_unread", columnList = "recipient_id, is_read"),
        @Index(name = "idx_notifications_request", columnList = "request_type, request_id"),
        @Index(name = "idx_notifications_recipient_created", columnList = "recipient_id, created_at")
    }
)
public class Notification {
    @Id
    @UuidGenerator(style = UuidGenerator.Style.TIME)
    private UUID notificationId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "recipient_id", referencedColumnName = "userId", foreignKey = @ForeignKey(name = "fk_notifications_recipient"))
    @JsonIgnore
    private User recipient;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sender_id", referencedColumnName = "userId", foreignKey = @ForeignKey(name = "fk_notifications_sender"))
    @JsonIgnore
    private User sender;

    @Column(name = "request_type", length = 50)
    @Enumerated(EnumType.STRING)
    private NotificationType requestType;

    @Column(name = "request_id")
    private UUID requestId;

    @Column(name = "action", length = 30)
    @Enumerated(EnumType.STRING)
    private NotificationAction action;

    @Column(name = "title", length = 255)
    private String title;

    @Column(name = "message", columnDefinition = "TEXT")
    private String message;

    @Column(name = "priority", length = 20)
    @Enumerated(EnumType.STRING)
    private NotificationPriority priority;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "metadata", columnDefinition = "jsonb")
    private Map<String, Object> metadata;

    @Column(name = "is_read", nullable = false)
    private Boolean isRead = false;

    @Column(name = "is_seen", nullable = false)
    private Boolean isSeen = false;

    @Column(name = "count", nullable = false)
    private Integer count = 1;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    // Helper methods
    public UUID getRecipientId() {
        return this.recipient != null ? recipient.getUserId() : null;
    }

    public UUID getSenderId() {
        return this.sender != null ? sender.getUserId() : null;
    }

    public String getSenderName() {
        if (metadata != null && metadata.containsKey("senderName")) {
            return (String) metadata.get("senderName");
        }
        return sender != null ? sender.getFirstName() + " " + sender.getLastName() : null;
    }
}