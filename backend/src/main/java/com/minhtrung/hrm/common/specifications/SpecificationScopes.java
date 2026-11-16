package com.minhtrung.hrm.common.specifications;

import java.util.List;

import com.minhtrung.hrm.employees.entities.Department;
import com.minhtrung.hrm.employees.entities.Job;
import com.minhtrung.hrm.employees.entities.User;

import jakarta.persistence.criteria.CriteriaBuilder;
import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.Predicate;

/**
 * Shared PBAC predicate: who sees whose records along the management hierarchy.
 * Single source of truth for attendance / leave / overtime visibility
 * (Chairman → Director → Deputy → Department Head → own department).
 */
public final class SpecificationScopes {

    private SpecificationScopes() {
    }

    public static void applyManagementHierarchy(
            List<Predicate> predicates,
            Join<User, Department> deptJoin,
            Join<User, Job> jobJoin,
            CriteriaBuilder cb,
            String myDepartment,
            String myJob,
            boolean hasDeptGrant,
            boolean hasApproveGrant) {
        boolean isExecutive = "Executive Leadership".equals(myDepartment);
        boolean isDepartmentHead = myJob.startsWith("Department Head");
        // Trưởng phòng theo chức danh HOẶC theo grant phòng ban đều chỉ xem phòng mình
        boolean asDepartmentHead = isDepartmentHead || hasDeptGrant;

        if (hasApproveGrant) {
            // grant: bỏ qua chuỗi phân cấp, chỉ giữ lọc ngày/trạng thái/keyword bên dưới
        } else if (isExecutive && myJob.contains("Chairman")) {
            // Chủ tịch xem Giám Đốc & Phó Giám Đốc
            Predicate isExecDept = cb.equal(deptJoin.get("name"), "Executive Leadership");
            Predicate isDirectors = cb.or(
                cb.like(jobJoin.get("title"), "%Director%"),
                cb.like(jobJoin.get("title"), "%Deputy%")
            );
            predicates.add(cb.and(isExecDept, isDirectors));
        }
        else if (isExecutive && myJob.contains("Director") && !myJob.contains("Deputy") && !myJob.contains("Vice")) {
            // Giám đốc xem Phó Giám Đốc và các Trưởng phòng
            Predicate isViceDirector = cb.and(
                cb.equal(deptJoin.get("name"), "Executive Leadership"),
                cb.or(cb.like(jobJoin.get("title"), "%Deputy%"), cb.like(jobJoin.get("title"), "%Vice%"))
            );
            Predicate isDepartmentHeads = cb.like(jobJoin.get("title"), "Department Head%");
            predicates.add(cb.or(isViceDirector, isDepartmentHeads));
        }
        else if (isExecutive && (myJob.contains("Deputy") || myJob.contains("Vice"))) {
            // Phó Giám đốc xem các Trưởng phòng
            predicates.add(cb.like(jobJoin.get("title"), "Department Head%"));
        }
        else if (asDepartmentHead) {
            // Trưởng phòng (chức danh hoặc grant) CHỈ XEM nhân viên thuộc phòng ban mình
            Predicate sameDept = cb.equal(deptJoin.get("name"), myDepartment);
            Predicate notAnotherHead = cb.notLike(jobJoin.get("title"), "Department Head%");
            predicates.add(cb.and(sameDept, notAnotherHead));
        }
        else {
            predicates.add(cb.disjunction()); // Nhân viên thường không có quyền quản lý
        }
    }
}
