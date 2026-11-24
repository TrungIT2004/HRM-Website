package com.minhtrung.hrm.notifications.controllers;

import java.util.Map;
import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;
import com.minhtrung.hrm.common.context.RequestContextHolder;
import com.minhtrung.hrm.notifications.dtos.responses.NotificationResponse;
import com.minhtrung.hrm.notifications.entities.NotificationType;
import com.minhtrung.hrm.notifications.services.NotificationService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    private TokenPayload currentUser() {
        return RequestContextHolder.get().getTokenPayload();
    }

    @GetMapping
    public ResponseEntity<Page<NotificationResponse>> getNotifications(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) NotificationType type,
            @RequestParam(required = false) String readStatus) {

        UUID userId = currentUser().getUserId();
        Pageable pageable = PageRequest.of(page, size);
        Page<NotificationResponse> result = notificationService.getForUser(userId, pageable, type, readStatus)
                .map(this::mapToResponse);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/unread-count")
    public ResponseEntity<Map<String, Long>> getUnreadCount() {
        UUID userId = currentUser().getUserId();
        long count = notificationService.getUnreadCount(userId);
        return ResponseEntity.ok(Map.of("count", count));
    }

    @PatchMapping("/{id}/read")
    public ResponseEntity<Void> markRead(@PathVariable UUID id) {
        UUID userId = currentUser().getUserId();
        notificationService.markRead(userId, id);
        return ResponseEntity.noContent().build();
    }

    @PatchMapping("/read-all")
    public ResponseEntity<Void> markAllRead() {
        UUID userId = currentUser().getUserId();
        notificationService.markAllRead(userId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{id}")
    public ResponseEntity<NotificationResponse> getNotification(@PathVariable UUID id) {
        UUID userId = currentUser().getUserId();
        // The service doesn't have a getById method, but we can use the existing one
        // For now, return 404 if not found in the user's notifications
        Page<NotificationResponse> page = notificationService.getForUser(userId, PageRequest.of(0, 1), null, null)
                .map(this::mapToResponse);
        return page.getContent().stream()
                .filter(n -> n.getNotificationId().equals(id))
                .findFirst()
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    private NotificationResponse mapToResponse(com.minhtrung.hrm.notifications.entities.Notification n) {
        return NotificationResponse.builder()
                .notificationId(n.getNotificationId())
                .type(n.getType())
                .title(n.getTitle())
                .body(n.getBody())
                .referenceId(n.getReferenceId())
                .referenceType(n.getReferenceType())
                .priority(n.getPriority())
                .metadata(n.getMetadata())
                .readAt(n.getReadAt())
                .createdAt(n.getCreatedAt())
                .read(n.isRead())
                .build();
    }
}