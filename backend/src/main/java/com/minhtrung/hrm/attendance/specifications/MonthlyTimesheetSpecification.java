package com.minhtrung.hrm.attendance.specifications;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.domain.Specification;

import com.minhtrung.hrm.attendance.dtos.requests.CompanyTimesheetFilterRequest;
import com.minhtrung.hrm.attendance.dtos.requests.ManagerTimesheetFilterRequest;
import com.minhtrung.hrm.attendance.dtos.requests.StaffTimesheetFilterRequest;
import com.minhtrung.hrm.attendance.entities.MonthlyTimesheet;
import com.minhtrung.hrm.attendance.enums.TimesheetStatus;
import com.minhtrung.hrm.employees.dtos.internals.UserRole;
import com.minhtrung.hrm.employees.entities.Department;
import com.minhtrung.hrm.employees.entities.User;

import jakarta.persistence.criteria.CriteriaBuilder;
import jakarta.persistence.criteria.CriteriaQuery;
import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.JoinType;
import jakarta.persistence.criteria.Predicate;
import jakarta.persistence.criteria.Root;

public class MonthlyTimesheetSpecification {

    @SuppressWarnings("unchecked")
    private static Join<MonthlyTimesheet, User> setupJoins(Root<MonthlyTimesheet> root, CriteriaQuery<?> query) {
        if (Long.class.equals(query.getResultType()) || long.class.equals(query.getResultType())) {
            return root.join("user", JoinType.INNER);
        }
        Join<MonthlyTimesheet, User> userJoin = (Join<MonthlyTimesheet, User>) root.<MonthlyTimesheet, User>fetch("user", JoinType.INNER);
        userJoin.fetch("department", JoinType.INNER);
        userJoin.fetch("job", JoinType.LEFT);
        return userJoin;
    }

    private static void applyPeriodAndStatusFilters(List<Predicate> predicates, Root<MonthlyTimesheet> root,
                                                   CriteriaBuilder cb, Integer month, Integer year, TimesheetStatus status) {
        if (month != null) {
            predicates.add(cb.equal(root.get("periodMonth"), month));
        }
        if (year != null) {
            predicates.add(cb.equal(root.get("periodYear"), year));
        }
        if (status != null) {
            predicates.add(cb.equal(root.get("status"), status));
        }
    }

    private static void applyKeywordSearch(List<Predicate> predicates, Join<MonthlyTimesheet, User> userJoin,
                                           CriteriaBuilder cb, String keyword) {
        if (keyword != null && !keyword.isBlank()) {
            String likeKeyword = "%" + keyword.trim().toLowerCase() + "%";
            Predicate searchCode = cb.like(cb.lower(userJoin.get("employeeCode")), likeKeyword);
            Predicate searchFirstName = cb.like(cb.lower(userJoin.get("firstName")), likeKeyword);
            Predicate searchLastName = cb.like(cb.lower(userJoin.get("lastName")), likeKeyword);

            predicates.add(cb.or(searchCode, searchFirstName, searchLastName));
        }
    }

    private static void applyDepartmentFilter(List<Predicate> predicates, Join<MonthlyTimesheet, User> userJoin,
                                              List<String> departmentNames) {
        if (departmentNames != null && !departmentNames.isEmpty()) {
            Join<User, Department> deptJoin = userJoin.join("department", JoinType.INNER);
            predicates.add(deptJoin.get("name").in(departmentNames));
        }
    }

    // ─── 1. TAB CỦA TÔI: Nhân viên chỉ xem bảng công của chính mình ───────────
    public static Specification<MonthlyTimesheet> filterForStaff(UUID currentUserId, StaffTimesheetFilterRequest filter) {
        return (root, query, cb) -> {
            Join<MonthlyTimesheet, User> userJoin = setupJoins(root, query);
            List<Predicate> predicates = new ArrayList<>();

            predicates.add(cb.equal(userJoin.get("userId"), currentUserId));
            applyPeriodAndStatusFilters(predicates, root, cb, filter.getMonth(), filter.getYear(), filter.getStatus());

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }

    // ─── 2. TAB PHÒNG BAN: Trưởng phòng xem nhân viên trong phòng (CHỪA MÌNH RA) ──
    public static Specification<MonthlyTimesheet> filterForManager(UserRole managerRole, ManagerTimesheetFilterRequest filter) {
        return (root, query, cb) -> {
            Join<MonthlyTimesheet, User> userJoin = setupJoins(root, query);
            Join<User, Department> deptJoin = userJoin.join("department", JoinType.INNER);
            List<Predicate> predicates = new ArrayList<>();

            // 👉 Chừa chính Trưởng phòng ra (xem công của mình ở Tab 1)
            predicates.add(cb.notEqual(userJoin.get("userId"), managerRole.getUserId()));

            // Lọc theo phòng ban phụ trách
            predicates.add(cb.equal(deptJoin.get("name"), managerRole.getDepartment()));

            applyPeriodAndStatusFilters(predicates, root, cb, filter.getMonth(), filter.getYear(), filter.getStatus());
            applyKeywordSearch(predicates, userJoin, cb, filter.getKeyword());

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }

    // ─── 3. TAB TOÀN CÔNG TY: HR / Giám đốc xem toàn công ty (CHỪA MÌNH RA) ───
    public static Specification<MonthlyTimesheet> filterForCompany(UUID currentUserId, CompanyTimesheetFilterRequest filter) {
        return (root, query, cb) -> {
            Join<MonthlyTimesheet, User> userJoin = setupJoins(root, query);
            List<Predicate> predicates = new ArrayList<>();

            // 👉 Chừa chính người đang xem ra
            predicates.add(cb.notEqual(userJoin.get("userId"), currentUserId));

            applyPeriodAndStatusFilters(predicates, root, cb, filter.getMonth(), filter.getYear(), filter.getStatus());
            applyKeywordSearch(predicates, userJoin, cb, filter.getKeyword());
            applyDepartmentFilter(predicates, userJoin, filter.getDepartmentNames());

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }
}
