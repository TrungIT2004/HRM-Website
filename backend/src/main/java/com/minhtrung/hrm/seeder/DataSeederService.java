package com.minhtrung.hrm.seeder;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.minhtrung.hrm.attendance.entities.Attendance;
import com.minhtrung.hrm.attendance.entities.WorkShift;
import com.minhtrung.hrm.attendance.enums.AttendanceStatus;
import com.minhtrung.hrm.attendance.repositories.AttendanceRepository;
import com.minhtrung.hrm.attendance.repositories.MonthlyTimesheetRepository;
import com.minhtrung.hrm.attendance.repositories.WorkShiftRepository;
import com.minhtrung.hrm.attendance.services.AttendanceService;
import com.minhtrung.hrm.employees.dtos.internals.UserRole;
import com.minhtrung.hrm.employees.entities.Salary;
import com.minhtrung.hrm.employees.entities.User;
import com.minhtrung.hrm.employees.enums.PayFrequency;
import com.minhtrung.hrm.employees.repositories.SalaryRepository;
import com.minhtrung.hrm.employees.repositories.UserRepository;
import com.minhtrung.hrm.leave.entities.LeaveRequest;
import com.minhtrung.hrm.leave.enums.LeaveRequestStatus;
import com.minhtrung.hrm.leave.repositories.LeaveRequestRepository;
import com.minhtrung.hrm.overtime.entities.Holiday;
import com.minhtrung.hrm.overtime.entities.OvertimeRecord;
import com.minhtrung.hrm.overtime.enums.OvertimeRecordStatus;
import com.minhtrung.hrm.overtime.repositories.HolidayRepository;
import com.minhtrung.hrm.overtime.repositories.OvertimeRecordRepository;
import com.minhtrung.hrm.payroll.repositories.MonthlyPayrollSummaryRepository;
import com.minhtrung.hrm.payroll.repositories.PayrollRepository;

import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class DataSeederService {

    private final UserRepository userRepository;
    private final WorkShiftRepository workShiftRepository;
    private final SalaryRepository salaryRepository;
    private final AttendanceRepository attendanceRepository;
    private final LeaveRequestRepository leaveRequestRepository;
    private final OvertimeRecordRepository overtimeRecordRepository;
    private final HolidayRepository holidayRepository;
    private final MonthlyTimesheetRepository monthlyTimesheetRepository;
    private final PayrollRepository payrollRepository;
    private final MonthlyPayrollSummaryRepository monthlyPayrollSummaryRepository;
    private final AttendanceService attendanceService;
    private final jakarta.persistence.EntityManager entityManager;

    public DataSeederService(
            UserRepository userRepository,
            WorkShiftRepository workShiftRepository,
            SalaryRepository salaryRepository,
            AttendanceRepository attendanceRepository,
            LeaveRequestRepository leaveRequestRepository,
            OvertimeRecordRepository overtimeRecordRepository,
            HolidayRepository holidayRepository,
            MonthlyTimesheetRepository monthlyTimesheetRepository,
            PayrollRepository payrollRepository,
            MonthlyPayrollSummaryRepository monthlyPayrollSummaryRepository,
            AttendanceService attendanceService,
            jakarta.persistence.EntityManager entityManager) {
        this.userRepository = userRepository;
        this.workShiftRepository = workShiftRepository;
        this.salaryRepository = salaryRepository;
        this.attendanceRepository = attendanceRepository;
        this.leaveRequestRepository = leaveRequestRepository;
        this.overtimeRecordRepository = overtimeRecordRepository;
        this.holidayRepository = holidayRepository;
        this.monthlyTimesheetRepository = monthlyTimesheetRepository;
        this.payrollRepository = payrollRepository;
        this.monthlyPayrollSummaryRepository = monthlyPayrollSummaryRepository;
        this.attendanceService = attendanceService;
        this.entityManager = entityManager;
    }

    /**
     * Khởi tạo dữ liệu đa dạng mẫu cho năm 2026 (từ tháng fromMonth đến toMonth)
     */
    @Transactional
    public Map<String, Object> seedMockData(int year, int fromMonth, int toMonth, boolean clearExisting, boolean autoGenerateTimesheets) {
        log.info("Bắt đầu khởi tạo dữ liệu mẫu cho năm {} từ tháng {} đến {}...", year, fromMonth, toMonth);

        // 1. Tạo ngày nghỉ lễ luật định năm 2026
        int holidaysCreated = seedVietnameseHolidays(year);

        // 2. Đảm bảo toàn bộ nhân viên có ca làm việc và hợp đồng lương
        int usersReady = ensureUserShiftsAndSalaries();

        LocalDate startDate = LocalDate.of(year, fromMonth, 1);
        LocalDate endDate = LocalDate.of(year, toMonth, 1).with(TemporalAdjusters.lastDayOfMonth());

        // 3. Dọn dẹp dữ liệu cũ trong khoảng thời gian nếu yêu cầu
        if (clearExisting) {
            log.info("Dọn dẹp dữ liệu cũ từ {} đến {}...", startDate, endDate);
            attendanceRepository.deleteByWorkDateBetween(startDate, endDate);
            overtimeRecordRepository.deleteByApprovedDateBetween(startDate, endDate);
            leaveRequestRepository.deleteLeavesBetween(startDate, endDate);
            monthlyTimesheetRepository.deleteByPeriodYearAndPeriodMonthBetween(year, fromMonth, toMonth);
            payrollRepository.deleteByPeriodYearAndPeriodMonthBetween(year, fromMonth, toMonth);
            monthlyPayrollSummaryRepository.deleteByPeriodYearAndPeriodMonthBetween(year, fromMonth, toMonth);

            entityManager.flush();
            entityManager.clear();
        }

        List<User> users = userRepository.findAll();
        if (users.isEmpty()) {
            return Map.of("error", "Không tìm thấy nhân viên nào trong hệ thống");
        }

        // 4. Khởi tạo Đơn nghỉ phép mẫu (LeaveRequests)
        int leaveCount = seedLeaveRequests(users, year, fromMonth, toMonth);

        // 5. Khởi tạo Đơn làm thêm giờ mẫu đa dạng hệ số (OvertimeRecords)
        int otCount = seedOvertimeRecords(users, year, fromMonth, toMonth);

        // 6. Khởi tạo Chấm công hằng ngày đa dạng tình huống (Attendances)
        int attendanceCount = seedDailyAttendances(users, startDate, endDate);

        // 7. Tự động tính toán bảng chấm công tháng nếu được bật
        int generatedTimesheetMonths = 0;
        if (autoGenerateTimesheets) {
            UserRole systemAdminRole = new UserRole(UUID.randomUUID(), "Executive Leadership", "Board Director");
            for (int m = fromMonth; m <= toMonth; m++) {
                try {
                    attendanceService.generateMonthlyTimesheets(m, year, systemAdminRole);
                    // Các tháng trước tháng hiện tại thì tự động khóa sổ (LOCKED), tháng cuối để DRAFT
                    if (m < toMonth) {
                        attendanceService.lockMonthlyTimesheet(m, year, systemAdminRole);
                    }
                    generatedTimesheetMonths++;
                } catch (Exception e) {
                    log.warn("Không thể tự động tính toán bảng công tháng {}/{}: {}", m, year, e.getMessage());
                }
            }
        }

        log.info("Hoàn tất khởi tạo dữ liệu mẫu: {} ngày lễ, {} nhân viên, {} chấm công, {} nghỉ phép, {} OT, {} tháng công",
                holidaysCreated, usersReady, attendanceCount, leaveCount, otCount, generatedTimesheetMonths);

        return Map.of(
                "status", "SUCCESS",
                "message", String.format("Khởi tạo thành công dữ liệu năm %d (Tháng %d - %d)", year, fromMonth, toMonth),
                "totalUsers", users.size(),
                "attendanceRecordsCreated", attendanceCount,
                "leaveRequestsCreated", leaveCount,
                "overtimeRecordsCreated", otCount,
                "timesheetMonthsProcessed", generatedTimesheetMonths,
                "note", String.format("Tháng %d đến %d đã khóa sổ (LOCKED), Tháng %d đang ở trạng thái DRAFT để kiểm thử",
                        fromMonth, Math.max(fromMonth, toMonth - 1), toMonth)
        );
    }

    private int seedVietnameseHolidays(int year) {
        List<Holiday> holidays = new ArrayList<>();

        addHolidayIfMissing(holidays, LocalDate.of(year, 1, 1), "Tết Dương Lịch");
        addHolidayIfMissing(holidays, LocalDate.of(year, 2, 16), "Nghỉ Tết Nguyên Đán (29 Tết)");
        addHolidayIfMissing(holidays, LocalDate.of(year, 2, 17), "Mùng 1 Tết Bính Ngọ");
        addHolidayIfMissing(holidays, LocalDate.of(year, 2, 18), "Mùng 2 Tết Bính Ngọ");
        addHolidayIfMissing(holidays, LocalDate.of(year, 2, 19), "Mùng 3 Tết Bính Ngọ");
        addHolidayIfMissing(holidays, LocalDate.of(year, 2, 20), "Mùng 4 Tết Bính Ngọ");
        addHolidayIfMissing(holidays, LocalDate.of(year, 4, 26), "Giỗ Tổ Hùng Vương");
        addHolidayIfMissing(holidays, LocalDate.of(year, 4, 30), "Ngày Chiến thắng (30/4)");
        addHolidayIfMissing(holidays, LocalDate.of(year, 5, 1), "Ngày Quốc tế Lao động (1/5)");
        addHolidayIfMissing(holidays, LocalDate.of(year, 9, 2), "Quốc khánh (2/9)");
        addHolidayIfMissing(holidays, LocalDate.of(year, 9, 3), "Nghỉ liền kề Quốc khánh (3/9)");

        if (!holidays.isEmpty()) {
            holidayRepository.saveAll(holidays);
        }
        return holidays.size();
    }

    private void addHolidayIfMissing(List<Holiday> list, LocalDate date, String desc) {
        if (!holidayRepository.existsByDate(date)) {
            Holiday h = new Holiday();
            h.setDate(date);
            h.setDescription(desc);
            list.add(h);
        }
    }

    private int ensureUserShiftsAndSalaries() {
        List<User> users = userRepository.findAll();
        List<WorkShift> shifts = workShiftRepository.findAll();
        WorkShift defaultShift = shifts.isEmpty() ? null : shifts.get(0);

        int count = 0;
        for (User user : users) {
            // Gán ca làm việc nếu chưa có
            if (user.getShift() == null && defaultShift != null) {
                user.setShift(defaultShift);
                userRepository.save(user);
            }

            // Gán hợp đồng lương nếu chưa có
            if (salaryRepository.findByUser_UserIdAndIsActiveTrue(user.getUserId()).isEmpty()) {
                double baseSalary = 15_000_000.0;
                String job = user.getJob() != null ? user.getJob().getTitle() : "";
                String dept = user.getDepartment() != null ? user.getDepartment().getName() : "";

                if ("Executive Leadership".equals(dept) || job.contains("Head") || job.contains("Manager") || job.contains("Trưởng")) {
                    baseSalary = 35_000_000.0;
                } else if (job.contains("Engineer") || job.contains("Specialist") || job.contains("Accountant")) {
                    baseSalary = 22_000_000.0;
                } else {
                    baseSalary = 16_500_000.0;
                }

                Salary s = new Salary();
                s.setUser(user);
                s.setBaseSalary(baseSalary);
                s.setWorkDays(22.0);
                s.setPayFrequency(PayFrequency.MONTHLY);
                s.setStartDate(LocalDate.of(2025, 1, 1));
                s.setActive(true);
                salaryRepository.save(s);
            }
            count++;
        }
        return count;
    }

    private int seedLeaveRequests(List<User> users, int year, int fromMonth, int toMonth) {
        List<LeaveRequest> leaveList = new ArrayList<>();

        for (int m = fromMonth; m <= toMonth; m++) {
            for (int i = 0; i < users.size(); i++) {
                User u = users.get(i);
                // Mỗi tháng có khoảng 1-2 nhân viên xin nghỉ phép
                if ((u.getUserId().hashCode() + m) % 5 == 0) {
                    LocalDate fromDate = LocalDate.of(year, m, 8 + (i % 10));
                    LocalDate toDate = fromDate.plusDays((i % 2 == 0) ? 1 : 0); // nghỉ 1 hoặc 2 ngày

                    LeaveRequest lr = new LeaveRequest();
                    lr.setRequestor(u);
                    lr.setFromDate(fromDate);
                    lr.setToDate(toDate);
                    lr.setStatus(LeaveRequestStatus.accepted);

                    // 80% nghỉ phép có lương, 20% nghỉ việc riêng không lương
                    boolean isPaid = (i % 5 != 0);
                    lr.setPaidLeaveDays(isPaid ? (int) (toDate.toEpochDay() - fromDate.toEpochDay() + 1) : 0);
                    lr.setReason(isPaid ? "Nghỉ phép năm giải quyết việc gia đình" : "Nghỉ việc riêng không hưởng lương");
                    leaveList.add(lr);
                }
            }
        }

        if (!leaveList.isEmpty()) {
            leaveRequestRepository.saveAll(leaveList);
        }
        return leaveList.size();
    }

    private int seedOvertimeRecords(List<User> users, int year, int fromMonth, int toMonth) {
        List<OvertimeRecord> otList = new ArrayList<>();
        java.util.Set<String> processedKeys = new java.util.HashSet<>();

        for (int m = fromMonth; m <= toMonth; m++) {
            LocalDate monthStart = LocalDate.of(year, m, 1);
            LocalDate monthEnd = monthStart.with(TemporalAdjusters.lastDayOfMonth());

            for (int i = 0; i < users.size(); i++) {
                User u = users.get(i);

                // Mỗi nhân viên trong tháng có 2 đến 3 đợt làm thêm giờ với đa dạng hệ số
                // Đợt 1: OT Ngày thường ban ngày (1.5x)
                LocalDate otDate1 = LocalDate.of(year, m, Math.min(6 + (i % 12), monthEnd.getDayOfMonth()));
                if (otDate1.getDayOfWeek() != DayOfWeek.SATURDAY && otDate1.getDayOfWeek() != DayOfWeek.SUNDAY) {
                    String key1 = u.getUserId().toString() + "_" + otDate1;
                    if (processedKeys.add(key1) && !overtimeRecordRepository.existsByRequestor_UserIdAndApprovedDate(u.getUserId(), otDate1)) {
                        OvertimeRecord ot1 = new OvertimeRecord();
                        ot1.setRequestor(u);
                        ot1.setApprovedDate(otDate1);
                        ot1.setApprovedStartTime(LocalDateTime.of(otDate1, LocalTime.of(17, 30)));
                        ot1.setApprovedEndTime(LocalDateTime.of(otDate1, LocalTime.of(20, 0)));
                        ot1.setClockInTime(LocalDateTime.of(otDate1, LocalTime.of(17, 30)));
                        ot1.setClockOutTime(LocalDateTime.of(otDate1, LocalTime.of(20, 0)));
                        ot1.setNightTime(false);
                        ot1.setWeekend(false);
                        ot1.setHoliday(false);
                        ot1.setStatus(OvertimeRecordStatus.accepted);
                        ot1.setReason("Làm thêm giờ hoàn thành báo cáo tiến độ dự án");
                        otList.add(ot1);
                    }
                }

                // Đợt 2: OT Cuối tuần ban ngày (2.0x)
                LocalDate otDate2 = LocalDate.of(year, m, Math.min(15 + (i % 10), monthEnd.getDayOfMonth()));
                // Tìm ngày Thứ 7 gần nhất
                while (otDate2.getDayOfWeek() != DayOfWeek.SATURDAY && otDate2.isBefore(monthEnd)) {
                    otDate2 = otDate2.plusDays(1);
                }
                if (otDate2.getDayOfWeek() == DayOfWeek.SATURDAY && !otDate2.isAfter(monthEnd)) {
                    String key2 = u.getUserId().toString() + "_" + otDate2;
                    if (processedKeys.add(key2) && !overtimeRecordRepository.existsByRequestor_UserIdAndApprovedDate(u.getUserId(), otDate2)) {
                        OvertimeRecord ot2 = new OvertimeRecord();
                        ot2.setRequestor(u);
                        ot2.setApprovedDate(otDate2);
                        ot2.setApprovedStartTime(LocalDateTime.of(otDate2, LocalTime.of(8, 30)));
                        ot2.setApprovedEndTime(LocalDateTime.of(otDate2, LocalTime.of(12, 30)));
                        ot2.setClockInTime(LocalDateTime.of(otDate2, LocalTime.of(8, 30)));
                        ot2.setClockOutTime(LocalDateTime.of(otDate2, LocalTime.of(12, 30)));
                        ot2.setNightTime(false);
                        ot2.setWeekend(true);
                        ot2.setHoliday(false);
                        ot2.setStatus(OvertimeRecordStatus.accepted);
                        ot2.setReason("Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần");
                        otList.add(ot2);
                    }
                }

                // Đợt 3: OT Ngày thường ban đêm (2.0x) cho một số nhân viên
                if (i % 3 == 0) {
                    LocalDate otDate3 = LocalDate.of(year, m, Math.min(22 + (i % 5), monthEnd.getDayOfMonth()));
                    if (otDate3.getDayOfWeek() != DayOfWeek.SATURDAY && otDate3.getDayOfWeek() != DayOfWeek.SUNDAY) {
                        String key3 = u.getUserId().toString() + "_" + otDate3;
                        if (processedKeys.add(key3) && !overtimeRecordRepository.existsByRequestor_UserIdAndApprovedDate(u.getUserId(), otDate3)) {
                            OvertimeRecord ot3 = new OvertimeRecord();
                            ot3.setRequestor(u);
                            ot3.setApprovedDate(otDate3);
                            ot3.setApprovedStartTime(LocalDateTime.of(otDate3, LocalTime.of(22, 0)));
                            ot3.setApprovedEndTime(LocalDateTime.of(otDate3.plusDays(1), LocalTime.of(1, 0)));
                            ot3.setClockInTime(LocalDateTime.of(otDate3, LocalTime.of(22, 0)));
                            ot3.setClockOutTime(LocalDateTime.of(otDate3.plusDays(1), LocalTime.of(1, 0)));
                            ot3.setNightTime(true);
                            ot3.setWeekend(false);
                            ot3.setHoliday(false);
                            ot3.setStatus(OvertimeRecordStatus.accepted);
                            ot3.setReason("Xử lý sự cố máy chủ ban đêm");
                            otList.add(ot3);
                        }
                    }
                }
            }
        }

        if (!otList.isEmpty()) {
            overtimeRecordRepository.saveAll(otList);
            overtimeRecordRepository.flush();
        }
        return otList.size();
    }

    private int seedDailyAttendances(List<User> users, LocalDate startDate, LocalDate endDate) {
        List<Attendance> batch = new ArrayList<>();

        for (LocalDate d = startDate; !d.isAfter(endDate); d = d.plusDays(1)) {
            boolean isHoliday = holidayRepository.existsByDate(d);

            for (User u : users) {
                WorkShift shift = u.getShift();
                if (shift == null) continue;

                boolean isWorkDay = attendanceService.isWorkingDay(shift.getShiftId(), d.getDayOfWeek());

                // Nếu là ngày lễ
                if (isHoliday) {
                    Attendance att = new Attendance();
                    att.setUser(u);
                    att.setShift(shift);
                    att.setWorkDate(d);
                    att.setStatus(AttendanceStatus.HOLIDAY);
                    batch.add(att);
                    continue;
                }

                // Nếu là ngày nghỉ hàng tuần bình thường (Thứ 7 / Chủ nhật)
                if (!isWorkDay) {
                    continue; // Không tạo record ngày nghỉ thường
                }

                // Kiểm tra xem ngày này nhân viên có đơn nghỉ phép không
                boolean onLeave = leaveRequestRepository.existsOverlappingLeaveRequest(
                        u.getUserId(), d, d, List.of(LeaveRequestStatus.accepted));

                if (onLeave) {
                    Attendance att = new Attendance();
                    att.setUser(u);
                    att.setShift(shift);
                    att.setWorkDate(d);
                    att.setStatus(AttendanceStatus.PAID_LEAVE);
                    batch.add(att);
                    continue;
                }

                // Tạo các tình huống chấm công thực tế đa dạng dựa trên hash xác định
                int hash = Math.abs((u.getUserId().toString() + d.toString()).hashCode()) % 100;

                Attendance att = new Attendance();
                att.setUser(u);
                att.setShift(shift);
                att.setWorkDate(d);

                if (hash < 76) {
                    // 76% Đi làm đầy đủ đúng giờ
                    att.setStatus(AttendanceStatus.SUFFICIENT);
                    att.setClockInTime(LocalTime.of(7, 48 + (hash % 10)));
                    att.setClockOutTime(LocalTime.of(17, 5 + (hash % 20)));
                } else if (hash < 84) {
                    // 8% Đi muộn (15 - 40 phút)
                    att.setStatus(AttendanceStatus.LATE);
                    att.setClockInTime(LocalTime.of(8, 15 + (hash % 25)));
                    att.setClockOutTime(LocalTime.of(17, 10 + (hash % 15)));
                } else if (hash < 89) {
                    // 5% Về sớm (15 - 30 phút)
                    att.setStatus(AttendanceStatus.EARLY);
                    att.setClockInTime(LocalTime.of(7, 52));
                    att.setClockOutTime(LocalTime.of(16, 30 + (hash % 15)));
                } else if (hash < 92) {
                    // 3% Cả đi muộn và về sớm
                    att.setStatus(AttendanceStatus.LATE_AND_EARLY);
                    att.setClockInTime(LocalTime.of(8, 20));
                    att.setClockOutTime(LocalTime.of(16, 35));
                } else if (hash < 96) {
                    // 4% Quên quẹt ra (MISSING) -> Kiểm tra tính 0.5 ngày công!
                    att.setStatus(AttendanceStatus.MISSING);
                    att.setClockInTime(LocalTime.of(7, 50));
                    att.setClockOutTime(null);
                } else if (hash < 98) {
                    // 2% Đi công tác (BUSINESS_TRIP)
                    att.setStatus(AttendanceStatus.BUSINESS_TRIP);
                } else {
                    // 2% Nghỉ không phép (UNEXCUSED_ABSENCE) -> Kiểm tra tính absentDays!
                    att.setStatus(AttendanceStatus.UNEXCUSED_ABSENCE);
                }

                batch.add(att);
            }

            // Lưu theo từng đợt để tối ưu bộ nhớ
            if (batch.size() >= 500) {
                attendanceRepository.saveAll(batch);
                batch.clear();
            }
        }

        if (!batch.isEmpty()) {
            attendanceRepository.saveAll(batch);
        }

        return (int) attendanceRepository.count();
    }
}
