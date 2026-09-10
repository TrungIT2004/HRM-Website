package com.minhtrung.hrm.employees.controllers;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;
import com.minhtrung.hrm.common.context.RequestContextHolder;
import com.minhtrung.hrm.employees.dtos.requests.CreateDepartmentRequest;
import com.minhtrung.hrm.employees.dtos.responses.DepartmentResponse;
import com.minhtrung.hrm.employees.services.OrganizationService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping("/api/departments")
@RequiredArgsConstructor
@Slf4j
public class DepartmentController {

    private final OrganizationService organizationService;

    /**
     * Lấy toàn bộ danh sách phòng ban kèm cơ cấu chức danh và số lượng nhân sự.
     * GET /api/departments
     */
    @GetMapping
    public ResponseEntity<List<DepartmentResponse>> getAllDepartments() {
        return ResponseEntity.ok(organizationService.getAllDepartments());
    }

    /**
     * Tạo phòng ban mới.
     * Chỉ Trưởng phòng HR hoặc Ban Giám Đốc mới có quyền tạo.
     * POST /api/departments
     */
    @PostMapping
    public ResponseEntity<DepartmentResponse> createDepartment(@Valid @RequestBody CreateDepartmentRequest request) {
        TokenPayload currentUser = RequestContextHolder.get().getTokenPayload();
        log.info("User {} is creating department: {}", currentUser.getUserId(), request.getName());

        DepartmentResponse created = organizationService.createDepartment(request, currentUser);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }
}
