package com.minhtrung.hrm.employees.services;

import java.util.List;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

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
import com.minhtrung.hrm.permissions.enums.PermissionKey;
import com.minhtrung.hrm.permissions.services.PermissionService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class OrganizationService {

    private final DepartmentRepository departmentRepository;
    private final JobRepository jobRepository;
    private final UserRepository userRepository;
    private final PermissionService permissionService;

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

    // ─── Cập nhật / Xoá phòng ban & chức danh ─────────────────────────

    @Transactional
    public DepartmentResponse updateDepartment(UUID departmentId, CreateDepartmentRequest request, TokenPayload currentUser) {
        checkOrganizationPermission(currentUser);

        Department department = departmentRepository.findById(departmentId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy phòng ban với ID: " + departmentId));

        String trimmedName = request.getName().trim();
        if (!trimmedName.equalsIgnoreCase(department.getName()) && departmentRepository.existsByName(trimmedName)) {
            throw new IllegalArgumentException("Phòng ban có tên '" + trimmedName + "' đã tồn tại trong hệ thống!");
        }
        department.setName(trimmedName);
        departmentRepository.save(department);

        log.info("User {} renamed department {} -> {}", currentUser.getUserId(), departmentId, trimmedName);

        List<Job> jobs = jobRepository.findByDepartment_DepartmentId(departmentId);
        return DepartmentResponse.builder()
                .departmentId(department.getDepartmentId())
                .name(department.getName())
                .totalEmployees(userRepository.countByDepartment_DepartmentId(departmentId))
                .jobs(jobs.stream().map(j -> DepartmentResponse.JobItemDto.builder()
                        .jobId(j.getJobId())
                        .title(j.getTitle())
                        .build()).toList())
                .build();
    }

    @Transactional
    public void deleteDepartment(UUID departmentId, TokenPayload currentUser) {
        checkOrganizationPermission(currentUser);

        Department department = departmentRepository.findById(departmentId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy phòng ban với ID: " + departmentId));

        // Department.jobs và Department.users đều @OneToMany(cascade = ALL) — xoá hàng loạt sẽ
        // cascade xoá luôn nhân viên. Vì vậy phải chặn TRƯỚC khi gọi delete.
        int jobs = jobRepository.countByDepartment_DepartmentId(departmentId);
        int employees = userRepository.countByDepartment_DepartmentId(departmentId);
        if (employees > 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Không thể xoá phòng ban '" + department.getName() + "': còn " + employees + " nhân viên đang thuộc phòng ban này.");
        }
        if (jobs > 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Không thể xoá phòng ban '" + department.getName() + "': còn " + jobs + " chức danh. Hãy xoá hoặc chuyển các chức danh trước.");
        }
        // clear collection để tránh cascade xoá (cascade = ALL kể cả REMOVE)
        department.getJobs().clear();
        departmentRepository.delete(department);

        log.info("User {} deleted department {}", currentUser.getUserId(), departmentId);
    }

    @Transactional
    public JobResponse updateJob(UUID jobId, CreateJobRequest request, TokenPayload currentUser) {
        checkOrganizationPermission(currentUser);

        Job job = jobRepository.findById(jobId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy chức danh với ID: " + jobId));
        Department department = departmentRepository.findById(request.getDepartmentId())
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy phòng ban với ID: " + request.getDepartmentId()));

        String trimmedTitle = request.getTitle().trim();
        boolean titleChanged = !trimmedTitle.equalsIgnoreCase(job.getTitle());
        boolean deptChanged = !department.getDepartmentId().equals(job.getDepartment().getDepartmentId());
        if ((titleChanged || deptChanged)
                && jobRepository.existsByTitleAndDepartment_DepartmentId(trimmedTitle, department.getDepartmentId())) {
            throw new IllegalArgumentException("Chức danh '" + trimmedTitle + "' đã tồn tại trong phòng ban " + department.getName() + "!");
        }

        job.setTitle(trimmedTitle);
        job.setDepartment(department);
        jobRepository.save(job);

        log.info("User {} updated job {}", currentUser.getUserId(), jobId);

        return JobResponse.builder()
                .jobId(job.getJobId())
                .title(job.getTitle())
                .departmentId(department.getDepartmentId())
                .departmentName(department.getName())
                .build();
    }

    @Transactional
    public void deleteJob(UUID jobId, TokenPayload currentUser) {
        checkOrganizationPermission(currentUser);

        Job job = jobRepository.findById(jobId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy chức danh với ID: " + jobId));

        int employees = userRepository.countByJob_JobId(jobId);
        if (employees > 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Không thể xoá chức danh '" + job.getTitle() + "': còn " + employees + " nhân viên đang giữ chức danh này.");
        }
        jobRepository.delete(job);

        log.info("User {} deleted job {}", currentUser.getUserId(), jobId);
    }

    /**
     * Quyền quản lý cơ cấu tổ chức (tạo/sửa/xoá phòng ban & chức danh).
     * Quyền gốc: phòng Human Resources (cả phòng, không chỉ HR Head — người dùng đã chốt).
     * Ủy quyền thêm qua grant ORG_MANAGE. Ban Giám Đốc đã bị gỡ khỏi danh sách này.
     * Đọc (GET) không chặn ai — master data không nhạy cảm.
     */
    private void checkOrganizationPermission(TokenPayload currentUser) {
        if (currentUser == null) {
            throw new AccessDeniedException("Yêu cầu đăng nhập trước khi thực hiện thao tác!");
        }

        boolean isHR = "Human Resources".equalsIgnoreCase(currentUser.getDepartment());
        boolean hasGrant = permissionService.hasPermission(currentUser.getUserId(), PermissionKey.ORG_MANAGE);

        if (!isHR && !hasGrant) {
            throw new AccessDeniedException("Chỉ có phòng Nhân sự (Human Resources) mới có quyền quản lý phòng ban, chức danh và ca làm việc!");
        }
    }
}
