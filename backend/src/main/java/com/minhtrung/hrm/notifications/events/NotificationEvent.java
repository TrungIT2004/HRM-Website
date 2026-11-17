package com.minhtrung.hrm.notifications.events;

import java.util.Map;
import java.util.UUID;

import com.minhtrung.hrm.notifications.entities.NotificationPriority;
import com.minhtrung.hrm.notifications.entities.NotificationType;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
public class NotificationEvent {
    private UUID recipientUserId;
    private NotificationType type;
    private String title;
    private String body;
    private UUID referenceId;
    private String referenceType;
    private NotificationPriority priority = NotificationPriority.NORMAL;
    private Map<String, Object> metadata;
}