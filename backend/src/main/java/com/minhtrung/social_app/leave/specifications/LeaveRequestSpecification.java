package com.minhtrung.social_app.leave.specifications;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.domain.Specification;

import com.minhtrung.social_app.employees.dtos.internals.UserRole;
import com.minhtrung.social_app.employees.entities.Department;
import com.minhtrung.social_app.employees.entities.Job;
import com.minhtrung.social_app.employees.entities.User;
import com.minhtrung.social_app.leave.dtos.requests.LeaveFilterRequest;
import com.minhtrung.social_app.leave.entities.LeaveRequest;

import jakarta.persistence.criteria.CriteriaBuilder;
import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.JoinType;
import jakarta.persistence.criteria.Predicate;
import jakarta.persistence.criteria.Root;

public class LeaveRequestSpecification {

    // 1. Bộ lọc chung: Status và Khoảng thời gian (Áp dụng cho mọi route)
    private static void applyDateAndStatusFilters(List<Predicate> predicates, Root<LeaveRequest> root,
                                                 CriteriaBuilder cb, LeaveFilterRequest filter) {
        if (filter.getStatus() != null) {
            predicates.add(cb.equal(root.get("status"), filter.getStatus()));
        }
        if (filter.getFromDate() != null) {
            predicates.add(cb.greaterThanOrEqualTo(root.get("toDate"), filter.getFromDate()));
        }
        if (filter.getToDate() != null) {
            predicates.add(cb.lessThanOrEqualTo(root.get("fromDate"), filter.getToDate()));
        }
    }

    // =========================================================================
    // 1. ROUTE CÁ NHÂN: GET /api/leave/my-requests
    // =========================================================================
    public static Specification<LeaveRequest> forMyRequests(UUID currentUserId, LeaveFilterRequest filter) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            Join<LeaveRequest, User> requestorJoin = root.join("requestor", JoinType.INNER);

            // Bắt buộc là chính mình
            predicates.add(cb.equal(requestorJoin.get("userId"), currentUserId));

            // Lọc ngày & trạng thái
            applyDateAndStatusFilters(predicates, root, cb, filter);

            // Với cá nhân: Keyword dùng để tìm kiếm theo "Lý do xin nghỉ" (reason)
            if (filter.getKeyword() != null && !filter.getKeyword().isBlank()) {
                String searchPattern = "%" + filter.getKeyword().trim().toLowerCase() + "%";
                predicates.add(cb.like(cb.lower(root.get("reason")), searchPattern));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }

    // =========================================================================
    // 2. ROUTE DUYỆT ĐƠN: GET /api/leave/approvals
    // =========================================================================
    public static Specification<LeaveRequest> forApprovals(UserRole userRole, LeaveFilterRequest filter) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            Join<LeaveRequest, User> requestorJoin = root.join("requestor", JoinType.INNER);
            Join<User, Department> deptJoin = requestorJoin.join("department", JoinType.LEFT);
            Join<User, Job> jobJoin = requestorJoin.join("job", JoinType.LEFT);

            UUID currentUserId = userRole.getUserId();
            String myDepartment = userRole.getDepartment() != null ? userRole.getDepartment() : "";
            String myJob = userRole.getJob() != null ? userRole.getJob() : "";

            // Không tự duyệt chính mình
            predicates.add(cb.notEqual(requestorJoin.get("userId"), currentUserId));

            boolean isExecutive = myDepartment.equals("Executive Leadership");
            boolean isDepartmentHead = myJob.startsWith("Department Head");

            if (isExecutive && myJob.contains("Chairman")) {
                Predicate isExecDept = cb.equal(deptJoin.get("name"), "Executive Leadership");
                Predicate isDirectors = cb.or(
                    cb.like(jobJoin.get("title"), "%Director%"),
                    cb.like(jobJoin.get("title"), "%Deputy%")
                );
                predicates.add(cb.and(isExecDept, isDirectors));
            } 
            else if (isExecutive && myJob.contains("Director") && !myJob.contains("Deputy") && !myJob.contains("Vice")) {
                Predicate isViceDirector = cb.and(
                    cb.equal(deptJoin.get("name"), "Executive Leadership"),
                    cb.or(cb.like(jobJoin.get("title"), "%Deputy%"), cb.like(jobJoin.get("title"), "%Vice%"))
                );
                Predicate isDepartmentHeads = cb.like(jobJoin.get("title"), "Department Head%");
                predicates.add(cb.or(isViceDirector, isDepartmentHeads));
            } 
            else if (isExecutive && (myJob.contains("Deputy") || myJob.contains("Vice"))) {
                predicates.add(cb.like(jobJoin.get("title"), "Department Head%"));
            } 
            else if (isDepartmentHead) {
                Predicate sameDept = cb.equal(deptJoin.get("name"), myDepartment);
                Predicate notAnotherHead = cb.notLike(jobJoin.get("title"), "Department Head%");
                predicates.add(cb.and(sameDept, notAnotherHead));
            } 
            else {
                predicates.add(cb.disjunction());
            }

            // Lọc ngày & trạng thái
            applyDateAndStatusFilters(predicates, root, cb, filter);

            // Với quản lý: Keyword tìm theo Tên, Mã nhân viên hoặc Lý do
            applyManagerKeywordSearch(predicates, root, requestorJoin, cb, filter);

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }

    // =========================================================================
    // 3. ROUTE TOÀN CÔNG TY: GET /api/leave/company
    // =========================================================================
    public static Specification<LeaveRequest> forCompanyWide(LeaveFilterRequest filter) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            Join<LeaveRequest, User> requestorJoin = root.join("requestor", JoinType.INNER);

            // Lọc ngày & trạng thái
            applyDateAndStatusFilters(predicates, root, cb, filter);

            // Với HR: Keyword tìm theo Tên, Mã nhân viên hoặc Lý do
            applyManagerKeywordSearch(predicates, root, requestorJoin, cb, filter);

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }

    // Helper: Tìm kiếm cho cấp Quản lý / HR (Tên, Mã NV, Lý do)
    private static void applyManagerKeywordSearch(List<Predicate> predicates, Root<LeaveRequest> root,
                                                 Join<LeaveRequest, User> requestorJoin,
                                                 CriteriaBuilder cb, LeaveFilterRequest filter) {
        if (filter.getKeyword() != null && !filter.getKeyword().isBlank()) {
            String searchPattern = "%" + filter.getKeyword().trim().toLowerCase() + "%";
            Predicate searchPredicate = cb.or(
                cb.like(cb.lower(requestorJoin.get("firstName")), searchPattern),
                cb.like(cb.lower(requestorJoin.get("lastName")), searchPattern),
                cb.like(cb.lower(requestorJoin.get("employeeCode")), searchPattern),
                cb.like(cb.lower(root.get("reason")), searchPattern)
            );
            predicates.add(searchPredicate);
        }
    }
}