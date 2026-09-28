package com.minhtrung.hrm.overtime.specification;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.domain.Specification;

import com.minhtrung.hrm.employees.dtos.internals.UserRole;
import com.minhtrung.hrm.employees.entities.Department;
import com.minhtrung.hrm.employees.entities.Job;
import com.minhtrung.hrm.employees.entities.User;
import com.minhtrung.hrm.overtime.dtos.requests.OvertimeFilterRequest;
import com.minhtrung.hrm.overtime.entities.OvertimeRecord;

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
        return forApprovals(userRole, filter, false);
    }

    // ponytail: grant APPROVE = bỏ qua chuỗi phân cấp, thấy MỌI đơn toàn công ty kể cả đã xử lý
    // (chỉ trừ đơn của chính mình — filter status là optional nên không tự lọc pending).
    // Trần: đây là cố ý, và UI /admin đã ghi rõ "toàn công ty" trong nhãn quyền. Nếu muốn siết thì
    // thêm predicate status=PENDING vào nhánh này, hoặc tách OVERTIME_APPROVE_ALL khỏi OVERTIME_APPROVE.
    public static Specification<OvertimeRecord> forApprovals(UserRole userRole, OvertimeFilterRequest filter, boolean hasApproveGrant) {
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

            if (hasApproveGrant) {
                // grant: bỏ qua chuỗi phân cấp, chỉ giữ lọc ngày/trạng thái/keyword bên dưới
            } else if (isExecutive && myJob.contains("Chairman")) {
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