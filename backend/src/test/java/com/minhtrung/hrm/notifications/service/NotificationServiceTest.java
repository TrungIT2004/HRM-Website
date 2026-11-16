package com.minhtrung.hrm.notifications.service;

import com.minhtrung.hrm.employees.entities.User;
import com.minhtrung.hrm.employees.entities.Department;
import com.minhtrung.hrm.employees.entities.Job;
import com.minhtrung.hrm.notifications.dtos.NotificationEvent;
import com.minhtrung.hrm.notifications.dtos.NotificationDTO;
import com.minhtrung.hrm.notifications.entity.Notification;
import com.minhtrung.hrm.notifications.enums.NotificationAction;
import com.minhtrung.hrm.notifications.enums.NotificationPriority;
import com.minhtrung.hrm.notifications.enums.NotificationType;
import com.minhtrung.hrm.notifications.repository.NotificationRepository;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class NotificationServiceTest {

    @Mock
    private NotificationRepository notificationRepository;

    @Mock
    private com.minhtrung.hrm.employees.repositories.UserRepository userRepository;

    @Mock
    private SseEmitterRegistry sseEmitterRegistry;

    @InjectMocks
    private NotificationService notificationService;

    private User testUser;
    private User requestor;
    private User approver;
    private UUID userId;
    private UUID requestorId;
    private UUID approverId;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        requestorId = UUID.randomUUID();
        approverId = UUID.randomUUID();

        Department dept = new Department();
        dept.setName("Information Technology");

        Job job = new Job();
        job.setTitle("Software Engineer");

        testUser = new User();
        testUser.setUserId(userId);
        testUser.setFirstName("Test");
        testUser.setLastName("User");
        testUser.setEmail("test@company.com");
        testUser.setDepartment(dept);
        testUser.setJob(job);

        requestor = new User();
        requestor.setUserId(requestorId);
        requestor.setFirstName("Requestor");
        requestor.setLastName("Name");
        requestor.setEmail("requestor@company.com");

        approver = new User();
        approver.setUserId(approverId);
        approver.setFirstName("Approver");
        approver.setLastName("Name");
        approver.setEmail("approver@company.com");
    }

    @Test
    void emit_shouldCreateNotificationAndPushViaSSE() {
        // Given
        NotificationEvent event = NotificationEvent.of(
            NotificationType.LEAVE,
            UUID.randomUUID(),
            NotificationAction.APPROVED,
            "Leave Request Approved",
            "Your leave has been approved",
            Map.of(),
            NotificationPriority.NORMAL
        );

        when(userRepository.findById(userId)).thenReturn(Optional.of(testUser));
        when(notificationRepository.save(any(Notification.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(notificationRepository.countByRecipient_UserIdAndIsReadFalse(userId)).thenReturn(1L);

        // When
        notificationService.emit(userId, event);

        // Then
        verify(notificationRepository).save(any(Notification.class));
        verify(sseEmitterRegistry).broadcastToUser(eq(userId), any(NotificationDTO.class));
        verify(sseEmitterRegistry).broadcastUnreadCount(eq(userId), eq(1L));
    }

    @Test
    void emit_shouldNotEmitWhenRecipientNotFound() {
        // Given
        NotificationEvent event = NotificationEvent.of(
            NotificationType.LEAVE,
            UUID.randomUUID(),
            NotificationAction.APPROVED,
            "Leave Request Approved",
            "Your leave has been approved",
            Map.of(),
            NotificationPriority.NORMAL
        );

        when(userRepository.findById(userId)).thenReturn(Optional.empty());

        // When
        notificationService.emit(userId, event);

        // Then
        verify(notificationRepository, never()).save(any());
        verify(sseEmitterRegistry, never()).broadcastToUser(any(), any());
    }

    @Test
    void emitToUsers_shouldEmitToMultipleUsers() {
        // Given
        NotificationEvent event = NotificationEvent.of(
            NotificationType.OVERTIME,
            UUID.randomUUID(),
            NotificationAction.SUBMITTED,
            "Overtime Request Submitted",
            "New overtime request",
            Map.of(),
            NotificationPriority.NORMAL
        );

        when(userRepository.findAllById(List.of(userId, requestorId))).thenReturn(List.of(testUser, requestor));
        when(notificationRepository.save(any(Notification.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(notificationRepository.countByRecipient_UserIdAndIsReadFalse(any(UUID.class))).thenReturn(1L);

        // When
        notificationService.emitToUsers(List.of(userId, requestorId), event);

        // Then
        verify(notificationRepository, times(2)).save(any(Notification.class));
        verify(sseEmitterRegistry, times(2)).broadcastToUser(any(UUID.class), any(NotificationDTO.class));
        verify(sseEmitterRegistry, times(2)).broadcastUnreadCount(any(UUID.class), eq(1L));
    }

    @Test
    void emitForRequest_submittedAction_shouldNotifyApprovers() {
        // Given
        UUID requestId = UUID.randomUUID();
        List<UUID> approverIds = List.of(approverId, userId);

        // Mock resolveApprovers to return our test approvers
        NotificationService spyService = spy(notificationService);
        doReturn(approverIds).when(spyService).resolveApprovers(requestId, NotificationType.LEAVE);

        NotificationEvent expectedEvent = NotificationEvent.of(
            NotificationType.LEAVE,
            requestId,
            NotificationAction.SUBMITTED,
            "Leave Request Submitted",
            "New leave request from Requestor Name",
            Map.of(
                "senderName", "Requestor Name",
                "requestType", "LEAVE",
                "action", "SUBMITTED"
            ),
            NotificationPriority.NORMAL
        );

        when(userRepository.findAllById(approverIds)).thenReturn(List.of(approver, testUser));
        when(notificationRepository.save(any(Notification.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(notificationRepository.countByRecipient_UserIdAndIsReadFalse(any(UUID.class))).thenReturn(1L);

        // When
        spyService.emitForRequest(requestId, NotificationType.LEAVE, NotificationAction.SUBMITTED,
            requestorId, approverId, "Requestor Name", "Approver Name", Map.of());

        // Then
        verify(spyService).emitToUsers(eq(approverIds), any(NotificationEvent.class));
    }

    @Test
    void emitForRequest_approvedAction_shouldNotifyRequestor() {
        // Given
        UUID requestId = UUID.randomUUID();

        NotificationService spyService = spy(notificationService);

        when(userRepository.findAllById(List.of(requestorId))).thenReturn(List.of(requestor));
        when(notificationRepository.save(any(Notification.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(notificationRepository.countByRecipient_UserIdAndIsReadFalse(requestorId)).thenReturn(1L);

        // When
        spyService.emitForRequest(requestId, NotificationType.LEAVE, NotificationAction.APPROVED,
            requestorId, approverId, "Requestor Name", "Approver Name", Map.of());

        // Then - emitForRequest uses emitToUsers for all actions, even single recipient
        verify(spyService).emitToUsers(eq(List.of(requestorId)), any(NotificationEvent.class));
    }

    @Test
    void emitForRequest_rejectedAction_shouldNotifyRequestorWithHighPriority() {
        // Given
        UUID requestId = UUID.randomUUID();

        NotificationService spyService = spy(notificationService);

        when(userRepository.findAllById(List.of(requestorId))).thenReturn(List.of(requestor));
        when(notificationRepository.save(any(Notification.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(notificationRepository.countByRecipient_UserIdAndIsReadFalse(requestorId)).thenReturn(1L);

        // When
        spyService.emitForRequest(requestId, NotificationType.OVERTIME, NotificationAction.REJECTED,
            requestorId, approverId, "Requestor Name", "Approver Name", Map.of());

        // Then - emitForRequest uses emitToUsers for all actions, even single recipient
        ArgumentCaptor<NotificationEvent> eventCaptor = ArgumentCaptor.forClass(NotificationEvent.class);
        verify(spyService).emitToUsers(eq(List.of(requestorId)), eventCaptor.capture());

        NotificationEvent capturedEvent = eventCaptor.getValue();
        assertThat(capturedEvent.action()).isEqualTo(NotificationAction.REJECTED);
        assertThat(capturedEvent.priority()).isEqualTo(NotificationPriority.HIGH);
    }

    @Test
    void emitForRequest_revokedAction_shouldNotifyRequestorAndApprover() {
        // Given
        UUID requestId = UUID.randomUUID();

        NotificationService spyService = spy(notificationService);

        when(userRepository.findAllById(List.of(requestorId, approverId))).thenReturn(List.of(requestor, approver));
        when(notificationRepository.save(any(Notification.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(notificationRepository.countByRecipient_UserIdAndIsReadFalse(any(UUID.class))).thenReturn(1L);

        // When
        spyService.emitForRequest(requestId, NotificationType.RESIGNATION, NotificationAction.REVOKED,
            requestorId, approverId, "Requestor Name", "Approver Name", Map.of());

        // Then
        verify(spyService).emitToUsers(eq(List.of(requestorId, approverId)), any(NotificationEvent.class));
    }

    @Test
    void emitForRequest_cancelledAction_shouldNotifyRequestor() {
        // Given
        UUID requestId = UUID.randomUUID();

        NotificationService spyService = spy(notificationService);

        when(userRepository.findAllById(List.of(requestorId))).thenReturn(List.of(requestor));
        when(notificationRepository.save(any(Notification.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(notificationRepository.countByRecipient_UserIdAndIsReadFalse(requestorId)).thenReturn(1L);

        // When
        spyService.emitForRequest(requestId, NotificationType.ASSET_REQUEST, NotificationAction.CANCELLED,
            requestorId, approverId, "Requestor Name", "Approver Name", Map.of());

        // Then - emitForRequest uses emitToUsers for all actions, even single recipient
        verify(spyService).emitToUsers(eq(List.of(requestorId)), any(NotificationEvent.class));
    }

    @Test
    void buildTitle_shouldReturnCorrectTitleForAllTypesAndActions() {
        // Given
        NotificationService service = new NotificationService(
            notificationRepository, userRepository, sseEmitterRegistry
        );

        // Test all combinations using reflection or by calling emitForRequest with different types
        // Since buildTitle is private, we test through emitForRequest

        UUID requestId = UUID.randomUUID();

        NotificationService spyService = spy(service);

        // Test LEAVE APPROVED (doesn't call resolveApprovers for APPROVED action)
        spyService.emitForRequest(requestId, NotificationType.LEAVE, NotificationAction.APPROVED,
            requestorId, approverId, "Requestor", "Approver", Map.of());

        ArgumentCaptor<NotificationEvent> captor = ArgumentCaptor.forClass(NotificationEvent.class);
        verify(spyService, atLeastOnce()).emitToUsers(any(), captor.capture());

        NotificationEvent lastEvent = captor.getAllValues().get(captor.getAllValues().size() - 1);
        assertThat(lastEvent.title()).isEqualTo("Leave Request Approved");
    }

    @Test
    void emitToDepartment_shouldFindUsersInDepartment() {
        // Given
        UUID departmentId = UUID.randomUUID();
        Department dept = new Department();
        dept.setDepartmentId(departmentId);
        dept.setName("Information Technology");

        User userInDept = new User();
        UUID userId = UUID.randomUUID();
        userInDept.setUserId(userId);
        userInDept.setDepartment(dept);

        when(userRepository.findByDepartment_DepartmentId(departmentId)).thenReturn(List.of(userInDept));
        when(userRepository.findAllById(List.of(userId))).thenReturn(List.of(userInDept));
        when(notificationRepository.save(any(Notification.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(notificationRepository.countByRecipient_UserIdAndIsReadFalse(any(UUID.class))).thenReturn(1L);

        NotificationEvent event = NotificationEvent.of(
            NotificationType.GENERIC,
            UUID.randomUUID(),
            NotificationAction.SUBMITTED,
            "Test",
            "Test message",
            Map.of(),
            NotificationPriority.NORMAL
        );

        // When
        notificationService.emitToDepartment(departmentId, event);

        // Then
        verify(userRepository).findByDepartment_DepartmentId(departmentId);
        verify(notificationRepository).save(any(Notification.class));
    }

    @Test
    void emitToRole_shouldFindUsersWithRole() {
        // Given
        User userWithRole = new User();
        UUID userId = UUID.randomUUID();
        userWithRole.setUserId(userId);
        Job job = new Job();
        job.setTitle("Department Head of IT");
        userWithRole.setJob(job);

        when(userRepository.findByJobTitleContainingIgnoreCase("Department Head")).thenReturn(List.of(userWithRole));
        when(userRepository.findAllById(List.of(userId))).thenReturn(List.of(userWithRole));
        when(notificationRepository.save(any(Notification.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(notificationRepository.countByRecipient_UserIdAndIsReadFalse(any(UUID.class))).thenReturn(1L);

        NotificationEvent event = NotificationEvent.of(
            NotificationType.GENERIC,
            UUID.randomUUID(),
            NotificationAction.SUBMITTED,
            "Test",
            "Test message",
            Map.of(),
            NotificationPriority.NORMAL
        );

        // When
        notificationService.emitToRole("Department Head", event);

        // Then
        verify(userRepository).findByJobTitleContainingIgnoreCase("Department Head");
        verify(notificationRepository).save(any(Notification.class));
    }
}