package com.minhtrung.hrm.notifications.services;

import java.util.Map;

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
public class NotificationPayload {
    private String notificationId;
    private String type;
    private String title;
    private String body;
    private String referenceId;
    private String referenceType;
    private String priority;
    private Map<String, Object> metadata;
    private String createdAt;
}