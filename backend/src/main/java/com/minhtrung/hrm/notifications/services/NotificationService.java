package com.minhtrung.hrm.notifications.services;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import com.minhtrung.hrm.employees.entities.User;
import com.minhtrung.hrm.employees.repositories.UserRepository;
import com.minhtrung.hrm.notifications.entities.Notification;
import com.minhtrung.hrm.notifications.entities.NotificationPriority;
import com.minhtrung.hrm.notifications.entities.NotificationType;
import com.minhtrung.hrm.notifications.events.NotificationEvent;
import com.minhtrung.hrm.notifications.repositories.NotificationRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final SimpMessagingTemplate messagingTemplate;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void createAndPush(NotificationEvent event) {
        log.info("Creating notification for user: {}, type: {}", event.getRecipientUserId(), event.getType());

        User userRef = userRepository.getReferenceById(event.getRecipientUserId());

        Notification notification = Notification.builder()
                .user(userRef)
                .type(event.getType())
                .title(event.getTitle())
                .body(event.getBody())
                .referenceId(event.getReferenceId())
                .referenceType(event.getReferenceType())
                .priority(event.getPriority())
                .metadata(event.getMetadata())
                .build();

        Notification saved = notificationRepository.save(notification);

        // Push realtime via WebSocket
        NotificationMessage message = NotificationMessage.builder()
                .type("NOTIFICATION_CREATED")
                .payload(NotificationPayload.builder()
                        .notificationId(saved.getNotificationId().toString())
                        .type(saved.getType().name())
                        .title(saved.getTitle())
                        .body(saved.getBody())
                        .referenceId(saved.getReferenceId().toString())
                        .referenceType(saved.getReferenceType())
                        .priority(saved.getPriority().name())
                        .metadata(saved.getMetadata())
                        .createdAt(saved.getCreatedAt().toString())
                        .build())
                .build();

        messagingTemplate.convertAndSendToUser(
                event.getRecipientUserId().toString(),
                "/queue/notifications",
                message
        );

        log.info("Notification created and pushed: {}", saved.getNotificationId());
    }

    @Transactional(readOnly = true)
    public Page<Notification> getForUser(UUID userId, Pageable pageable, NotificationType type, String readStatus) {
        return notificationRepository.findByUserIdWithFilters(userId, type, readStatus, pageable);
    }

    @Transactional(readOnly = true)
    public long getUnreadCount(UUID userId) {
        return notificationRepository.countUnreadByUserId(userId);
    }

    @Transactional
    public void markRead(UUID userId, UUID notificationId) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new IllegalArgumentException("Notification not found: " + notificationId));

        if (!notification.getUserId().equals(userId)) {
            throw new SecurityException("Notification does not belong to user");
        }

        if (notification.getReadAt() == null) {
            notification.setReadAt(LocalDateTime.now());
            notificationRepository.save(notification);
        }
    }

    @Transactional
    public void markAllRead(UUID userId) {
        notificationRepository.findUnreadByUserId(userId, Pageable.unpaged())
                .forEach(n -> n.setReadAt(LocalDateTime.now()));
    }
}