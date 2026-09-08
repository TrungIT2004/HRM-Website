package com.minhtrung.social_app.overtime.specification;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.domain.Specification;

import com.minhtrung.social_app.employees.dtos.internals.UserRole;
import com.minhtrung.social_app.employees.entities.Department;
import com.minhtrung.social_app.employees.entities.Job;
import com.minhtrung.social_app.employees.entities.User;
import com.minhtrung.social_app.overtime.dtos.requests.OvertimeFilterRequest;
import com.minhtrung.social_app.overtime.entities.OvertimeRecord;

import jakarta.persistence.criteria.CriteriaBuilder;
import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.JoinType;
import jakarta.persistence.criteria.Predicate;
import jakarta.persistence.criteria.Root;

public class OvertimeSpecification {

    private static void applyDateAndStatusFilters(List<Predicate> predicates, Root<OvertimeRecord> root,
                                                 CriteriaBuilder cb, OvertimeFilterRequest filter) {
        if (filter.getStatus() != null && !filter.getStatus().isBlank()) {
            predicates.add(cb.equal(root.get("status"), filter.getStatus().toLowerCase()));
        }
        if (filter.getFromDate() != null) {
            predicates.add(cb.greaterThanOrEqualTo(root.get("approvedDate"), filter.getFromDate()));
        }
        if (filter.getToDate() != null) {
            predicates.add(cb.lessThanOrEqualTo(root.get("approvedDate"), filter.getToDate()));
        }
    }

    private static void applyManagerKeywordSearch(List<Predicate> predicates,
                                                 Join<OvertimeRecord, User> requestorJoin,
                                                 CriteriaBuilder cb, OvertimeFilterRequest filter) {
        if (filter.getKeyword() != null && !filter.getKeyword().isBlank()) {
            String searchPattern = "%" + filter.getKeyword().trim().toLowerCase() + "%";
            Predicate searchPredicate = cb.or(
                cb.like(cb.lower(requestorJoin.get("firstName")), searchPattern),
                cb.like(cb.lower(requestorJoin.get("lastName")), searchPattern),
                cb.like(cb.lower(requestorJoin.get("employeeCode")), searchPattern)
            );
            predicates.add(searchPredicate);
        }
    }

    // 1. SPECIFICATION: Đơn OT cá nhân
    public static Specification<OvertimeRecord> forMyRecords(UUID currentUserId, OvertimeFilterRequest filter) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            Join<OvertimeRecord, User> requestorJoin = root.join("requestor", JoinType.INNER);

            predicates.add(cb.equal(requestorJoin.get("userId"), currentUserId));
            applyDateAndStatusFilters(predicates, root, cb, filter);

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }

    // 2. SPECIFICATION: Đơn OT cần phê duyệt (Theo cấp quản lý)
    public static Specification<OvertimeRecord> forApprovals(UserRole userRole, OvertimeFilterRequest filter) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            Join<OvertimeRecord, User> requestorJoin = root.join("requestor", JoinType.INNER);
            Join<User, Department> deptJoin = requestorJoin.join("department", JoinType.LEFT);
            Join<User, Job> jobJoin = requestorJoin.join("job", JoinType.LEFT);

            UUID currentUserId = userRole.getUserId();
            String myDepartment = userRole.getDepartment() != null ? userRole.getDepartment() : "";
            String myJob = userRole.getJob() != null ? userRole.getJob() : "";

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

            applyDateAndStatusFilters(predicates, root, cb, filter);
            applyManagerKeywordSearch(predicates, requestorJoin, cb, filter);

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }

    // 3. SPECIFICATION: Toàn bộ đơn OT công ty (HR theo dõi / tính lương)
    public static Specification<OvertimeRecord> forCompanyWide(OvertimeFilterRequest filter) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            Join<OvertimeRecord, User> requestorJoin = root.join("requestor", JoinType.INNER);

            applyDateAndStatusFilters(predicates, root, cb, filter);
            applyManagerKeywordSearch(predicates, requestorJoin, cb, filter);

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }
}