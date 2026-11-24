package com.minhtrung.hrm.notifications.dtos.responses;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

import com.minhtrung.hrm.notifications.entities.NotificationPriority;
import com.minhtrung.hrm.notifications.entities.NotificationType;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
@Builder
public class NotificationResponse {
    private UUID notificationId;
    private NotificationType type;
    private String title;
    private String body;
    private UUID referenceId;
    private String referenceType;
    private NotificationPriority priority;
    private Map<String, Object> metadata;
    private LocalDateTime readAt;
    private LocalDateTime createdAt;
    private boolean read;
}