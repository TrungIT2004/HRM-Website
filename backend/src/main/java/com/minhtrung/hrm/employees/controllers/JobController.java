package com.minhtrung.hrm.employees.controllers;

import java.util.List;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;
import com.minhtrung.hrm.common.context.RequestContextHolder;
import com.minhtrung.hrm.employees.dtos.requests.CreateJobRequest;
import com.minhtrung.hrm.employees.dtos.responses.JobResponse;
import com.minhtrung.hrm.employees.services.OrganizationService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping("/api/jobs")
@RequiredArgsConstructor
@Slf4j
public class JobController {

    private final OrganizationService organizationService;

    /**
     * Lấy danh sách chức danh/vị trí công việc (có thể lọc theo phòng ban).
     * GET /api/jobs
     * GET /api/jobs?departmentId=...
     */
    @GetMapping
    public ResponseEntity<List<JobResponse>> getAllJobs(
            @RequestParam(required = false) UUID departmentId
    ) {
        return ResponseEntity.ok(organizationService.getAllJobs(departmentId));
    }

    /**
     * Tạo chức vụ mới thuộc phòng ban.
     * Chỉ Trưởng phòng HR hoặc Ban Giám Đốc mới có quyền tạo.
     * POST /api/jobs
     */
    @PostMapping
    public ResponseEntity<JobResponse> createJob(@Valid @RequestBody CreateJobRequest request) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        log.info("User {} is creating job: {} in department: {}", currentUser.getUserId(), request.getTitle(), request.getDepartmentId());

        JobResponse created = organizationService.createJob(request, currentUser);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }
}
