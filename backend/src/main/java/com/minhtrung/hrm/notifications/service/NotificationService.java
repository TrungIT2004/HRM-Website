package com.minhtrung.hrm.notifications.service;

import com.minhtrung.hrm.employees.entities.User;
import com.minhtrung.hrm.employees.repositories.UserRepository;
import com.minhtrung.hrm.notifications.dtos.NotificationEvent;
import com.minhtrung.hrm.notifications.dtos.NotificationDTO;
import com.minhtrung.hrm.notifications.entity.Notification;
import com.minhtrung.hrm.notifications.enums.NotificationAction;
import com.minhtrung.hrm.notifications.enums.NotificationPriority;
import com.minhtrung.hrm.notifications.enums.NotificationType;
import com.minhtrung.hrm.notifications.repository.NotificationRepository;

import jakarta.transaction.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final SseEmitterRegistry sseEmitterRegistry;

    @Transactional
    public void emit(UUID recipientId, NotificationEvent event) {
        if (recipientId == null) {
            log.warn("Cannot emit notification: recipientId is null");
            return;
        }

        User recipient = userRepository.findById(recipientId).orElse(null);
        if (recipient == null) {
            log.warn("Cannot emit notification: recipient not found for id: {}", recipientId);
            return;
        }

        Notification notification = buildNotification(recipient, null, event);
        Notification saved = notificationRepository.save(notification);

        // Push via SSE
        sseEmitterRegistry.broadcastToUser(recipientId, toDTO(saved));

        // Update unread count
        long unreadCount = notificationRepository.countByRecipient_UserIdAndIsReadFalse(recipientId);
        sseEmitterRegistry.broadcastUnreadCount(recipientId, unreadCount);

        log.info("Notification emitted to user {}: {} - {}", recipientId, event.action(), event.title());
    }

    @Transactional
    public void emitToUsers(List<UUID> recipientIds, NotificationEvent event) {
        if (recipientIds == null || recipientIds.isEmpty()) {
            return;
        }

        List<User> recipients = userRepository.findAllById(recipientIds);
        for (User recipient : recipients) {
            Notification notification = buildNotification(recipient, null, event);
            Notification saved = notificationRepository.save(notification);

            sseEmitterRegistry.broadcastToUser(recipient.getUserId(), toDTO(saved));

            long unreadCount = notificationRepository.countByRecipient_UserIdAndIsReadFalse(recipient.getUserId());
            sseEmitterRegistry.broadcastUnreadCount(recipient.getUserId(), unreadCount);
        }

        log.info("Notification emitted to {} users: {} - {}", recipients.size(), event.action(), event.title());
    }

    @Transactional
    public void emitToRole(String role, NotificationEvent event) {
        List<User> users = userRepository.findByJobTitleContainingIgnoreCase(role);
        emitToUsers(users.stream().map(User::getUserId).collect(Collectors.toList()), event);
    }

    @Transactional
    public void emitToDepartment(UUID departmentId, NotificationEvent event) {
        List<User> users = userRepository.findByDepartment_DepartmentId(departmentId);
        emitToUsers(users.stream().map(User::getUserId).collect(Collectors.toList()), event);
    }

    @Transactional
    public void emitToApprovers(UUID requestId, NotificationEvent event) {
        // This is a generic method - specific implementations in LeaveService, OvertimeService, etc.
        // will call emitToUsers with the correct approver IDs
        log.warn("emitToApprovers called generically - should be overridden by specific service");
    }

    // Recipient resolution based on action type
    @Transactional
    public void emitForRequest(UUID requestId, NotificationType type, NotificationAction action,
                               UUID requestorId, UUID approverId, String requestorName,
                               String approverName, Map<String, Object> metadata) {

        NotificationEvent event;
        List<UUID> recipients;

        switch (action) {
            case SUBMITTED -> {
                // SUBMITTED -> all users with approval permission
                recipients = resolveApprovers(requestId, type);
                event = buildEvent(type, requestId, action, requestorName, metadata, NotificationPriority.NORMAL);
            }
            case APPROVED, REJECTED -> {
                // APPROVED/REJECTED -> the requestor
                recipients = List.of(requestorId);
                event = buildEvent(type, requestId, action, approverName, metadata,
                    action == NotificationAction.APPROVED ? NotificationPriority.NORMAL : NotificationPriority.HIGH);
            }
            case CANCELLED -> {
                // CANCELLED -> the requestor (if cancelled by someone else) or approver (if cancelled by requestor)
                // For now, notify requestor
                recipients = List.of(requestorId);
                event = buildEvent(type, requestId, action, approverName, metadata, NotificationPriority.NORMAL);
            }
            case REVOKED -> {
                // REVOKED -> requestor + original approver
                recipients = List.of(requestorId, approverId).stream().filter(id -> id != null).collect(Collectors.toList());
                event = buildEvent(type, requestId, action, approverName, metadata, NotificationPriority.URGENT);
            }
            default -> {
                recipients = List.of(requestorId);
                event = buildEvent(type, requestId, action, approverName, metadata, NotificationPriority.NORMAL);
            }
        }

        emitToUsers(recipients, event);
    }

    List<UUID> resolveApprovers(UUID requestId, NotificationType type) {
        // This should be implemented by specific services
        // For now, return empty list - specific services will call emitToUsers with correct approvers
        log.debug("resolveApprovers called for {} request {}", type, requestId);
        return List.of();
    }

    private Notification buildNotification(User recipient, User sender, NotificationEvent event) {
        Notification notification = new Notification();
        notification.setRecipient(recipient);
        notification.setSender(sender);
        notification.setRequestType(event.type());
        notification.setRequestId(event.requestId());
        notification.setAction(event.action());
        notification.setTitle(event.title());
        notification.setMessage(event.message());
        notification.setPriority(event.priority() != null ? event.priority() : NotificationPriority.NORMAL);
        notification.setMetadata(event.metadata());
        notification.setIsRead(false);
        notification.setIsSeen(false);
        notification.setCount(1);
        return notification;
    }

    private NotificationEvent buildEvent(NotificationType type, UUID requestId, NotificationAction action,
                                          String actorName, Map<String, Object> metadata, NotificationPriority priority) {

        String title = buildTitle(type, action);
        String message = buildMessage(type, action, actorName, metadata);

        Map<String, Object> enrichedMetadata = new java.util.HashMap<>(metadata != null ? metadata : Map.of());
        enrichedMetadata.put("senderName", actorName);
        enrichedMetadata.put("requestType", type.name());
        enrichedMetadata.put("action", action.name());

        return NotificationEvent.of(type, requestId, action, title, message, enrichedMetadata, priority);
    }

    private String buildTitle(NotificationType type, NotificationAction action) {
        String typeDisplay = switch (type) {
            case LEAVE -> "Leave Request";
            case OVERTIME -> "Overtime Request";
            case RESIGNATION -> "Resignation Request";
            case ASSET_REQUEST -> "Asset Request";
            case GENERIC -> "Notification";
        };

        String actionDisplay = switch (action) {
            case SUBMITTED -> "Submitted";
            case APPROVED -> "Approved";
            case REJECTED -> "Rejected";
            case CANCELLED -> "Cancelled";
            case REVOKED -> "Revoked";
        };

        return typeDisplay + " " + actionDisplay;
    }

    private String buildMessage(NotificationType type, NotificationAction action, String actorName, Map<String, Object> metadata) {
        String typeDisplay = switch (type) {
            case LEAVE -> "leave request";
            case OVERTIME -> "overtime request";
            case RESIGNATION -> "resignation request";
            case ASSET_REQUEST -> "asset request";
            case GENERIC -> "request";
        };

        String actor = actorName != null ? actorName : "System";

        return switch (action) {
            case SUBMITTED -> String.format("New %s from %s", typeDisplay, actor);
            case APPROVED -> String.format("Your %s has been approved by %s", typeDisplay, actor);
            case REJECTED -> String.format("Your %s has been rejected by %s", typeDisplay, actor);
            case CANCELLED -> String.format("%s has been cancelled by %s", typeDisplay, actor);
            case REVOKED -> String.format("%s has been revoked by %s", typeDisplay, actor);
        };
    }

    private NotificationDTO toDTO(Notification n) {
        NotificationDTO dto = new NotificationDTO();
        dto.setNotificationId(n.getNotificationId());
        dto.setRecipientId(n.getRecipientId());
        dto.setSenderId(n.getSenderId());
        dto.setRequestType(n.getRequestType());
        dto.setRequestId(n.getRequestId());
        dto.setAction(n.getAction());
        dto.setTitle(n.getTitle());
        dto.setMessage(n.getMessage());
        dto.setPriority(n.getPriority());
        dto.setMetadata(n.getMetadata());
        dto.setIsRead(n.getIsRead());
        dto.setIsSeen(n.getIsSeen());
        dto.setCount(n.getCount());
        dto.setCreatedAt(n.getCreatedAt());
        dto.setUpdatedAt(n.getUpdatedAt());
        return dto;
    }
}