package com.minhtrung.hrm.notifications.dtos;

import com.minhtrung.hrm.notifications.enums.NotificationAction;
import com.minhtrung.hrm.notifications.enums.NotificationPriority;
import com.minhtrung.hrm.notifications.enums.NotificationType;

import java.util.Map;
import java.util.UUID;

public record NotificationEvent(
    NotificationType type,
    UUID requestId,
    NotificationAction action,
    String title,
    String message,
    Map<String, Object> metadata,
    NotificationPriority priority
) {
    public static NotificationEvent of(
            NotificationType type,
            UUID requestId,
            NotificationAction action,
            String title,
            String message,
            Map<String, Object> metadata,
            NotificationPriority priority) {
        return new NotificationEvent(type, requestId, action, title, message, metadata, priority);
    }

    public static NotificationEvent of(
            NotificationType type,
            UUID requestId,
            NotificationAction action,
            String title,
            String message) {
        return new NotificationEvent(type, requestId, action, title, message, Map.of(), NotificationPriority.NORMAL);
    }
}