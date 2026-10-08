package com.minhtrung.hrm.performance.specifications;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.domain.Specification;

import com.minhtrung.hrm.employees.dtos.internals.UserRole;
import com.minhtrung.hrm.employees.entities.Department;
import com.minhtrung.hrm.employees.entities.User;
import com.minhtrung.hrm.performance.dtos.requests.PerformanceFilterRequest;
import com.minhtrung.hrm.performance.entities.PerformanceReview;

import jakarta.persistence.criteria.CriteriaBuilder;
import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.JoinType;
import jakarta.persistence.criteria.Predicate;
import jakarta.persistence.criteria.Root;

public class PerformanceSpecification {

    private static void applyFilters(List<Predicate> predicates, Root<PerformanceReview> root,
                                     Join<PerformanceReview, User> userJoin,
                                     CriteriaBuilder cb, PerformanceFilterRequest filter) {
        if (filter == null) return;
        if (filter.getPeriodType() != null && !filter.getPeriodType().isBlank()) {
            predicates.add(cb.equal(root.get("periodType"), filter.getPeriodType().toUpperCase()));
        }
        if (filter.getYear() != null) {
            predicates.add(cb.equal(root.get("periodYear"), filter.getYear()));
        }
        if (filter.getMonth() != null) {
            predicates.add(cb.equal(root.get("periodMonth"), filter.getMonth()));
        }
        if (filter.getStatus() != null && !filter.getStatus().isBlank()) {
            predicates.add(cb.equal(root.get("status"), filter.getStatus().toUpperCase()));
        }
        if (filter.getDepartment() != null && !filter.getDepartment().isBlank()) {
            Join<User, Department> deptJoin = userJoin.join("department", JoinType.LEFT);
            predicates.add(cb.equal(deptJoin.get("name"), filter.getDepartment()));
        }
        if (filter.getKeyword() != null && !filter.getKeyword().isBlank()) {
            String p = "%" + filter.getKeyword().trim().toLowerCase() + "%";
            predicates.add(cb.or(
                cb.like(cb.lower(userJoin.get("firstName")), p),
                cb.like(cb.lower(userJoin.get("lastName")), p),
                cb.like(cb.lower(userJoin.get("employeeCode")), p)));
        }
    }

    public static Specification<PerformanceReview> forMyRecords(UUID currentUserId, PerformanceFilterRequest filter) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            Join<PerformanceReview, User> userJoin = root.join("user", JoinType.INNER);
            predicates.add(cb.equal(userJoin.get("userId"), currentUserId));
            applyFilters(predicates, root, userJoin, cb, filter);
            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }

    // DANH SACH PHONG (trang records tab phong ban): cung phong, tru bai cua chinh minh (khỏi tu cham).
    // Khac Leave/OT: khong bypass theo grant — cong ty da co endpoint /company rieng.
    public static Specification<PerformanceReview> forApprovals(UserRole userRole, PerformanceFilterRequest filter) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            Join<PerformanceReview, User> userJoin = root.join("user", JoinType.INNER);
            Join<User, Department> deptJoin = userJoin.join("department", JoinType.LEFT);

            predicates.add(cb.notEqual(userJoin.get("userId"), userRole.getUserId()));
            String myDepartment = userRole.getDepartment() != null ? userRole.getDepartment() : "";
            predicates.add(cb.equal(deptJoin.get("name"), myDepartment));

            applyFilters(predicates, root, userJoin, cb, filter);
            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }

    // SPEC RIENG CHO OVERVIEW/RECORDS PHAM VI PHONG: loc cung theo phong, khong bypass theo grant
    // (forApprovals cua Leave/OT mo rong theo grant — dung o day se lot ca cong ty vao mode phong ban)
    public static Specification<PerformanceReview> forDeptScope(String department, PerformanceFilterRequest filter) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            Join<PerformanceReview, User> userJoin = root.join("user", JoinType.INNER);
            Join<User, Department> deptJoin = userJoin.join("department", JoinType.LEFT);
            predicates.add(cb.equal(deptJoin.get("name"), department != null ? department : ""));
            applyFilters(predicates, root, userJoin, cb, filter);
            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }

    public static Specification<PerformanceReview> forCompanyWide(PerformanceFilterRequest filter) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            Join<PerformanceReview, User> userJoin = root.join("user", JoinType.INNER);
            applyFilters(predicates, root, userJoin, cb, filter);
            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }
}
