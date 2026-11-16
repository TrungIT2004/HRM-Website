package com.minhtrung.hrm.notifications.controller;

import com.minhtrung.hrm.common.context.RequestContextHolder;
import com.minhtrung.hrm.notifications.dtos.NotificationDTO;
import com.minhtrung.hrm.notifications.service.NotificationService;
import com.minhtrung.hrm.notifications.service.SseEmitterRegistry;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
@Slf4j
public class NotificationController {

    private final NotificationService notificationService;
    private final SseEmitterRegistry sseEmitterRegistry;
    private final com.minhtrung.hrm.notifications.repository.NotificationRepository notificationRepository;

    /**
     * SSE endpoint for real-time notifications
     * GET /api/notifications/stream
     */
    @GetMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter stream() {
        // Get current user from request context (set by JwtAuthFilter)
        if (RequestContextHolder.get() == null || RequestContextHolder.get().getTokenPayload().getUserId() == null) {
            log.warn("SSE connection attempt without authenticated user");
            SseEmitter emitter = new SseEmitter(0L);
            emitter.completeWithError(new IllegalStateException("Unauthorized"));
            return emitter;
        }

        UUID userId = RequestContextHolder.get().getTokenPayload().getUserId();
        log.info("SSE connection opened for user: {}", userId);

        // Create emitter with long timeout (1 hour)
        SseEmitter emitter = new SseEmitter(3600000L);

        // Register emitter
        sseEmitterRegistry.addEmitter(userId, emitter);

        // Send initial unread count
        try {
            long unreadCount = notificationRepository.countByRecipient_UserIdAndIsReadFalse(userId);
            emitter.send(SseEmitter.event()
                    .name("unread_count")
                    .data(Map.of("count", unreadCount)));
        } catch (Exception e) {
            log.error("Failed to send initial unread count: {}", e.getMessage());
        }

        // Cleanup on completion/timeout/error
        emitter.onCompletion(() -> {
            log.debug("SSE connection closed (completion) for user: {}", userId);
            sseEmitterRegistry.removeEmitter(userId, emitter);
        });
        emitter.onTimeout(() -> {
            log.debug("SSE connection closed (timeout) for user: {}", userId);
            sseEmitterRegistry.removeEmitter(userId, emitter);
        });
        emitter.onError(e -> {
            log.debug("SSE connection error for user {}: {}", userId, e.getMessage());
            sseEmitterRegistry.removeEmitter(userId, emitter);
        });

        return emitter;
    }

    /**
     * Get paginated notifications list
     * GET /api/notifications?page=0&size=20&unreadOnly=false
     */
    @GetMapping
    public ResponseEntity<Page<NotificationDTO>> getNotifications(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "false") boolean unreadOnly) {

        if (RequestContextHolder.get() == null || RequestContextHolder.get().getTokenPayload().getUserId() == null) {
            return ResponseEntity.status(401).build();
        }

        UUID userId = RequestContextHolder.get().getTokenPayload().getUserId();
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));

        Page<NotificationDTO> notificationsPage = unreadOnly
                ? notificationRepository.findUnreadDTOsByRecipientId(userId, pageable)
                : notificationRepository.findDTOsByRecipientId(userId, pageable);

        return ResponseEntity.ok(notificationsPage);
    }

    /**
     * Get unread count
     * GET /api/notifications/unread-count
     */
    @GetMapping("/unread-count")
    public ResponseEntity<Map<String, Long>> getUnreadCount() {
        if (RequestContextHolder.get() == null || RequestContextHolder.get().getTokenPayload().getUserId() == null) {
            return ResponseEntity.status(401).build();
        }

        UUID userId = RequestContextHolder.get().getTokenPayload().getUserId();
        long count = notificationRepository.countByRecipient_UserIdAndIsReadFalse(userId);

        return ResponseEntity.ok(Map.of("count", count));
    }

    /**
     * Mark single notification as read
     * PATCH /api/notifications/{id}/read
     */
    @PatchMapping("/{id}/read")
    public ResponseEntity<Void> markAsRead(@PathVariable UUID id) {
        if (RequestContextHolder.get() == null || RequestContextHolder.get().getTokenPayload().getUserId() == null) {
            return ResponseEntity.status(401).build();
        }

        UUID userId = RequestContextHolder.get().getTokenPayload().getUserId();

        // Verify notification belongs to user
        NotificationDTO notification = notificationRepository.findDTOsByRecipientId(userId, PageRequest.of(0, 1))
                .stream()
                .filter(n -> n.getNotificationId().equals(id))
                .findFirst()
                .orElse(null);

        if (notification == null) {
            return ResponseEntity.notFound().build();
        }

        notificationRepository.markAsRead(id, LocalDateTime.now());

        // Broadcast updated unread count
        long unreadCount = notificationRepository.countByRecipient_UserIdAndIsReadFalse(userId);
        sseEmitterRegistry.broadcastUnreadCount(userId, unreadCount);

        return ResponseEntity.ok().build();
    }

    /**
     * Mark all notifications as read
     * PATCH /api/notifications/read-all
     */
    @PatchMapping("/read-all")
    public ResponseEntity<Void> markAllAsRead() {
        if (RequestContextHolder.get() == null || RequestContextHolder.get().getTokenPayload().getUserId() == null) {
            return ResponseEntity.status(401).build();
        }

        UUID userId = RequestContextHolder.get().getTokenPayload().getUserId();
        notificationRepository.markAllAsRead(userId, LocalDateTime.now());

        // Broadcast updated unread count (0)
        sseEmitterRegistry.broadcastUnreadCount(userId, 0);

        return ResponseEntity.ok().build();
    }
}