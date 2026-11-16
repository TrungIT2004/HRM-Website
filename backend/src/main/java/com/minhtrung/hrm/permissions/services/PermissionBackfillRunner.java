package com.minhtrung.hrm.permissions.services;

import java.time.LocalDateTime;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import com.minhtrung.hrm.employees.entities.User;
import com.minhtrung.hrm.employees.repositories.UserRepository;
import com.minhtrung.hrm.permissions.entities.PermissionGrant;
import com.minhtrung.hrm.permissions.enums.PermissionKey;
import com.minhtrung.hrm.permissions.repositories.PermissionGrantRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * Gieo grants lần đầu cho người giữ vai trò (HR / Ban Giám Đốc / Kế toán trưởng / SysAdmin).
 * Lý do: specs duyệt đơn (Phương án A) giữ nhánh phân cấp theo dept/job KHÔNG cần grant, nhưng các
 * nhánh company-wide và gate frontend (`can()` đọc claim JWT) thì cần grant thật — tài khoản cũ
 * tạo trước bảng grants nên đang trắng tick dù đúng vai trò.
 * Chạy mỗi lần boot, chỉ INSERT thiếu (idempotent), không bao giờ xóa hay đá session.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class PermissionBackfillRunner implements ApplicationRunner {

    private static final Set<PermissionKey> HR_KEYS = EnumSet.of(
            PermissionKey.ATTENDANCE_VIEW_ALL, PermissionKey.LEAVE_VIEW_ALL,
            PermissionKey.OVERTIME_VIEW_ALL, PermissionKey.RESIGN_VIEW_ALL,
            PermissionKey.LEAVE_APPROVE, PermissionKey.OVERTIME_APPROVE, PermissionKey.RESIGN_APPROVE,
            PermissionKey.TIMESHEET_LOCK, PermissionKey.EMPLOYEE_VIEW_ALL, PermissionKey.EMPLOYEE_EDIT,
            PermissionKey.ORG_MANAGE, PermissionKey.DOCUMENT_UPLOAD,
            PermissionKey.VIEW_ASSETS, PermissionKey.MANAGE_ASSETS,
            PermissionKey.EVALUATION_VIEW_ALL, PermissionKey.EVALUATION_APPROVE);

    private static final Set<PermissionKey> EXEC_KEYS = EnumSet.of(
            PermissionKey.ATTENDANCE_VIEW_ALL, PermissionKey.LEAVE_VIEW_ALL,
            PermissionKey.OVERTIME_VIEW_ALL, PermissionKey.PAYROLL_VIEW_ALL, PermissionKey.RESIGN_VIEW_ALL,
            PermissionKey.LEAVE_APPROVE, PermissionKey.OVERTIME_APPROVE, PermissionKey.RESIGN_APPROVE,
            PermissionKey.TIMESHEET_LOCK, PermissionKey.PAYROLL_MANAGE,
            PermissionKey.EMPLOYEE_VIEW_ALL, PermissionKey.DOCUMENT_UPLOAD,
            PermissionKey.EVALUATION_VIEW_ALL, PermissionKey.EVALUATION_APPROVE);

    private static final Set<PermissionKey> ACCOUNTING_HEAD_KEYS = EnumSet.of(
            PermissionKey.PAYROLL_VIEW_ALL, PermissionKey.PAYROLL_MANAGE);

    // Quyền phạm vi phòng ban: gieo cho mọi Trưởng phòng (kể cả Trưởng phòng HR —
    // người này đã có bộ công ty nên sở hữu cả 2 phạm vi, frontend hiện 2 tabs).
    private static final Set<PermissionKey> DEPT_KEYS = EnumSet.of(
            PermissionKey.ATTENDANCE_VIEW_DEPT, PermissionKey.LEAVE_VIEW_DEPT,
            PermissionKey.OVERTIME_VIEW_DEPT, PermissionKey.LEAVE_APPROVE_DEPT,
            PermissionKey.OVERTIME_APPROVE_DEPT,
            PermissionKey.EVALUATION_VIEW_DEPT, PermissionKey.EVALUATION_APPROVE_DEPT);

    // ponytail: liệt kê tường minh 16 key hợp lệ trong CHECK constraint của DB thay vì
    // EnumSet.allOf — enum có thể được thêm key mới (_DEPT...) mà constraint chưa cho phép,
    // allOf sẽ gieo key lạ → 500 + sập boot. Key mới do luồng khác quản lý.
    private static final Set<PermissionKey> SYSADMIN_KEYS = EnumSet.of(
            PermissionKey.ATTENDANCE_VIEW_ALL, PermissionKey.LEAVE_VIEW_ALL,
            PermissionKey.OVERTIME_VIEW_ALL, PermissionKey.PAYROLL_VIEW_ALL, PermissionKey.RESIGN_VIEW_ALL,
            PermissionKey.LEAVE_APPROVE, PermissionKey.OVERTIME_APPROVE, PermissionKey.RESIGN_APPROVE,
            PermissionKey.TIMESHEET_LOCK, PermissionKey.PAYROLL_MANAGE,
            PermissionKey.ACCOUNT_LOCK, PermissionKey.PERMISSION_GRANT, PermissionKey.ORG_MANAGE,
            PermissionKey.EMPLOYEE_VIEW_ALL, PermissionKey.EMPLOYEE_EDIT, PermissionKey.DOCUMENT_UPLOAD,
            PermissionKey.VIEW_ASSETS, PermissionKey.MANAGE_ASSETS,
            PermissionKey.EVALUATION_VIEW_ALL, PermissionKey.EVALUATION_VIEW_DEPT,
            PermissionKey.EVALUATION_APPROVE, PermissionKey.EVALUATION_APPROVE_DEPT);

    private final UserRepository userRepository;
    private final PermissionGrantRepository grantRepository;

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        UUID granter = findGranter();
        if (granter == null) {
            log.warn("Permission backfill: không tìm thấy SUPER_ADMIN/sysadmin để đứng tên granted_by — bỏ qua.");
            return;
        }
        int added = 0;
        for (User u : userRepository.findAll()) {
            Set<PermissionKey> want = keysFor(u);
            if (want.isEmpty() || u.getUserId() == null) continue;
            Set<String> have = grantRepository.findByUserId(u.getUserId()).stream()
                    .map(g -> g.getPermission().name())
                    .collect(Collectors.toSet());
            for (PermissionKey k : want) {
                if (have.contains(k.name())) continue;
                try {
                    grantRepository.save(new PermissionGrant(u.getUserId(), k, granter, LocalDateTime.now()));
                    added++;
                } catch (Exception ex) {
                    // ponytail: 1 key lạ (CHECK constraint chưa cho phép) không được sập cả boot
                    log.warn("Permission backfill: bỏ qua {} cho user {} ({})", k, u.getUserId(), ex.getMessage());
                }
            }
        }
        if (added > 0) log.info("Permission backfill: đã gieo {} grants còn thiếu (granted_by={}).", added, granter);
        else log.info("Permission backfill: không có gì thiếu.");
    }

    private UUID findGranter() {
        User sa = userRepository.findByEmail("superadmin@company.com");
        if (sa != null && sa.getUserId() != null) return sa.getUserId();
        User sys = userRepository.findByEmail("sysadmin@company.com");
        return sys != null ? sys.getUserId() : null;
    }

    private Set<PermissionKey> keysFor(User u) {
        String dept = u.getDepartment() != null && u.getDepartment().getName() != null
                ? u.getDepartment().getName().trim() : "";
        String job = u.getJob() != null && u.getJob().getTitle() != null
                ? u.getJob().getTitle().trim() : "";
        String deptLower = dept.toLowerCase();
        String jobLower = job.toLowerCase();
        String email = u.getEmail() != null ? u.getEmail().toLowerCase() : "";

        // ponytail: Trưởng phòng KHÔNG gieo APPROVE toàn công ty — spec giữ duyệt trong phòng
        // không cần grant, gieo vào là nới thành duyệt toàn công ty (trái Phương án A đã chốt).
        // Grant *_DEPT (phạm vi phòng ban) thì gieo: cộng thêm vào cuối, không thay base.
        Set<PermissionKey> base;
        if ("human resources".equalsIgnoreCase(dept)) base = EnumSet.copyOf(HR_KEYS);
        else if ("executive leadership".equalsIgnoreCase(dept)) base = EnumSet.copyOf(EXEC_KEYS);
        else if (email.equals("sysadmin@company.com") || job.equalsIgnoreCase("SUPER_ADMIN")
                || jobLower.contains("super admin")
                || ((deptLower.equals("it") || deptLower.contains("information technology"))
                        && (jobLower.contains("system administrator") || jobLower.equals("admin")))) {
            base = EnumSet.copyOf(SYSADMIN_KEYS);
        }
        else if (deptLower.contains("account")
                && (jobLower.contains("head") || jobLower.contains("chief") || jobLower.contains("manager")
                        || jobLower.contains("lead") || jobLower.contains("trưởng"))) {
            base = EnumSet.copyOf(ACCOUNTING_HEAD_KEYS);
        }
        else base = EnumSet.noneOf(PermissionKey.class);
        if (job.startsWith("Department Head")) base.addAll(DEPT_KEYS);
        return base;
    }
}
