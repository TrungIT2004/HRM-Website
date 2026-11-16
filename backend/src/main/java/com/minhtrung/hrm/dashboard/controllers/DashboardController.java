package com.minhtrung.hrm.dashboard.controllers;

import java.util.UUID;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;
import com.minhtrung.hrm.common.context.RequestContextHolder;
import com.minhtrung.hrm.dashboard.dtos.responses.DashboardSummaryResponse;
import com.minhtrung.hrm.dashboard.services.DashboardService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
@Slf4j
public class DashboardController {

    private final DashboardService dashboardService;

    /**
     * Lấy toàn bộ thông tin tổng quan trang Dashboard cá nhân.
     * Tự động điều chỉnh theo vai trò (Nhân viên, Quản lý phòng ban, HR, Ban Giám Đốc).
     * 
     * GET /api/dashboard/summary
     */
    @GetMapping("/summary")
    public ResponseEntity<DashboardSummaryResponse> getDashboardSummary() {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        UUID userId = currentUser.getUserId();
        log.info("User {} is fetching dashboard summary", userId);

        DashboardSummaryResponse response = dashboardService.getDashboardSummary(userId);
        return ResponseEntity.ok(response);
    }
}
