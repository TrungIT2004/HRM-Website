package com.minhtrung.hrm.attendance.services;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.minhtrung.hrm.attendance.dtos.response.AttendanceOverviewResponse;
import com.minhtrung.hrm.attendance.dtos.response.AttendanceOverviewResponse.DeptLeaveDto;
import com.minhtrung.hrm.attendance.dtos.response.AttendanceOverviewResponse.LeaveTypeDto;
import com.minhtrung.hrm.attendance.dtos.response.AttendanceOverviewResponse.OtDeptDto;
import com.minhtrung.hrm.attendance.dtos.response.AttendanceOverviewResponse.TopAbsenteeDto;
import com.minhtrung.hrm.attendance.dtos.response.AttendanceOverviewResponse.TopOtDto;
import com.minhtrung.hrm.attendance.dtos.response.AttendanceOverviewResponse.WeeklyPointDto;
import com.minhtrung.hrm.attendance.entities.Attendance;
import com.minhtrung.hrm.attendance.enums.AttendanceErrorCode;
import com.minhtrung.hrm.attendance.enums.AttendanceStatus;
import com.minhtrung.hrm.attendance.exceptions.AttendanceException;
import com.minhtrung.hrm.attendance.repositories.AttendanceRepository;
import com.minhtrung.hrm.attendance.services.AttendanceService;
import com.minhtrung.hrm.employees.dtos.internals.UserRole;
import com.minhtrung.hrm.leave.enums.LeaveRequestStatus;
import com.minhtrung.hrm.leave.repositories.LeaveRequestRepository;
import com.minhtrung.hrm.overtime.entities.OvertimeRecord;
import com.minhtrung.hrm.overtime.enums.OvertimeRecordStatus;
import com.minhtrung.hrm.overtime.repositories.OvertimeRecordRepository;
import com.minhtrung.hrm.permissions.enums.PermissionKey;
import com.minhtrung.hrm.permissions.services.PermissionService;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class AttendanceOverviewService {

    private final AttendanceRepository attendanceRepository;
    private final LeaveRequestRepository leaveRequestRepository;
    private final OvertimeRecordRepository overtimeRecordRepository;
    private final PermissionService permissionService;

    private static String requestorDeptName(com.minhtrung.hrm.leave.entities.LeaveRequest lr) {
        var r = lr.getRequestor();
        return r != null && r.getDepartment() != null ? r.getDepartment().getName() : "Chưa phân phòng";
    }

    // scope="dept": chỉ tổng hợp phòng của người gọi (phòng lấy từ token, không từ param).
    @Transactional(readOnly = true)
    public AttendanceOverviewResponse getOverview(LocalDate startDate, LocalDate endDate, UserRole userRole, String scope) {
        final String deptFilter;
        if ("dept".equalsIgnoreCase(scope)) {
            String myDept = userRole.getDepartment() != null ? userRole.getDepartment() : "";
            String myJob = userRole.getJob() != null ? userRole.getJob() : "";
            java.util.UUID uid = userRole.getUserId();
            boolean ok = "Executive Leadership".equals(myDept) || "Human Resources".equals(myDept)
                    || myJob.startsWith("Department Head")
                    || permissionService.hasPermission(uid, PermissionKey.ATTENDANCE_VIEW_DEPT)
                    || permissionService.hasPermission(uid, PermissionKey.LEAVE_VIEW_DEPT)
                    || permissionService.hasPermission(uid, PermissionKey.OVERTIME_VIEW_DEPT);
            if (!ok || myDept.isBlank()) {
                throw new AttendanceException(AttendanceErrorCode.INSUFFICIENT_PERMISSION,
                        "Bạn không có quyền xem tổng quan phòng ban");
            }
            deptFilter = myDept;
        } else {
            deptFilter = null;
        }
        LocalDate today = LocalDate.now();
        // ponytail: không truyền kỳ = kỳ của bản ghi mới nhất (đầu tháng chưa có công mà mặc định
        // tháng hiện tại thì toàn số 0). Có param thì tôn trọng param.
        LocalDate start = startDate;
        LocalDate end = endDate;
        if (start == null || end == null) {
            LocalDate latest = attendanceRepository.findMaxCheckedWorkDate().orElse(today);
            start = latest.withDayOfMonth(1);
            end = latest.withDayOfMonth(latest.lengthOfMonth());
        }
        if (end.isBefore(start)) {
            LocalDate tmp = start;
            start = end;
            end = tmp;
        }

        List<Attendance> rows = attendanceRepository.findAllByWorkDateBetween(start, end);
        if (deptFilter != null) {
            rows = rows.stream()
                    .filter(a -> a.getUser() != null && deptFilter.equals(
                            a.getUser().getDepartment() != null ? a.getUser().getDepartment().getName() : null))
                    .toList();
        }

        long lateEarly = rows.stream()
                .filter(a -> a.getStatus() == AttendanceStatus.LATE
                        || a.getStatus() == AttendanceStatus.EARLY
                        || a.getStatus() == AttendanceStatus.LATE_AND_EARLY)
                .count();
        // Tách muộn / sớm (LATE_AND_EARLY tính cho cả hai) + tổng ngày công toàn công ty.
        // Đúng giờ ở đây = SUFFICIENT (điểm danh đúng khung ca, không điều chỉnh/công tác).
        long lateCount = rows.stream()
                .filter(a -> a.getStatus() == AttendanceStatus.LATE
                        || a.getStatus() == AttendanceStatus.LATE_AND_EARLY)
                .count();
        long earlyCount = rows.stream()
                .filter(a -> a.getStatus() == AttendanceStatus.EARLY
                        || a.getStatus() == AttendanceStatus.LATE_AND_EARLY)
                .count();
        long onTimeCount = rows.stream()
                .filter(a -> a.getStatus() == AttendanceStatus.SUFFICIENT)
                .count();
        // Cơ cấu 6 trạng thái chấm công cho donut + top quên chấm công (HR rà soát trước chốt sổ).
        java.util.Map<String, Long> statusCounts = rows.stream()
                .filter(a -> a.getStatus() != null)
                .collect(Collectors.groupingBy(a -> a.getStatus().name(), Collectors.counting()));
        java.util.Map<java.util.UUID, Long> missingUserCounts = new java.util.HashMap<>();
        java.util.Map<java.util.UUID, String> missingUserName = new java.util.HashMap<>();
        java.util.Map<java.util.UUID, String> missingUserDept = new java.util.HashMap<>();
        for (Attendance a : rows) {
            if (a.getStatus() != AttendanceStatus.MISSING) continue;
            var u = a.getUser();
            if (u == null || u.getUserId() == null) continue;
            missingUserCounts.merge(u.getUserId(), 1L, Long::sum);
            missingUserName.putIfAbsent(u.getUserId(), (u.getFirstName() + " " + u.getLastName()).trim());
            missingUserDept.putIfAbsent(u.getUserId(),
                    u.getDepartment() != null ? u.getDepartment().getName() : "Chưa phân phòng");
        }
        List<TopAbsenteeDto> missingTop = missingUserCounts.entrySet().stream()
                .map(e -> TopAbsenteeDto.builder()
                        .userId(e.getKey())
                        .fullName(missingUserName.getOrDefault(e.getKey(), "Không rõ"))
                        .department(missingUserDept.getOrDefault(e.getKey(), "Chưa phân phòng"))
                        .days(e.getValue().doubleValue())
                        .build())
                .sorted(Comparator.comparingDouble(TopAbsenteeDto::getDays).reversed())
                .limit(7)
                .toList();
        // ponytail: MISSING tính 0.5 công (cùng luật DashboardService) — tổng lẻ .5 là đúng, không phải bug
        double totalWorkDays = Math.round((rows.stream()
                .filter(a -> a.getStatus() == AttendanceStatus.SUFFICIENT
                        || a.getStatus() == AttendanceStatus.ADJUSTED
                        || a.getStatus() == AttendanceStatus.BUSINESS_TRIP
                        || a.getStatus() == AttendanceStatus.LATE
                        || a.getStatus() == AttendanceStatus.EARLY
                        || a.getStatus() == AttendanceStatus.LATE_AND_EARLY)
                .count()
                + rows.stream().filter(a -> a.getStatus() == AttendanceStatus.MISSING).count() * 0.5) * 10.0) / 10.0;

        // Nguồn sự thật cho ngày nghỉ: đơn accepted (LeaveService đã sinh bản ghi PAID/UNPAID
        // từ đơn nên KHÔNG đếm lại 2 trạng thái đó ở attendances) + các bản ghi MISSING/UNEXCUSED
        // không có đơn + BUSINESS_TRIP (chỉ hiện ở donut, không tính là nghỉ).
        // ponytail: gom trong Java, bảng đơn nhỏ (< 1k). GROUP BY ở DB khi vượt ~100k rows/kỳ.
        LocalDate rangeStart = start;
        LocalDate rangeEnd = end;
        java.util.Map<String, Long> deptDays = new java.util.HashMap<>();
        java.util.Map<java.util.UUID, Long> userDays = new java.util.HashMap<>();
        java.util.Map<java.util.UUID, String> userName = new java.util.HashMap<>();
        java.util.Map<java.util.UUID, String> userDept = new java.util.HashMap<>();
        java.util.Map<LocalDate, Long> dayHits = new java.util.HashMap<>();
        long paidDays = 0;
        long unpaidDays = 0;
        long leaveApproved = 0;
        long leaveRejected = 0;

        for (com.minhtrung.hrm.leave.entities.LeaveRequest lr : leaveRequestRepository.findAll()) {
            if (lr.getFromDate() == null || lr.getToDate() == null) continue;
            if (deptFilter != null && !deptFilter.equals(requestorDeptName(lr))) continue;
            boolean overlaps = !lr.getToDate().isBefore(rangeStart) && !lr.getFromDate().isAfter(rangeEnd);
            // Đếm số đơn (mọi trạng thái duyệt/từ chối) giao kỳ — đặt trước nhánh accepted
            if (overlaps) {
                if (lr.getStatus() == LeaveRequestStatus.accepted) leaveApproved++;
                else if (lr.getStatus() == LeaveRequestStatus.rejected) leaveRejected++;
            }
            if (lr.getStatus() != LeaveRequestStatus.accepted) continue;
            LocalDate oStart = lr.getFromDate().isBefore(rangeStart) ? rangeStart : lr.getFromDate();
            LocalDate oEnd = lr.getToDate().isAfter(rangeEnd) ? rangeEnd : lr.getToDate();
            if (oEnd.isBefore(oStart)) continue;
            long totalReq = java.time.temporal.ChronoUnit.DAYS.between(lr.getFromDate(), lr.getToDate()) + 1;
            long overlap = java.time.temporal.ChronoUnit.DAYS.between(oStart, oEnd) + 1;
            long paidOverlap = totalReq > 0
                    ? Math.min(overlap, Math.round(lr.getPaidLeaveDays() * (overlap * 1.0 / totalReq)))
                    : 0;
            paidDays += paidOverlap;
            unpaidDays += overlap - paidOverlap;
            var req = lr.getRequestor();
            String dept = req != null && req.getDepartment() != null ? req.getDepartment().getName() : "Chưa phân phòng";
            deptDays.merge(dept, overlap, Long::sum);
            if (req != null && req.getUserId() != null) {
                userDays.merge(req.getUserId(), overlap, Long::sum);
                userName.putIfAbsent(req.getUserId(), (req.getFirstName() + " " + req.getLastName()).trim());
                userDept.putIfAbsent(req.getUserId(), dept);
            }
            for (LocalDate d = oStart; !d.isAfter(oEnd); d = d.plusDays(1)) {
                dayHits.merge(d, 1L, Long::sum);
            }
        }

        long missing = 0;
        long unexcused = 0;
        long business = 0;
        for (Attendance a : rows) {
            AttendanceStatus st = a.getStatus();
            if (st != AttendanceStatus.MISSING && st != AttendanceStatus.UNEXCUSED_ABSENCE
                    && st != AttendanceStatus.BUSINESS_TRIP) continue;
            if (st == AttendanceStatus.MISSING) missing++;
            else if (st == AttendanceStatus.UNEXCUSED_ABSENCE) unexcused++;
            else business++;
            if (st == AttendanceStatus.BUSINESS_TRIP || a.getWorkDate() == null) continue;
            dayHits.merge(a.getWorkDate(), 1L, Long::sum);
            var u = a.getUser();
            String dept = u != null && u.getDepartment() != null ? u.getDepartment().getName() : "Chưa phân phòng";
            deptDays.merge(dept, 1L, Long::sum);
            if (u != null && u.getUserId() != null) {
                userDays.merge(u.getUserId(), 1L, Long::sum);
                userName.putIfAbsent(u.getUserId(), (u.getFirstName() + " " + u.getLastName()).trim());
                userDept.putIfAbsent(u.getUserId(), dept);
            }
        }

        long actualLeave = paidDays + unpaidDays + missing + unexcused;

        // Đơn chờ duyệt giao với kỳ = kế hoạch nghỉ.
        long planned = leaveRequestRepository.findAll().stream()
                .filter(lr -> lr.getStatus() == LeaveRequestStatus.pending
                        && lr.getToDate() != null && !lr.getToDate().isBefore(rangeStart)
                        && lr.getFromDate() != null && !lr.getFromDate().isAfter(rangeEnd)
                        && (deptFilter == null || deptFilter.equals(requestorDeptName(lr))))
                .count();

        // Nghỉ theo phòng ban (ngày nghỉ từ đơn duyệt + quên/vắng không đơn).
        List<DeptLeaveDto> leaveByDept = deptDays.entrySet().stream()
                .sorted(Map.Entry.<String, Long>comparingByValue(Comparator.reverseOrder()))
                .limit(10)
                .map(e -> DeptLeaveDto.builder().department(e.getKey()).days(e.getValue()).build())
                .toList();

        // Xu hướng theo tuần (bucket 7 ngày từ start, đếm ngày nghỉ thật).
        List<WeeklyPointDto> weekly = new ArrayList<>();
        LocalDate cursor = start;
        int weekIdx = 1;
        while (!cursor.isAfter(end)) {
            LocalDate weekEnd = cursor.plusDays(6).isAfter(end) ? end : cursor.plusDays(6);
            long days = 0;
            for (LocalDate d = cursor; !d.isAfter(weekEnd); d = d.plusDays(1)) {
                days += dayHits.getOrDefault(d, 0L);
            }
            weekly.add(WeeklyPointDto.builder().label("Tuần " + weekIdx++).days(days).build());
            cursor = weekEnd.plusDays(1);
        }

        // Loại nghỉ: có lương/không lương từ đơn duyệt + quên/vắng/công tác từ chấm công.
        Map<String, Long> typeCounts = new LinkedHashMap<>();
        typeCounts.put("Nghỉ phép có lương", paidDays);
        typeCounts.put("Nghỉ không lương", unpaidDays);
        typeCounts.put("Quên chấm công", missing);
        typeCounts.put("Vắng không phép", unexcused);
        typeCounts.put("Công tác", business);
        long typeTotal = typeCounts.values().stream().mapToLong(Long::longValue).sum();
        List<LeaveTypeDto> leaveTypes = typeCounts.entrySet().stream()
                .map(e -> LeaveTypeDto.builder()
                        .label(e.getKey())
                        .count(e.getValue())
                        .percent(typeTotal > 0 ? Math.round(e.getValue() * 1000.0 / typeTotal) / 10.0 : 0.0)
                        .build())
                .toList();

        // Top nghỉ nhiều nhất (ngày nghỉ từ đơn duyệt + quên/vắng không đơn).
        List<TopAbsenteeDto> top = userDays.entrySet().stream()
                .map(e -> TopAbsenteeDto.builder()
                        .userId(e.getKey())
                        .fullName(userName.getOrDefault(e.getKey(), "Không rõ"))
                        .department(userDept.getOrDefault(e.getKey(), "Chưa phân phòng"))
                        .days(e.getValue().doubleValue())
                        .build())
                .sorted(Comparator.comparingDouble(TopAbsenteeDto::getDays).reversed())
                .limit(7)
                .toList();

        // Đi muộn theo phòng ban + theo tuần (từ cùng rows đã fetch).
        java.util.function.Predicate<Attendance> isLate = a ->
                a.getStatus() == AttendanceStatus.LATE
                        || a.getStatus() == AttendanceStatus.EARLY
                        || a.getStatus() == AttendanceStatus.LATE_AND_EARLY;
        List<DeptLeaveDto> lateByDept = rows.stream()
                .filter(isLate)
                .collect(Collectors.groupingBy(
                        a -> a.getUser() != null && a.getUser().getDepartment() != null
                                ? a.getUser().getDepartment().getName()
                                : "Chưa phân phòng",
                        Collectors.counting()))
                .entrySet().stream()
                .sorted(Map.Entry.<String, Long>comparingByValue(Comparator.reverseOrder()))
                .limit(10)
                .map(e -> DeptLeaveDto.builder().department(e.getKey()).days(e.getValue()).build())
                .toList();
        List<WeeklyPointDto> lateTrend = new ArrayList<>();
        {
            LocalDate c = start;
            int wi = 1;
            while (!c.isAfter(end)) {
                LocalDate we = c.plusDays(6).isAfter(end) ? end : c.plusDays(6);
                long n = 0;
                for (Attendance a : rows) {
                    if (a.getWorkDate() != null && !a.getWorkDate().isBefore(c)
                            && !a.getWorkDate().isAfter(we) && isLate.test(a)) n++;
                }
                lateTrend.add(WeeklyPointDto.builder().label("Tuần " + wi++).days(n).build());
                c = we.plusDays(1);
            }
        }

        // OT toàn công ty: đơn accepted giao kỳ, giờ thực tế theo đúng luật hệ số.
        // ponytail: full scan bảng OT trong Java (vài trăm dòng). GROUP BY ở DB khi vượt ~100k/kỳ.
        java.util.Map<String, Double> otDeptHours = new java.util.HashMap<>();
        java.util.Map<java.util.UUID, Double> otUserHours = new java.util.HashMap<>();
        java.util.Map<java.util.UUID, String> otUserName = new java.util.HashMap<>();
        java.util.Map<java.util.UUID, String> otUserDept = new java.util.HashMap<>();
        double otTotal = 0.0;
        long otSubmitted = 0;
        long otApproved = 0;
        long otRejected = 0;
        java.util.Map<LocalDate, Double> otDayHours = new java.util.HashMap<>();
        for (OvertimeRecord ot : overtimeRecordRepository.findAll()) {
            if (ot.getApprovedDate() == null || ot.getApprovedDate().isBefore(rangeStart)
                    || ot.getApprovedDate().isAfter(rangeEnd)) continue;
            var otReq = ot.getRequestor();
            String otDept = otReq != null && otReq.getDepartment() != null ? otReq.getDepartment().getName() : "Chưa phân phòng";
            if (deptFilter != null && !deptFilter.equals(otDept)) continue;
            otSubmitted++;
            if (ot.getStatus() == OvertimeRecordStatus.accepted) otApproved++;
            else if (ot.getStatus() == OvertimeRecordStatus.rejected) otRejected++;
            else continue;
            double h = AttendanceService.calcOvertimeAmounts(ot).actualHours().doubleValue();
            if (h <= 0) continue;
            otTotal += h;
            otDayHours.merge(ot.getApprovedDate(), h, Double::sum);
            var req = ot.getRequestor();
            String dept = req != null && req.getDepartment() != null ? req.getDepartment().getName() : "Chưa phân phòng";
            otDeptHours.merge(dept, h, Double::sum);
            if (req != null && req.getUserId() != null) {
                otUserHours.merge(req.getUserId(), h, Double::sum);
                otUserName.putIfAbsent(req.getUserId(), (req.getFirstName() + " " + req.getLastName()).trim());
                otUserDept.putIfAbsent(req.getUserId(), dept);
            }
        }
        otTotal = Math.round(otTotal * 10.0) / 10.0;
        List<OtDeptDto> otByDept = otDeptHours.entrySet().stream()
                .sorted(Map.Entry.<String, Double>comparingByValue(Comparator.reverseOrder()))
                .limit(10)
                .map(e -> OtDeptDto.builder()
                        .department(e.getKey())
                        .hours(Math.round(e.getValue() * 10.0) / 10.0)
                        .build())
                .toList();
        List<TopOtDto> topOt = otUserHours.entrySet().stream()
                .map(e -> TopOtDto.builder()
                        .userId(e.getKey())
                        .fullName(otUserName.getOrDefault(e.getKey(), "Không rõ"))
                        .department(otUserDept.getOrDefault(e.getKey(), "Chưa phân phòng"))
                        .hours(Math.round(e.getValue() * 10.0) / 10.0)
                        .build())
                .sorted(Comparator.comparingDouble(TopOtDto::getHours).reversed())
                .limit(7)
                .toList();
        List<WeeklyPointDto> otTrend = new ArrayList<>();
        {
            LocalDate c = start;
            int wi = 1;
            while (!c.isAfter(end)) {
                LocalDate we = c.plusDays(6).isAfter(end) ? end : c.plusDays(6);
                double hh = 0.0;
                for (LocalDate d = c; !d.isAfter(we); d = d.plusDays(1)) {
                    hh += otDayHours.getOrDefault(d, 0.0);
                }
                otTrend.add(WeeklyPointDto.builder().label("Tuần " + wi++).days(Math.round(hh)).build());
                c = we.plusDays(1);
            }
        }

        return AttendanceOverviewResponse.builder()
                .periodStart(start)
                .periodEnd(end)
                .lateEarlyCount(lateEarly)
                .actualLeaveCount(actualLeave)
                .plannedLeaveCount(planned)
                .leaveByDept(leaveByDept)
                .weeklyTrend(weekly)
                .leaveTypes(leaveTypes)
                .topAbsentees(top)
                .totalLeaveDays(actualLeave)
                .otTotalHours(otTotal)
                .otByDept(otByDept)
                .topOt(topOt)
                .lateByDept(lateByDept)
                .lateTrend(lateTrend)
                .otSubmitted(otSubmitted)
                .otApproved(otApproved)
                .otRejected(otRejected)
                .otTrend(otTrend)
                .leaveApproved(leaveApproved)
                .leaveRejected(leaveRejected)
                .totalWorkDays(totalWorkDays)
                .lateCount(lateCount)
                .earlyCount(earlyCount)
                .onTimeCount(onTimeCount)
                .statusCounts(statusCounts)
                .missingTop(missingTop)
                .build();
    }
}
