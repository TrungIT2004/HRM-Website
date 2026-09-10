package com.minhtrung.hrm.dashboard.services;

import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.minhtrung.hrm.attendance.entities.Attendance;
import com.minhtrung.hrm.attendance.entities.MonthlyTimesheet;
import com.minhtrung.hrm.attendance.enums.AttendanceStatus;
import com.minhtrung.hrm.attendance.repositories.AttendanceRepository;
import com.minhtrung.hrm.attendance.repositories.MonthlyTimesheetRepository;
import com.minhtrung.hrm.dashboard.dtos.responses.DashboardSummaryResponse;
import com.minhtrung.hrm.dashboard.dtos.responses.DashboardSummaryResponse.LeaveBalanceDto;
import com.minhtrung.hrm.dashboard.dtos.responses.DashboardSummaryResponse.MonthlySummaryDto;
import com.minhtrung.hrm.dashboard.dtos.responses.DashboardSummaryResponse.PendingApprovalsDto;
import com.minhtrung.hrm.dashboard.dtos.responses.DashboardSummaryResponse.TodayAttendanceDto;
import com.minhtrung.hrm.dashboard.dtos.responses.DashboardSummaryResponse.UserProfileDto;
import com.minhtrung.hrm.employees.dtos.internals.UserRole;
import com.minhtrung.hrm.employees.entities.User;
import com.minhtrung.hrm.employees.repositories.UserRepository;
import com.minhtrung.hrm.leave.dtos.requests.LeaveFilterRequest;
import com.minhtrung.hrm.leave.enums.LeaveRequestStatus;
import com.minhtrung.hrm.leave.repositories.LeaveRequestRepository;
import com.minhtrung.hrm.leave.specifications.LeaveRequestSpecification;
import com.minhtrung.hrm.overtime.dtos.requests.OvertimeFilterRequest;
import com.minhtrung.hrm.overtime.repositories.OvertimeRecordRepository;
import com.minhtrung.hrm.overtime.specification.OvertimeSpecification;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class DashboardService {

    private final UserRepository userRepository;
    private final AttendanceRepository attendanceRepository;
    private final MonthlyTimesheetRepository monthlyTimesheetRepository;
    private final LeaveRequestRepository leaveRequestRepository;
    private final OvertimeRecordRepository overtimeRecordRepository;

    @Transactional(readOnly = true)
    public DashboardSummaryResponse getDashboardSummary(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy người dùng với ID: " + userId));

        LocalDate today = LocalDate.now();
        int currentMonth = today.getMonthValue();
        int currentYear = today.getYear();

        // 1. Hồ sơ người dùng
        String fullName = (user.getFirstName() != null ? user.getFirstName() : "") + " " +
                          (user.getLastName() != null ? user.getLastName() : "");
        String deptName = user.getDepartment() != null ? user.getDepartment().getName() : "";
        String jobTitle = user.getJob() != null ? user.getJob().getTitle() : "";

        UserProfileDto userProfile = UserProfileDto.builder()
                .fullName(fullName.trim())
                .employeeCode(user.getEmployeeCode())
                .department(deptName)
                .job(jobTitle)
                .profilePicUrl(user.getProfilePicUrl())
                .build();

        // 2. Chấm công hôm nay
        Optional<Attendance> todayAttOpt = attendanceRepository.findUsersTodayAttendance(userId, today);
        TodayAttendanceDto todayAttendance;
        if (todayAttOpt.isPresent()) {
            Attendance att = todayAttOpt.get();
            LocalTime inTime = att.getClockInTime();
            LocalTime outTime = att.getClockOutTime();
            Double hours = null;
            if (inTime != null && outTime != null) {
                hours = Math.round(Duration.between(inTime, outTime).toMinutes() / 60.0 * 10.0) / 10.0;
            }
            todayAttendance = TodayAttendanceDto.builder()
                    .workDate(today)
                    .hasClockIn(inTime != null)
                    .clockInTime(inTime)
                    .clockOutTime(outTime)
                    .status(att.getStatus() != null ? att.getStatus().name() : "WORKING")
                    .workingHours(hours)
                    .build();
        } else {
            todayAttendance = TodayAttendanceDto.builder()
                    .workDate(today)
                    .hasClockIn(false)
                    .clockInTime(null)
                    .clockOutTime(null)
                    .status("NOT_CHECKED_IN")
                    .workingHours(0.0)
                    .build();
        }

        // 3. Tổng hợp công trong tháng
        Optional<MonthlyTimesheet> timesheetOpt = monthlyTimesheetRepository
                .findByUser_UserIdAndPeriodMonthAndPeriodYear(userId, currentMonth, currentYear);
        MonthlySummaryDto monthlySummary;
        if (timesheetOpt.isPresent()) {
            MonthlyTimesheet ts = timesheetOpt.get();
            monthlySummary = MonthlySummaryDto.builder()
                    .month(currentMonth)
                    .year(currentYear)
                    .actualWorkDays(ts.getActualWorkedDays() != null ? ts.getActualWorkedDays().doubleValue() : 0.0)
                    .lateDays(ts.getLateCount())
                    .totalOtHours(ts.getTotalActualOtHours() != null ? ts.getTotalActualOtHours().doubleValue() : 0.0)
                    .build();
        } else {
            LocalDate startOfMonth = today.withDayOfMonth(1);
            LocalDate endOfMonth = today.withDayOfMonth(today.lengthOfMonth());
            List<Attendance> attendances = attendanceRepository.findByUserIdAndDateRange(userId, startOfMonth, endOfMonth);
            double actualWorkDays = 0.0;
            int lateDays = 0;
            for (Attendance a : attendances) {
                AttendanceStatus st = a.getStatus();
                if (st == AttendanceStatus.SUFFICIENT || st == AttendanceStatus.ADJUSTED || st == AttendanceStatus.BUSINESS_TRIP) {
                    actualWorkDays += 1.0;
                } else if (st == AttendanceStatus.LATE || st == AttendanceStatus.EARLY || st == AttendanceStatus.LATE_AND_EARLY) {
                    actualWorkDays += 1.0;
                    if (st == AttendanceStatus.LATE || st == AttendanceStatus.LATE_AND_EARLY) {
                        lateDays++;
                    }
                } else if (st == AttendanceStatus.MISSING) {
                    actualWorkDays += 0.5;
                }
            }
            monthlySummary = MonthlySummaryDto.builder()
                    .month(currentMonth)
                    .year(currentYear)
                    .actualWorkDays(actualWorkDays)
                    .lateDays(lateDays)
                    .totalOtHours(0.0)
                    .build();
        }

        // 4. Số dư ngày phép
        int totalAnnualLeave = user.getAnnualLeaveDays();
        int usedLeave = user.getUsedLeaveDays();
        double remainingLeave = Math.max(0.0, totalAnnualLeave - usedLeave);
        LeaveBalanceDto leaveBalance = LeaveBalanceDto.builder()
                .totalAnnualLeave(totalAnnualLeave)
                .usedLeaveDays(usedLeave)
                .remainingLeaveDays(remainingLeave)
                .build();

        // 5. Số lượng đơn chờ duyệt (nếu là cấp duyệt)
        boolean isExecutive = "Executive Leadership".equalsIgnoreCase(deptName);
        boolean isDepartmentHead = jobTitle != null && jobTitle.startsWith("Department Head");
        boolean isHR = "Human Resources".equalsIgnoreCase(deptName);
        boolean isApprover = isExecutive || isDepartmentHead || isHR;

        long pendingLeaves = 0;
        long pendingOTs = 0;

        if (isApprover) {
            UserRole userRole = new UserRole(userId, deptName, jobTitle);
            try {
                LeaveFilterRequest leaveFilter = new LeaveFilterRequest(null, LeaveRequestStatus.pending, null, null, null);
                pendingLeaves = leaveRequestRepository.count(LeaveRequestSpecification.forApprovals(userRole, leaveFilter));

                OvertimeFilterRequest otFilter = new OvertimeFilterRequest();
                otFilter.setStatus("pending");
                pendingOTs = overtimeRecordRepository.count(OvertimeSpecification.forApprovals(userRole, otFilter));
            } catch (Exception ex) {
                log.warn("Lỗi khi đếm số đơn chờ duyệt cho user: {}", userId, ex);
            }
        }

        PendingApprovalsDto pendingApprovals = PendingApprovalsDto.builder()
                .isApprover(isApprover)
                .pendingLeavesCount(pendingLeaves)
                .pendingOvertimesCount(pendingOTs)
                .build();

        return DashboardSummaryResponse.builder()
                .userProfile(userProfile)
                .todayAttendance(todayAttendance)
                .monthlySummary(monthlySummary)
                .leaveBalance(leaveBalance)
                .pendingApprovals(pendingApprovals)
                .build();
    }
}
