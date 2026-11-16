package com.minhtrung.hrm.notifications.dtos;

import com.minhtrung.hrm.notifications.enums.NotificationAction;
import com.minhtrung.hrm.notifications.enums.NotificationPriority;
import com.minhtrung.hrm.notifications.enums.NotificationType;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationDTO {
    private UUID notificationId;
    private UUID recipientId;
    private UUID senderId;
    private NotificationType requestType;
    private UUID requestId;
    private NotificationAction action;
    private String title;
    private String message;
    private NotificationPriority priority;
    private Map<String, Object> metadata;
    private Boolean isRead;
    private Boolean isSeen;
    private Integer count;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // Helper method to get sender name from metadata
    public String getSenderName() {
        if (metadata != null && metadata.containsKey("senderName")) {
            return (String) metadata.get("senderName");
        }
        return null;
    }

    // Helper method to get request type display name
    public String getRequestTypeDisplay() {
        if (requestType == null) return "General";
        return switch (requestType) {
            case LEAVE -> "Leave Request";
            case OVERTIME -> "Overtime Request";
            case RESIGNATION -> "Resignation Request";
            case ASSET_REQUEST -> "Asset Request";
            case GENERIC -> "Notification";
        };
    }

    // Helper method to get action display name
    public String getActionDisplay() {
        if (action == null) return "Updated";
        return switch (action) {
            case SUBMITTED -> "Submitted";
            case APPROVED -> "Approved";
            case REJECTED -> "Rejected";
            case CANCELLED -> "Cancelled";
            case REVOKED -> "Revoked";
        };
    }
}