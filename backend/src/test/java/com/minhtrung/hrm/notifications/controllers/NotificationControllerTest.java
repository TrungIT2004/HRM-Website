package com.minhtrung.hrm.notifications.controllers;

import java.util.Map;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;
import com.minhtrung.hrm.auth.services.JwtService;
import com.minhtrung.hrm.common.context.RequestContext;
import com.minhtrung.hrm.common.context.RequestContextHolder;
import com.minhtrung.hrm.notifications.dtos.responses.NotificationResponse;
import com.minhtrung.hrm.notifications.entities.Notification;
import com.minhtrung.hrm.notifications.entities.NotificationPriority;
import com.minhtrung.hrm.notifications.entities.NotificationType;
import com.minhtrung.hrm.notifications.services.NotificationService;

import org.mockito.Mockito;

@WebMvcTest(NotificationController.class)
@AutoConfigureMockMvc(addFilters = false)
@org.springframework.context.annotation.Import({NotificationController.class, com.minhtrung.hrm.HrmApplication.class})
class NotificationControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private NotificationService notificationService;

    private TokenPayload testTokenPayload;
    private UUID testUserId;

    @BeforeEach
    void setUp() {
        testUserId = UUID.randomUUID();
        testTokenPayload = TokenPayload.builder()
                .userId(testUserId)
                .email("test@example.com")
                .fullName("Test User")
                .department("Engineering")
                .job("Developer")
                .build();

        // Mock the RequestContextHolder to return our test token
        RequestContext context = RequestContext.builder()
                .tokenPayload(testTokenPayload)
                .build();
        RequestContextHolder.set(context);

        // Reset mock before each test
        Mockito.reset(notificationService);
    }

    @Test
    void getNotifications_returnsPagedNotifications() throws Exception {
        Notification notification = Notification.builder()
                .notificationId(UUID.randomUUID())
                .type(NotificationType.LEAVE)
                .title("Leave Request")
                .body("Your leave request was approved")
                .referenceId(UUID.randomUUID())
                .referenceType("LEAVE_REQUEST")
                .priority(NotificationPriority.NORMAL)
                .readAt(null)
                .build();

        Page<Notification> page = new PageImpl<>(java.util.List.of(notification), PageRequest.of(0, 10), 1);
        when(notificationService.getForUser(eq(testUserId), any(), any(), any()))
                .thenReturn(page);

        mockMvc.perform(get("/api/notifications")
                        .param("page", "0")
                        .param("size", "10")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content[0].type").value("LEAVE"))
                .andExpect(jsonPath("$.content[0].title").value("Leave Request"))
                .andExpect(jsonPath("$.totalElements").value(1));
    }

    @Test
    void getUnreadCount_returnsCount() throws Exception {
        when(notificationService.getUnreadCount(testUserId)).thenReturn(5L);

        mockMvc.perform(get("/api/notifications/unread-count")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.count").value(5));
    }

    @Test
    void markRead_callsServiceAndReturnsNoContent() throws Exception {
        UUID notificationId = UUID.randomUUID();
        doNothing().when(notificationService).markRead(testUserId, notificationId);

        mockMvc.perform(patch("/api/notifications/{id}/read", notificationId)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNoContent());

        verify(notificationService).markRead(testUserId, notificationId);
    }

    @Test
    void markAllRead_callsServiceAndReturnsNoContent() throws Exception {
        doNothing().when(notificationService).markAllRead(testUserId);

        mockMvc.perform(patch("/api/notifications/read-all")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNoContent());

        verify(notificationService).markAllRead(testUserId);
    }

    @Configuration
    static class TestConfig {
        @Bean
        @Primary
        NotificationService notificationService() {
            return Mockito.mock(NotificationService.class);
        }

        @Bean
        @Primary
        JwtService jwtService() {
            return Mockito.mock(JwtService.class);
        }
    }
}