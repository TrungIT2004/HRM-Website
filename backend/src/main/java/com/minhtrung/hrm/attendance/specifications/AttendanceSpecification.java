package com.minhtrung.hrm.attendance.specifications;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.domain.Specification;

import com.minhtrung.hrm.attendance.dtos.requests.AttendanceFilterRequest;
import com.minhtrung.hrm.attendance.entities.Attendance;
import com.minhtrung.hrm.common.specifications.SpecificationScopes;
import com.minhtrung.hrm.employees.dtos.internals.UserRole;
import com.minhtrung.hrm.employees.entities.Department;
import com.minhtrung.hrm.employees.entities.Job;
import com.minhtrung.hrm.employees.entities.User;

import jakarta.persistence.criteria.CriteriaBuilder;
import jakarta.persistence.criteria.CriteriaQuery;
import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.JoinType;
import jakarta.persistence.criteria.Predicate;
import jakarta.persistence.criteria.Root;

public class AttendanceSpecification {

    // Helper: Xử lý Fetch Join tránh N+1 query khi Query Data (bỏ qua khi Count Query)
    @SuppressWarnings("unchecked")
    private static Join<Attendance, User> setupJoins(Root<Attendance> root, CriteriaQuery<?> query) {
        if (Long.class.equals(query.getResultType()) || long.class.equals(query.getResultType())) {
            return root.join("user", JoinType.INNER);
        }
        Join<Attendance, User> userJoin = (Join<Attendance, User>) root.<Attendance, User>fetch("user", JoinType.INNER);
        userJoin.fetch("department", JoinType.INNER);
        userJoin.fetch("job", JoinType.LEFT);
        root.fetch("editor", JoinType.LEFT);
        return userJoin;
    }

    // Helper: Lọc Status, Khoảng ngày và điều kiện is_deleted = false
    private static void applyDateAndStatusFilters(List<Predicate> predicates, Root<Attendance> root,
                                                 CriteriaBuilder cb, AttendanceFilterRequest filter) {
        predicates.add(cb.isFalse(root.get("isDeleted")));

        if (filter.getStatus() != null) {
            predicates.add(cb.equal(root.get("status"), filter.getStatus()));
        }
        if (filter.getStartDate() != null) {
            predicates.add(cb.greaterThanOrEqualTo(root.get("workDate"), filter.getStartDate()));
        }
        if (filter.getEndDate() != null) {
            predicates.add(cb.lessThanOrEqualTo(root.get("workDate"), filter.getEndDate()));
        }
    }

    // Helper: Tìm kiếm theo Keyword (Mã NV, Tên, Email)
    private static void applyKeywordSearch(List<Predicate> predicates, Join<Attendance, User> userJoin,
                                          CriteriaBuilder cb, AttendanceFilterRequest filter) {
        if (filter.getKeyword() != null && !filter.getKeyword().isBlank()) {
            String likeKeyword = "%" + filter.getKeyword().trim().toLowerCase() + "%";
            Predicate searchCode = cb.like(cb.lower(userJoin.get("employeeCode")), likeKeyword);
            Predicate searchFirstName = cb.like(cb.lower(userJoin.get("firstName")), likeKeyword);
            Predicate searchLastName = cb.like(cb.lower(userJoin.get("lastName")), likeKeyword);
            Predicate searchEmail = cb.like(cb.lower(userJoin.get("email")), likeKeyword);

            predicates.add(cb.or(searchCode, searchFirstName, searchLastName, searchEmail));
        }
    }

    // =========================================================================
    // 1. SPECIFICATION: Chấm công cá nhân
    // =========================================================================
    public static Specification<Attendance> forMyAttendances(UUID currentUserId, AttendanceFilterRequest filter) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            Join<Attendance, User> userJoin = setupJoins(root, query);

            predicates.add(cb.equal(userJoin.get("userId"), currentUserId));
            applyDateAndStatusFilters(predicates, root, cb, filter);

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }

    // =========================================================================
    // 2. SPECIFICATION: Chấm công quản lý (Trưởng phòng / Ban Giám Đốc)
    // =========================================================================
    public static Specification<Attendance> forManagement(UserRole userRole, AttendanceFilterRequest filter) {
        return forManagement(userRole, filter, false);
    }

    // hasDeptGrant (ATTENDANCE_VIEW_DEPT): người không phải trưởng phòng nhưng được cấp quyền
    // thì thấy đúng phòng ban mình, cùng luật loại trừ như trưởng phòng.
    public static Specification<Attendance> forManagement(UserRole userRole, AttendanceFilterRequest filter, boolean hasDeptGrant) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            Join<Attendance, User> userJoin = setupJoins(root, query);
            Join<User, Department> deptJoin = userJoin.join("department", JoinType.LEFT);
            Join<User, Job> jobJoin = userJoin.join("job", JoinType.LEFT);

            UUID currentUserId = userRole.getUserId();
            String myDepartment = userRole.getDepartment() != null ? userRole.getDepartment() : "";
            String myJob = userRole.getJob() != null ? userRole.getJob() : "";

            // Loại trừ chấm công của chính quản lý
            predicates.add(cb.notEqual(userJoin.get("userId"), currentUserId));

            // Chung 1 luật phân cấp với leave/overtime (SpecificationScopes) — lệch là rò dữ liệu
            SpecificationScopes.applyManagementHierarchy(
                    predicates, deptJoin, jobJoin, cb, myDepartment, myJob, hasDeptGrant, false);

            applyDateAndStatusFilters(predicates, root, cb, filter);
            applyKeywordSearch(predicates, userJoin, cb, filter);

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }

    // =========================================================================
    // 3. SPECIFICATION: Chấm công toàn công ty (Dành cho HR)
    // =========================================================================
    public static Specification<Attendance> forCompanyWide(AttendanceFilterRequest filter) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            Join<Attendance, User> userJoin = setupJoins(root, query);
            Join<User, Department> deptJoin = userJoin.join("department", JoinType.LEFT);

            // Lọc theo nhiều phòng ban nếu HR chọn
            if (filter.getDepartmentNames() != null && !filter.getDepartmentNames().isEmpty()) {
                predicates.add(deptJoin.get("name").in(filter.getDepartmentNames()));
            }

            applyDateAndStatusFilters(predicates, root, cb, filter);
            applyKeywordSearch(predicates, userJoin, cb, filter);

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }
}