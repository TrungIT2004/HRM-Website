package com.minhtrung.hrm.performance.controllers;

import java.util.List;
import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;
import com.minhtrung.hrm.common.context.RequestContextHolder;
import com.minhtrung.hrm.employees.dtos.internals.UserRole;
import com.minhtrung.hrm.performance.dtos.requests.ManagerScoreRequest;
import com.minhtrung.hrm.performance.dtos.requests.PerformanceFilterRequest;
import com.minhtrung.hrm.performance.dtos.requests.SelfSubmitRequest;
import com.minhtrung.hrm.performance.dtos.responses.PerformanceOverviewResponse;
import com.minhtrung.hrm.performance.dtos.responses.PerformanceReviewResponse;
import com.minhtrung.hrm.performance.services.PerformanceService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/performance-reviews")
@RequiredArgsConstructor
public class PerformanceController {

    private final PerformanceService performanceService;

    private UserRole getCurrentUserRole() {
        TokenPayload payload = RequestContextHolder.get().getTokenPayload();
        return new UserRole(payload.getUserId(), payload.getDepartment(), payload.getJob());
    }

    /**
     * 0. Mo bai thang/nam hien tai (lazy-create DRAFT neu chua co)
     * GET /api/performance-reviews/current?periodType=MONTHLY&year=&month=
     */
    @GetMapping("/current")
    public ResponseEntity<PerformanceReviewResponse> getOrCreate(
            @RequestParam(required = false) String periodType,
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) Integer month) {
        return ResponseEntity.ok(performanceService.getOrCreate(getCurrentUserRole(), periodType, year, month));
    }

    /**
     * 1. Nhan vien nop tu danh gia
     * POST /api/performance-reviews/{reviewId}/self
     */
    @PostMapping("/{reviewId}/self")
    public ResponseEntity<PerformanceReviewResponse> submitSelf(
            @PathVariable UUID reviewId,
            @Valid @RequestBody SelfSubmitRequest request) {
        TokenPayload payload = RequestContextHolder.get().getTokenPayload();
        return ResponseEntity.ok(performanceService.submitSelf(payload.getUserId(), reviewId, request));
    }

    /**
     * 2. Manager cham diem chinh thuc
     * PATCH /api/performance-reviews/{reviewId}/manager
     */
    @PatchMapping("/{reviewId}/manager")
    public ResponseEntity<PerformanceReviewResponse> scoreManager(
            @PathVariable UUID reviewId,
            @Valid @RequestBody ManagerScoreRequest request) {
        return ResponseEntity.ok(performanceService.scoreManager(reviewId, request, getCurrentUserRole()));
    }

    /**
     * 3. HR khoa so
     * PATCH /api/performance-reviews/{reviewId}/lock
     */
    @PatchMapping("/{reviewId}/lock")
    public ResponseEntity<PerformanceReviewResponse> lock(@PathVariable UUID reviewId) {
        return ResponseEntity.ok(performanceService.lock(reviewId, getCurrentUserRole()));
    }

    /**
     * 3b. HR khoa so hang loat (tick N dong tren bang records)
     * POST /api/performance-reviews/lock-batch {reviewIds: [...]}
     */
    @PostMapping("/lock-batch")
    public ResponseEntity<java.util.Map<String, Object>> lockBatch(
            @RequestBody java.util.Map<String, List<UUID>> body) {
        List<UUID> ids = body != null ? body.get("reviewIds") : null;
        return ResponseEntity.ok(performanceService.lockBatch(ids, getCurrentUserRole()));
    }

    /**
     * 3c. Xuat Excel cac bai dang tick (sheet Tong hop + 1 sheet/bai)
     * GET /api/performance-reviews/export?reviewIds=..&reviewIds=..
     */
    @GetMapping("/export")
    public ResponseEntity<byte[]> export(@RequestParam List<UUID> reviewIds) {
        byte[] data = performanceService.exportReviewsToExcel(reviewIds, getCurrentUserRole());
        return ResponseEntity.ok()
                .header("Content-Disposition", "attachment; filename=\"danh_gia.xlsx\"")
                .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .body(data);
    }

    /**
     * 4. Lich su cua toi
     * GET /api/performance-reviews/my-records
     */
    @GetMapping("/my-records")
    public ResponseEntity<Page<PerformanceReviewResponse>> getMyReviews(
            @ModelAttribute PerformanceFilterRequest filter,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        TokenPayload payload = RequestContextHolder.get().getTokenPayload();
        return ResponseEntity.ok(performanceService.getMyReviews(payload.getUserId(), filter, pageable));
    }

    /**
     * 5. Bai can cham (manager theo phan cap / grant)
     * GET /api/performance-reviews/approvals
     */
    @GetMapping("/approvals")
    public ResponseEntity<Page<PerformanceReviewResponse>> getApprovals(
            @ModelAttribute PerformanceFilterRequest filter,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        return ResponseEntity.ok(performanceService.getApprovals(getCurrentUserRole(), filter, pageable));
    }

    /**
     * 6. Toan cong ty (HR / Ban Giam Doc)
     * GET /api/performance-reviews/company
     */
    @GetMapping("/company")
    public ResponseEntity<Page<PerformanceReviewResponse>> getCompanyRecords(
            @ModelAttribute PerformanceFilterRequest filter,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        return ResponseEntity.ok(performanceService.getCompanyRecords(getCurrentUserRole(), filter, pageable));
    }

    /**
     * 7. Dashboard tong quan (bieu do + tuyen duong)
     * GET /api/performance-reviews/overview?year=&month=&scope=dept|company
     */
    @GetMapping("/overview")
    public ResponseEntity<PerformanceOverviewResponse> getOverview(
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) Integer month,
            @RequestParam(required = false, defaultValue = "dept") String scope) {
        return ResponseEntity.ok(performanceService.getOverview(getCurrentUserRole(), year, month, scope));
    }

}
