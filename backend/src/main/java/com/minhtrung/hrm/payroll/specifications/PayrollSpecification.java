package com.minhtrung.hrm.payroll.specifications;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.domain.Specification;

import com.minhtrung.hrm.employees.entities.Department;
import com.minhtrung.hrm.employees.entities.User;
import com.minhtrung.hrm.payroll.dtos.requests.CompanyPayrollFilterRequest;
import com.minhtrung.hrm.payroll.dtos.requests.StaffPayrollFilterRequest;
import com.minhtrung.hrm.payroll.entities.Payroll;
import com.minhtrung.hrm.payroll.enums.PayrollStatus;

import jakarta.persistence.criteria.CriteriaBuilder;
import jakarta.persistence.criteria.CriteriaQuery;
import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.JoinType;
import jakarta.persistence.criteria.Predicate;
import jakarta.persistence.criteria.Root;

public class PayrollSpecification {

    // Helper: Fetch Join tránh N+1 query
    @SuppressWarnings("unchecked")
    private static Join<Payroll, User> setupJoins(Root<Payroll> root, CriteriaQuery<?> query) {
        if (Long.class.equals(query.getResultType()) || long.class.equals(query.getResultType())) {
            return root.join("user", JoinType.INNER);
        }
        Join<Payroll, User> userJoin = (Join<Payroll, User>) root.<Payroll, User>fetch("user", JoinType.INNER);
        userJoin.fetch("department", JoinType.INNER);
        userJoin.fetch("job", JoinType.LEFT);
        root.fetch("timesheet", JoinType.LEFT);
        return userJoin;
    }

    // Helper: Lọc Kỳ lương (Month, Year) và Status
    private static void applyPeriodAndStatusFilters(List<Predicate> predicates, Root<Payroll> root,
                                                   CriteriaBuilder cb, Integer month, Integer year, PayrollStatus status) {
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

    // Helper: Tìm kiếm theo Keyword (Mã NV, Họ, Tên)
    private static void applyKeywordSearch(List<Predicate> predicates, Join<Payroll, User> userJoin,
                                           CriteriaBuilder cb, String keyword) {
        if (keyword != null && !keyword.isBlank()) {
            String likeKeyword = "%" + keyword.trim().toLowerCase() + "%";
            Predicate searchCode = cb.like(cb.lower(userJoin.get("employeeCode")), likeKeyword);
            Predicate searchFirstName = cb.like(cb.lower(userJoin.get("firstName")), likeKeyword);
            Predicate searchLastName = cb.like(cb.lower(userJoin.get("lastName")), likeKeyword);

            predicates.add(cb.or(searchCode, searchFirstName, searchLastName));
        }
    }

    // Helper: Lọc danh sách phòng ban
    private static void applyDepartmentFilter(List<Predicate> predicates, Join<Payroll, User> userJoin,
                                              List<String> departmentNames) {
        if (departmentNames != null && !departmentNames.isEmpty()) {
            Join<User, Department> deptJoin = userJoin.join("department", JoinType.INNER);
            predicates.add(deptJoin.get("name").in(departmentNames));
        }
    }

    // ─── 1. TAB CỦA TÔI: Bất kỳ ai (Staff, Manager, HR) chỉ xem phiếu lương của chính mình ──
    public static Specification<Payroll> filterForStaff(UUID currentUserId, StaffPayrollFilterRequest filter) {
        return (root, query, cb) -> {
            Join<Payroll, User> userJoin = setupJoins(root, query);
            List<Predicate> predicates = new ArrayList<>();

            predicates.add(cb.equal(userJoin.get("userId"), currentUserId));
            applyPeriodAndStatusFilters(predicates, root, cb, filter.getPeriodMonth(), filter.getPeriodYear(), filter.getStatus());

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }

    // ─── 2. TAB TOÀN CÔNG TY: CHỈ Kế toán & Ban Giám đốc xem toàn công ty ───
    public static Specification<Payroll> filterForCompany(CompanyPayrollFilterRequest filter) {
        return (root, query, cb) -> {
            Join<Payroll, User> userJoin = setupJoins(root, query);
            List<Predicate> predicates = new ArrayList<>();

            applyPeriodAndStatusFilters(predicates, root, cb, filter.getPeriodMonth(), filter.getPeriodYear(), filter.getStatus());
            applyKeywordSearch(predicates, userJoin, cb, filter.getKeyword());
            applyDepartmentFilter(predicates, userJoin, filter.getDepartmentNames());

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }
}
