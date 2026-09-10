package com.minhtrung.hrm.employees.services;

import java.util.List;
import java.util.UUID;

import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;
import com.minhtrung.hrm.employees.dtos.requests.CreateDepartmentRequest;
import com.minhtrung.hrm.employees.dtos.requests.CreateJobRequest;
import com.minhtrung.hrm.employees.dtos.responses.DepartmentResponse;
import com.minhtrung.hrm.employees.dtos.responses.JobResponse;
import com.minhtrung.hrm.employees.entities.Department;
import com.minhtrung.hrm.employees.entities.Job;
import com.minhtrung.hrm.employees.repositories.DepartmentRepository;
import com.minhtrung.hrm.employees.repositories.JobRepository;
import com.minhtrung.hrm.employees.repositories.UserRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class OrganizationService {

    private final DepartmentRepository departmentRepository;
    private final JobRepository jobRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public List<DepartmentResponse> getAllDepartments() {
        List<Department> departments = departmentRepository.findAll();
        return departments.stream().map(d -> {
            List<Job> jobs = jobRepository.findByDepartment_DepartmentId(d.getDepartmentId());
            int totalEmployees = userRepository.countByDepartment_DepartmentId(d.getDepartmentId());

            List<DepartmentResponse.JobItemDto> jobDtos = jobs.stream()
                    .map(j -> DepartmentResponse.JobItemDto.builder()
                            .jobId(j.getJobId())
                            .title(j.getTitle())
                            .build())
                    .toList();

            return DepartmentResponse.builder()
                    .departmentId(d.getDepartmentId())
                    .name(d.getName())
                    .totalEmployees(totalEmployees)
                    .jobs(jobDtos)
                    .build();
        }).toList();
    }

    @Transactional
    public DepartmentResponse createDepartment(CreateDepartmentRequest request, TokenPayload currentUser) {
        checkOrganizationPermission(currentUser);

        String trimmedName = request.getName().trim();
        if (departmentRepository.existsByName(trimmedName)) {
            throw new IllegalArgumentException("Phòng ban có tên '" + trimmedName + "' đã tồn tại trong hệ thống!");
        }

        Department department = new Department();
        department.setName(trimmedName);
        Department saved = departmentRepository.save(department);

        log.info("User {} created new department: {}", currentUser.getUserId(), saved.getName());

        return DepartmentResponse.builder()
                .departmentId(saved.getDepartmentId())
                .name(saved.getName())
                .totalEmployees(0)
                .jobs(List.of())
                .build();
    }

    @Transactional(readOnly = true)
    public List<JobResponse> getAllJobs(UUID departmentId) {
        List<Job> jobs;
        if (departmentId != null) {
            jobs = jobRepository.findByDepartment_DepartmentId(departmentId);
        } else {
            jobs = jobRepository.findAll();
        }

        return jobs.stream().map(j -> JobResponse.builder()
                .jobId(j.getJobId())
                .title(j.getTitle())
                .departmentId(j.getDepartment() != null ? j.getDepartment().getDepartmentId() : null)
                .departmentName(j.getDepartment() != null ? j.getDepartment().getName() : null)
                .build()
        ).toList();
    }

    @Transactional
    public JobResponse createJob(CreateJobRequest request, TokenPayload currentUser) {
        checkOrganizationPermission(currentUser);

        Department department = departmentRepository.findById(request.getDepartmentId())
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy phòng ban với ID: " + request.getDepartmentId()));

        String trimmedTitle = request.getTitle().trim();
        if (jobRepository.existsByTitleAndDepartment_DepartmentId(trimmedTitle, department.getDepartmentId())) {
            throw new IllegalArgumentException("Chức danh '" + trimmedTitle + "' đã tồn tại trong phòng ban " + department.getName() + "!");
        }

        Job job = new Job();
        job.setTitle(trimmedTitle);
        job.setDepartment(department);
        Job saved = jobRepository.save(job);

        log.info("User {} created new job: {} in department: {}", currentUser.getUserId(), saved.getTitle(), department.getName());

        return JobResponse.builder()
                .jobId(saved.getJobId())
                .title(saved.getTitle())
                .departmentId(department.getDepartmentId())
                .departmentName(department.getName())
                .build();
    }

    private void checkOrganizationPermission(TokenPayload currentUser) {
        if (currentUser == null) {
            throw new AccessDeniedException("Yêu cầu đăng nhập trước khi thực hiện thao tác!");
        }

        boolean isExecutive = "Executive Leadership".equalsIgnoreCase(currentUser.getDepartment());
        boolean isHRHead = "Human Resources".equalsIgnoreCase(currentUser.getDepartment())
                && currentUser.getJob() != null
                && currentUser.getJob().contains("Head");

        if (!isExecutive && !isHRHead) {
            throw new AccessDeniedException("Chỉ có Trưởng phòng Nhân sự (HR Head) hoặc Ban Giám Đốc mới có quyền tạo mới phòng ban hoặc chức vụ!");
        }
    }
}
