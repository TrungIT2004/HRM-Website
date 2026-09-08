package com.minhtrung.social_app.attendance.services;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.DayOfWeek;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.TemporalAdjusters;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import javax.management.RuntimeErrorException;

import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.FillPatternType;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.HorizontalAlignment;
import org.apache.poi.ss.usermodel.IndexedColors;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.minhtrung.social_app.attendance.dtos.requests.AttendanceFilterRequest;
import com.minhtrung.social_app.attendance.dtos.requests.CompanyTimesheetFilterRequest;
import com.minhtrung.social_app.attendance.dtos.requests.EditAttendanceRequest;
import com.minhtrung.social_app.attendance.dtos.requests.ManagerTimesheetFilterRequest;
import com.minhtrung.social_app.attendance.dtos.requests.MonthlyTimesheetEditRequest;
import com.minhtrung.social_app.attendance.dtos.requests.StaffTimesheetFilterRequest;
import com.minhtrung.social_app.attendance.enums.TimesheetStatus;
import com.minhtrung.social_app.attendance.dtos.response.CompanyMonthlyTimesheetResponse;
import com.minhtrung.social_app.attendance.dtos.response.HrAttendanceResponse;
import com.minhtrung.social_app.attendance.dtos.response.ManagerAttendanceResponse;
import com.minhtrung.social_app.attendance.dtos.response.StaffAttendanceResponse;
import com.minhtrung.social_app.attendance.dtos.response.StaffMonthlyTimesheetResponse;
import com.minhtrung.social_app.attendance.entities.Attendance;
import com.minhtrung.social_app.attendance.entities.MonthlyTimesheet;
import com.minhtrung.social_app.attendance.entities.WorkShift;
import com.minhtrung.social_app.attendance.entities.WorkShiftSchedule;
import com.minhtrung.social_app.attendance.enums.AttendanceErrorCode;
import com.minhtrung.social_app.attendance.enums.AttendanceStatus;
import com.minhtrung.social_app.attendance.exceptions.AttendanceException;
import com.minhtrung.social_app.attendance.repositories.AttendanceRepository;
import com.minhtrung.social_app.attendance.repositories.MonthlyTimesheetRepository;
import com.minhtrung.social_app.attendance.repositories.WorkShiftRepository;
import com.minhtrung.social_app.attendance.repositories.WorkShiftScheduleRepository;
import com.minhtrung.social_app.attendance.specifications.AttendanceSpecification;
import com.minhtrung.social_app.attendance.specifications.MonthlyTimesheetSpecification;
import com.minhtrung.social_app.employees.dtos.internals.UserRole;
import com.minhtrung.social_app.employees.entities.User;
import com.minhtrung.social_app.employees.repositories.UserRepository;
import com.minhtrung.social_app.leave.entities.LeaveRequest;
import com.minhtrung.social_app.leave.enums.LeaveRequestStatus;
import com.minhtrung.social_app.leave.repositories.LeaveRequestRepository;
import com.minhtrung.social_app.overtime.entities.OvertimeRecord;
import com.minhtrung.social_app.overtime.enums.OvertimeRecordStatus;
import com.minhtrung.social_app.overtime.repositories.HolidayRepository;
import com.minhtrung.social_app.overtime.repositories.OvertimeRecordRepository;

import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class AttendanceService {
    private final UserRepository userRepository;
    private final AttendanceRepository attendanceRepository;
    private final WorkShiftScheduleRepository workShiftScheduleRepository;
    private final LeaveRequestRepository leaveRequestRepository;
    private final OvertimeRecordRepository overtimeRecordRepository;
    private final HolidayRepository holidayRepository;
    private final WorkShiftRepository workShiftRepository;
    private final MonthlyTimesheetRepository monthlyTimesheetRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public AttendanceService(
            UserRepository userRepository,
            AttendanceRepository attendanceRepository,
            WorkShiftScheduleRepository workShiftScheduleRepository,
            LeaveRequestRepository leaveRequestRepository,
            OvertimeRecordRepository overtimeRecordRepository,
            HolidayRepository holidayRepository,
            WorkShiftRepository workShiftRepository,
            MonthlyTimesheetRepository monthlyTimesheetRepository) {
        this.userRepository = userRepository;
        this.attendanceRepository = attendanceRepository;
        this.workShiftScheduleRepository = workShiftScheduleRepository;
        this.leaveRequestRepository = leaveRequestRepository;
        this.overtimeRecordRepository = overtimeRecordRepository;
        this.holidayRepository = holidayRepository;
        this.workShiftRepository = workShiftRepository;
        this.monthlyTimesheetRepository = monthlyTimesheetRepository;
    }

    @SuppressWarnings("null")
    public boolean isWorkingDay(UUID shiftId, DayOfWeek dayOfWeek) {
        int dayNumber = dayOfWeek.getValue(); // MONDAY=1, ..., SUNDAY=7
        return workShiftScheduleRepository
                .findByWorkShift_ShiftIdAndDayOfWeek(shiftId, dayNumber)
                .map(WorkShiftSchedule::isWorking)
                .orElse(false);
    }


    public void clockIn(Attendance usersTodayAttendance, WorkShift usersWorkShift) {
        LocalTime clockInTime = LocalTime.now();

        usersTodayAttendance.setClockInTime(clockInTime);
        usersTodayAttendance.setStatus(AttendanceStatus.WORKING);
    }

    public void clockOut(Attendance usersTodayAttendance, LocalTime attendancesClockInTime, WorkShift usersWorkShift) {
        LocalTime clockOutTime = LocalTime.now();
        LocalTime startTime = usersWorkShift.getStartTime();
        LocalTime endTime = usersWorkShift.getEndTime();

        boolean sufficientWorkShift = attendancesClockInTime.compareTo(startTime) <= 0 && clockOutTime.compareTo(endTime) >= 0;
        boolean lateWorkShift = attendancesClockInTime.compareTo(startTime) > 0 && clockOutTime.compareTo(endTime) >= 0;
        boolean leaveEarlyWorkShift = attendancesClockInTime.compareTo(startTime) <= 0 && clockOutTime.compareTo(endTime) < 0;
        boolean lateAndLeaveEarlyWorkShift = attendancesClockInTime.compareTo(startTime) > 0 && clockOutTime.compareTo(endTime) < 0; 

        usersTodayAttendance.setClockOutTime(clockOutTime);

        LocalDate workDate = usersTodayAttendance.getWorkDate();
        UUID userId = usersTodayAttendance.getUserId();

        if (sufficientWorkShift) {
            usersTodayAttendance.setStatus(AttendanceStatus.SUFFICIENT);
            log.info("Set attendance's status on {} at {} of user {} to SUFFICIENT", workDate, clockOutTime, userId);
        }
        
        if (lateWorkShift) {
            usersTodayAttendance.setStatus(AttendanceStatus.LATE);
            log.info("Set attendance's status on {} at {} of user {} to LATE", workDate, clockOutTime, userId);
        }
        
        if (leaveEarlyWorkShift) {
            usersTodayAttendance.setStatus(AttendanceStatus.EARLY);
            log.info("Set attendance's status on {} at {} of user {} to EARLY", workDate, clockOutTime, userId);

        }

        if (lateAndLeaveEarlyWorkShift) {
            usersTodayAttendance.setStatus(AttendanceStatus.LATE_AND_EARLY);
            log.info("Set attendance's status on {} at {} of user {} to LATE_AND_EARLY", workDate, clockOutTime, userId);
        }
    }

    @Transactional
    public String checkAttendance(UUID userId) {
        LocalDate today = LocalDate.now();
        LocalTime now = LocalTime.now();
        DayOfWeek dayOfWeek = today.getDayOfWeek();

        WorkShift usersWorkShift = userRepository.getUsersWorkShift(userId).orElseThrow(() -> {
            throw new AttendanceException(AttendanceErrorCode.SHIFT_NOT_FOUND, "Không tìm thấy ca làm việc của nhân viên");
        });

        if (!isWorkingDay(usersWorkShift.getShiftId(), dayOfWeek)) {
            throw new AttendanceException(AttendanceErrorCode.NOT_WORK_DAY, "Hôm nay không phải ngày làm việc của nhân viên");
        }

        Attendance usersTodayAttendance = attendanceRepository.findUsersTodayAttendance(userId, today)
                .orElseThrow(() -> {
                    throw new AttendanceException(AttendanceErrorCode.ATTENDANCE_NOT_FOUND,
                            "Không tìm thấy bản ghi chấm công hôm nay của nhân viên");
                });

        LocalTime attendancesClockInTime = usersTodayAttendance.getClockInTime();
        LocalTime attendancesClockOutTime = usersTodayAttendance.getClockOutTime();

        boolean isClockedInTurn = attendancesClockInTime == null && attendancesClockOutTime == null;
        boolean isClockedOutTurn = attendancesClockInTime != null && attendancesClockOutTime == null;
        boolean isAlreadyClockedOut = attendancesClockInTime != null && attendancesClockOutTime != null;

        if (isClockedInTurn) {
            clockIn(usersTodayAttendance, usersWorkShift);
            log.info("CLOCK_IN thành công. UserId: {}, Ngày: {}, Giờ: {}", userId, today, now);
            return "CHECK_IN";
        } else if (isClockedOutTurn) {
            boolean hasWorkedForAtLeastAmmountOfTime = Duration.between(attendancesClockInTime, now).toMinutes() >= 1;

            if (hasWorkedForAtLeastAmmountOfTime) {
                clockOut(usersTodayAttendance, attendancesClockInTime, usersWorkShift);
                log.info("CLOCK_OUT thành công. UserId: {}, Ngày: {}, Giờ: {}, Thời gian làm việc: {} phút",
                        userId, today, now,
                        Duration.between(attendancesClockInTime, now).toMinutes());
                return "CHECK_OUT";
            }

            if (!hasWorkedForAtLeastAmmountOfTime) {
                throw new AttendanceException(AttendanceErrorCode.INSUFFICIENT_WORK_TIME,
                        "Nhân viên phải làm việc ít nhất 1 giờ");
            }

        } else if (isAlreadyClockedOut) {
            clockOut(usersTodayAttendance, attendancesClockInTime, usersWorkShift);
            log.info("CLOCK_OUT (lần 2 - ghi đè). UserId: {}, Ngày: {}, Giờ: {}", userId, today, now);
            return "CHECK_OUT";
        }

        return "UNKNOWN";
    }
    
    // 1. Lấy dữ liệu chấm công cá nhân
    @Transactional(readOnly = true)
    public Page<StaffAttendanceResponse> getMyAttendances(UUID currentUserId, AttendanceFilterRequest filter, Pageable pageable) {
        Specification<Attendance> spec = AttendanceSpecification.forMyAttendances(currentUserId, filter);
        return attendanceRepository.findAll(spec, pageable).map(this::mapToStaffResponse);
    }

    // 2. Lấy dữ liệu chấm công quản lý cấp dưới (TP IT, TP HR, Giám đốc...)
    @Transactional(readOnly = true)
    public Page<ManagerAttendanceResponse> getDepartmentAttendances(UserRole userRole, AttendanceFilterRequest filter, Pageable pageable) {
        Specification<Attendance> spec = AttendanceSpecification.forManagement(userRole, filter);
        return attendanceRepository.findAll(spec, pageable).map(this::mapToManagerResponse);
    }

    // 3. Lấy dữ liệu chấm công toàn công ty (Dành riêng cho ban HR)
    @Transactional(readOnly = true)
    public Page<HrAttendanceResponse> getCompanyAttendances(UserRole userRole, AttendanceFilterRequest filter, Pageable pageable) {
        String myDepartment = userRole.getDepartment() != null ? userRole.getDepartment() : "";
        if (!myDepartment.equals("Human Resources")) {
            throw new AttendanceException(AttendanceErrorCode.INSUFFICIENT_PERMISSION, "Chỉ phòng Nhân sự mới có quyền xem chấm công toàn công ty");
        }

        Specification<Attendance> spec = AttendanceSpecification.forCompanyWide(filter);
        return attendanceRepository.findAll(spec, pageable).map(this::mapToHrResponse);
    }

    // =================== MAPPING DTOs ===================

    private StaffAttendanceResponse mapToStaffResponse(Attendance att) {
        StaffAttendanceResponse dto = new StaffAttendanceResponse();
        dto.setWorkDate(att.getWorkDate());
        dto.setClockInTime(att.getClockInTime());
        dto.setClockOutTime(att.getClockOutTime());
        dto.setStatus(att.getStatus());
        dto.setEdited(att.isEdited());
        if (att.isEdited() && att.getEditor() != null) {
            dto.setEditedReason(att.getEditedReason());
        }
        return dto;
    }

    private ManagerAttendanceResponse mapToManagerResponse(Attendance att) {
        ManagerAttendanceResponse dto = new ManagerAttendanceResponse();
        dto.setWorkDate(att.getWorkDate());
        dto.setClockInTime(att.getClockInTime());
        dto.setClockOutTime(att.getClockOutTime());
        dto.setStatus(att.getStatus());

        User user = att.getUser();
        if (user != null) {
            dto.setEmployeeCode(user.getEmployeeCode());
            dto.setFullName(user.getFirstName() + " " + user.getLastName());
            if (user.getJob() != null) {
                dto.setJob(user.getJob().getTitle());
            }
        }

        dto.setEdited(att.isEdited() && att.getEditor() != null);
        if (att.isEdited()) {
            dto.setEditedReason(att.getEditedReason());
        }
        return dto;
    }

    private HrAttendanceResponse mapToHrResponse(Attendance att) {
        HrAttendanceResponse dto = new HrAttendanceResponse();
        dto.setAttendanceId(att.getAttendanceId());
        dto.setWorkDate(att.getWorkDate());
        dto.setClockInTime(att.getClockInTime());
        dto.setClockOutTime(att.getClockOutTime());
        dto.setStatus(att.getStatus());

        User user = att.getUser();
        if (user != null) {
            dto.setUserId(user.getUserId());
            dto.setEmployeeCode(user.getEmployeeCode());
            dto.setFullName(user.getFirstName() + " " + user.getLastName());
            if (user.getDepartment() != null) {
                dto.setDepartment(user.getDepartment().getName());
            }
            if (user.getJob() != null) {
                dto.setJob(user.getJob().getTitle());
            }
        }

        dto.setEdited(att.isEdited());
        if (att.isEdited() && att.getEditor() != null) {
            dto.setEditedReason(att.getEditedReason());
            dto.setEditorName(att.getEditor().getFirstName() + " " + att.getEditor().getLastName());
            dto.setEditorEmpCode(att.getEditor().getEmployeeCode());
        }
        return dto;
    }
    
    @Transactional
    public Attendance editAttendanceRecord(UUID attendanceId, UserRole userRole, EditAttendanceRequest request) {
        Attendance attendance = attendanceRepository.findById(attendanceId).orElseThrow(() -> {
            throw new AttendanceException(AttendanceErrorCode.ATTENDANCE_NOT_FOUND, "Không tìm thấy bản ghi chấm công");
        });

        UUID edtiorId = userRole.getUserId();
        String department = userRole.getDepartment();

        LocalTime editedClockInTime = request.getEditedClockInTime();
        LocalTime editedClockOutTime = request.getEditedClockOutTime();
        String edtiedReason = request.getEditedReason();
        AttendanceStatus editedStatus = request.getEditedStatus();

        if (editedClockInTime != null && editedClockOutTime != null) {
            if (editedClockInTime.isAfter(editedClockOutTime)) {
                throw new AttendanceException(AttendanceErrorCode.INVALID_CLOCK_TIME,
                        "Giờ vào phải trước giờ ra");
            }
        }

        if (department.equals("Human Resources")) {
            attendance.setEdited(true);
            attendance.setClockInTime(editedClockInTime);
            attendance.setClockOutTime(editedClockOutTime);
            attendance.setEditedReason(edtiedReason);
            attendance.setStatus(editedStatus);

            User userProxy = userRepository.getReferenceById(edtiorId);
            attendance.setEditor(userProxy);

            attendanceRepository.save(attendance);
            log.warn("Bản ghi chấm công bị chỉnh sửa. HR Editor: {}, Bản ghi ID: {}, Nhân viên: {}, Giờ vào mới: {}, Giờ ra mới: {}, Lý do: {}",
                    edtiorId, attendanceId,
                    attendance.getUser() != null ? attendance.getUser().getUserId() : "N/A",
                    editedClockInTime, editedClockOutTime, edtiedReason);
            return attendance;
        } else {
            throw new AttendanceException(AttendanceErrorCode.INSUFFICIENT_PERMISSION,
                    "Nhân viên không có quyền thực hiện chức năng này");
        }
    }

    @Transactional
    public void deleteAttendanceRecord(UUID attendanceId, UserRole userRole) {
        Attendance attendance = attendanceRepository.findById(attendanceId).orElseThrow(() -> {
            throw new AttendanceException(AttendanceErrorCode.ATTENDANCE_NOT_FOUND, "Can't find attendance record");
        });

        String department = userRole.getDepartment();

        if (department.startsWith("Human Resources")) {
            attendanceRepository.delete(attendance);
            log.warn("Bản ghi chấm công bị XÓA. HR Executor: {}, Bản ghi ID: {}, Nhân viên: {}",
                    userRole.getUserId(), attendanceId,
                    attendance.getUser() != null ? attendance.getUser().getUserId() : "N/A");
        } else {
            throw new AttendanceException(AttendanceErrorCode.INSUFFICIENT_PERMISSION,
                    "Nhân viên không có quyền thực hiện chức năng này");
        }
    }
    
    // ─── XUẤT EXCEL BẢNG CHẤM CÔNG (HR) ──────────────────────────────
    @Transactional(readOnly = true)
    public byte[] exportAttendancesToExcel(UserRole userRole, AttendanceFilterRequest filter) {
        String myDepartment = userRole.getDepartment() != null ? userRole.getDepartment() : "";
        if (!myDepartment.equals("Human Resources")) {
            throw new AttendanceException(AttendanceErrorCode.INSUFFICIENT_PERMISSION,
                "Chỉ phòng Nhân sự mới có quyền xuất dữ liệu chấm công");
        }

        // 1. Lấy danh sách chấm công theo bộ lọc
        Specification<Attendance> spec = AttendanceSpecification.forCompanyWide(filter);
        List<Attendance> attendances = attendanceRepository.findAll(spec, Sort.by(Sort.Direction.DESC, "workDate"));
        List<HrAttendanceResponse> dtoList = attendances.stream().map(this::mapToHrResponse).toList();

        // 2. Khởi tạo Workbook và định dạng Header
        try (Workbook workbook = new XSSFWorkbook(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Sheet sheet = workbook.createSheet("Bang Cham Cong");

            // Style Header: In đậm, nền xanh ngọc nhạt, căn giữa
            CellStyle headerStyle = workbook.createCellStyle();
            Font headerFont = workbook.createFont();
            headerFont.setBold(true);
            headerStyle.setFont(headerFont);
            headerStyle.setFillForegroundColor(IndexedColors.LIGHT_TURQUOISE.getIndex());
            headerStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);
            headerStyle.setAlignment(HorizontalAlignment.CENTER);

            // Danh sách tiêu đề cột
            String[] columns = {
                "STT", "Mã NV", "Họ và Tên", "Phòng Ban", "Chức Vụ",
                "Ngày Làm Việc", "Giờ Vào", "Giờ Ra", "Trạng Thái",
                "Đã Chỉnh Sửa", "Lý Do Chỉnh Sửa", "Người Chỉnh Sửa", "Mã NV Người Sửa"
            };

            Row headerRow = sheet.createRow(0);
            for (int i = 0; i < columns.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(columns[i]);
                cell.setCellStyle(headerStyle);
            }

            DateTimeFormatter timeFormatter = DateTimeFormatter.ofPattern("HH:mm:ss");
            int rowIdx = 1;

            // 3. Ghi dữ liệu từng dòng theo đúng DTO HrAttendanceResponse
            for (HrAttendanceResponse rowData : dtoList) {
                Row row = sheet.createRow(rowIdx);

                row.createCell(0).setCellValue(rowIdx);
                row.createCell(1).setCellValue(rowData.getEmployeeCode() != null ? rowData.getEmployeeCode() : "");
                row.createCell(2).setCellValue(rowData.getFullName() != null ? rowData.getFullName() : "");
                row.createCell(3).setCellValue(rowData.getDepartment() != null ? rowData.getDepartment() : "");
                row.createCell(4).setCellValue(rowData.getJob() != null ? rowData.getJob() : "");
                row.createCell(5).setCellValue(rowData.getWorkDate() != null ? rowData.getWorkDate().toString() : "");
                row.createCell(6).setCellValue(
                        rowData.getClockInTime() != null ? rowData.getClockInTime().format(timeFormatter) : "");
                row.createCell(7).setCellValue(
                        rowData.getClockOutTime() != null ? rowData.getClockOutTime().format(timeFormatter) : "");
                row.createCell(8).setCellValue(rowData.getStatus() != null ? rowData.getStatus().name() : "");
                row.createCell(9).setCellValue(rowData.isEdited() ? "Có" : "Không");
                row.createCell(10).setCellValue(rowData.getEditedReason() != null ? rowData.getEditedReason() : "");
                row.createCell(11).setCellValue(rowData.getEditorName() != null ? rowData.getEditorName() : "");
                row.createCell(12).setCellValue(rowData.getEditorEmpCode() != null ? rowData.getEditorEmpCode() : "");

                rowIdx++;
            }

            // Tự động căn chỉnh độ rộng cột
            for (int i = 0; i < columns.length; i++) {
                sheet.autoSizeColumn(i);
            }

            workbook.write(out);
            return out.toByteArray();
        } catch (IOException e) {
            log.error("Failed to generate Attendance Excel file", e);
            throw new RuntimeErrorException(null);
        }
    }

    // =========================================================================
    // MONTHLY TIMESHEET RETRIEVAL & EXCEL EXPORT
    // =========================================================================

    // 1. Nhân viên xem bảng công của chính mình
    @Transactional(readOnly = true)
    public Page<StaffMonthlyTimesheetResponse> getMyMonthlyTimesheets(
            UUID currentUserId, StaffTimesheetFilterRequest filter, Pageable pageable) {
        Specification<MonthlyTimesheet> spec = MonthlyTimesheetSpecification.filterForStaff(currentUserId, filter);
        return monthlyTimesheetRepository.findAll(spec, pageable).map(this::mapToStaffResponse);
    }

    // 2. Trưởng phòng xem bảng công của nhân viên phòng ban mình (chừa chính mình ra)
    @Transactional(readOnly = true)
    public Page<CompanyMonthlyTimesheetResponse> getDepartmentMonthlyTimesheets(
            UserRole managerRole, ManagerTimesheetFilterRequest filter, Pageable pageable) {
        validateDepartmentHeadOrExecutive(managerRole);
        Specification<MonthlyTimesheet> spec = MonthlyTimesheetSpecification.filterForManager(managerRole, filter);
        return monthlyTimesheetRepository.findAll(spec, pageable).map(this::mapToCompanyResponse);
    }

    // 3. HR / Executive xem bảng công toàn công ty (chừa chính mình ra)
    @Transactional(readOnly = true)
    public Page<CompanyMonthlyTimesheetResponse> getCompanyMonthlyTimesheets(
            UserRole userRole, CompanyTimesheetFilterRequest filter, Pageable pageable) {
        validateHROrExecutive(userRole);
        Specification<MonthlyTimesheet> spec = MonthlyTimesheetSpecification.filterForCompany(userRole.getUserId(), filter);
        return monthlyTimesheetRepository.findAll(spec, pageable).map(this::mapToCompanyResponse);
    }

    // 4. Xuất Excel bảng công cá nhân (Nhân viên)
    @Transactional(readOnly = true)
    public byte[] exportMyMonthlyTimesheetsToExcel(UUID currentUserId, StaffTimesheetFilterRequest filter) {
        Specification<MonthlyTimesheet> spec = MonthlyTimesheetSpecification.filterForStaff(currentUserId, filter);
        Sort sort = Sort.by(Sort.Direction.ASC, "periodYear", "periodMonth");
        List<MonthlyTimesheet> list = monthlyTimesheetRepository.findAll(spec, sort);
        return generateStaffTimesheetExcel(list);
    }

    // 5. Xuất Excel bảng công phòng ban (Trưởng phòng)
    @Transactional(readOnly = true)
    public byte[] exportDepartmentMonthlyTimesheetsToExcel(UserRole managerRole, ManagerTimesheetFilterRequest filter) {
        validateDepartmentHeadOrExecutive(managerRole);
        Specification<MonthlyTimesheet> spec = MonthlyTimesheetSpecification.filterForManager(managerRole, filter);
        Sort sort = Sort.by(Sort.Direction.ASC, "user.employeeCode", "periodYear", "periodMonth");
        List<MonthlyTimesheet> list = monthlyTimesheetRepository.findAll(spec, sort);
        String deptName = (managerRole.getDepartment() != null && !managerRole.getDepartment().isBlank()) 
                ? managerRole.getDepartment() : "PhongBan";
        return generateCompanyTimesheetExcel(list, "Phong Ban " + deptName);
    }

    // 6. Xuất Excel bảng công toàn công ty (HR / Executive)
    @Transactional(readOnly = true)
    public byte[] exportCompanyMonthlyTimesheetsToExcel(UserRole userRole, CompanyTimesheetFilterRequest filter) {
        validateHROrExecutive(userRole);
        Specification<MonthlyTimesheet> spec = MonthlyTimesheetSpecification.filterForCompany(userRole.getUserId(), filter);
        Sort sort = Sort.by(Sort.Direction.ASC, "user.department.name", "user.employeeCode", "periodYear", "periodMonth");
        List<MonthlyTimesheet> list = monthlyTimesheetRepository.findAll(spec, sort);
        return generateCompanyTimesheetExcel(list, "Toan Cong Ty");
    }

    // =========================================================================
    // 7. TÍNH TOÁN, ĐIỀU CHỈNH & CHỐT BẢNG CÔNG THÁNG
    // =========================================================================

    @Transactional
    public Map<String, Object> generateMonthlyTimesheets(int month, int year, UserRole userRole) {
        validateHROrExecutive(userRole);

        // 1. Kiểm tra xem tháng này đã bị khóa (LOCKED) chưa
        boolean alreadyLocked = monthlyTimesheetRepository.existsByPeriodMonthAndPeriodYearAndStatus(month, year, TimesheetStatus.LOCKED);
        if (alreadyLocked) {
            throw new AttendanceException(AttendanceErrorCode.TIMESHEET_ALREADY_LOCKED,
                    "Bảng chấm công tháng " + month + "/" + year + " đã được khóa sổ (LOCKED), không thể tính toán lại.");
        }

        // 2. Xóa các bản ghi DRAFT cũ của tháng này (cho phép re-generate)
        monthlyTimesheetRepository.deleteByPeriodMonthAndPeriodYearAndStatus(month, year, TimesheetStatus.DRAFT);

        LocalDate startOfMonth = LocalDate.of(year, month, 1);
        LocalDate endOfMonth = startOfMonth.with(TemporalAdjusters.lastDayOfMonth());

        List<User> users = userRepository.findAll();
        int calculatedCount = 0;

        for (User user : users) {
            WorkShift shift = user.getShift();

            // 1. Tính ngày công chuẩn theo ca làm việc (trừ ngày nghỉ tuần & ngày lễ)
            int standardWorkingDays = 0;
            if (shift != null) {
                for (LocalDate d = startOfMonth; !d.isAfter(endOfMonth); d = d.plusDays(1)) {
                    if (isWorkingDay(shift.getShiftId(), d.getDayOfWeek()) && !holidayRepository.existsByDate(d)) {
                        standardWorkingDays++;
                    }
                }
            } else {
                standardWorkingDays = 22; // Mặc định 22 ngày nếu chưa gán ca
            }

            // 2. Tổng hợp chấm công thực tế
            List<Attendance> attendances = attendanceRepository.findByUserIdAndDateRange(user.getUserId(), startOfMonth, endOfMonth);
            BigDecimal actualWorkedDays = BigDecimal.ZERO;
            BigDecimal actualWorkHours = BigDecimal.ZERO;
            int lateCount = 0;
            int totalLateMinutes = 0;
            int earlyDepartureCount = 0;
            BigDecimal absentDays = BigDecimal.ZERO;

            for (Attendance att : attendances) {
                AttendanceStatus status = att.getStatus();
                if (status == null) continue;

                switch (status) {
                    case SUFFICIENT:
                    case BUSINESS_TRIP:
                    case ADJUSTED:
                        actualWorkedDays = actualWorkedDays.add(BigDecimal.ONE);
                        break;
                    case LATE:
                        actualWorkedDays = actualWorkedDays.add(BigDecimal.ONE);
                        lateCount++;
                        if (att.getClockInTime() != null && shift != null && shift.getStartTime() != null) {
                            if (att.getClockInTime().isAfter(shift.getStartTime())) {
                                totalLateMinutes += (int) Duration.between(shift.getStartTime(), att.getClockInTime()).toMinutes();
                            }
                        }
                        break;
                    case EARLY:
                        actualWorkedDays = actualWorkedDays.add(BigDecimal.ONE);
                        earlyDepartureCount++;
                        break;
                    case LATE_AND_EARLY:
                        actualWorkedDays = actualWorkedDays.add(BigDecimal.ONE);
                        lateCount++;
                        earlyDepartureCount++;
                        if (att.getClockInTime() != null && shift != null && shift.getStartTime() != null) {
                            if (att.getClockInTime().isAfter(shift.getStartTime())) {
                                totalLateMinutes += (int) Duration.between(shift.getStartTime(), att.getClockInTime()).toMinutes();
                            }
                        }
                        break;
                    case MISSING:
                        // Quên quẹt ra/vào: tạm tính 0.5 ngày làm việc theo quyết định
                        actualWorkedDays = actualWorkedDays.add(BigDecimal.valueOf(0.5));
                        break;
                    case UNEXCUSED_ABSENCE:
                        absentDays = absentDays.add(BigDecimal.ONE);
                        break;
                    default:
                        break;
                }

                // Tính giờ làm thực tế
                if (att.getClockInTime() != null && att.getClockOutTime() != null) {
                    long minutes = Duration.between(att.getClockInTime(), att.getClockOutTime()).toMinutes();
                    if (shift != null && shift.getRestStartTime() != null && shift.getRestEndTime() != null) {
                        if (!att.getClockInTime().isAfter(shift.getRestStartTime()) && !att.getClockOutTime().isBefore(shift.getRestEndTime())) {
                            long restMins = Duration.between(shift.getRestStartTime(), shift.getRestEndTime()).toMinutes();
                            minutes = Math.max(0, minutes - restMins);
                        }
                    }
                    double hours = Math.max(0, minutes / 60.0);
                    actualWorkHours = actualWorkHours.add(BigDecimal.valueOf(hours));
                } else if (status == AttendanceStatus.MISSING) {
                    actualWorkHours = actualWorkHours.add(BigDecimal.valueOf(4.0));
                } else if (status == AttendanceStatus.BUSINESS_TRIP || status == AttendanceStatus.ADJUSTED) {
                    actualWorkHours = actualWorkHours.add(BigDecimal.valueOf(8.0));
                }
            }

            // 3. Tổng hợp Nghỉ phép
            List<LeaveRequest> leaves = leaveRequestRepository.findAcceptedLeavesByUserIdAndDateRange(
                    user.getUserId(), LeaveRequestStatus.accepted, startOfMonth, endOfMonth);
            BigDecimal paidLeaveDays = BigDecimal.ZERO;
            BigDecimal unpaidLeaveDays = BigDecimal.ZERO;

            for (LeaveRequest leave : leaves) {
                LocalDate from = leave.getFromDate().isBefore(startOfMonth) ? startOfMonth : leave.getFromDate();
                LocalDate to = leave.getToDate().isAfter(endOfMonth) ? endOfMonth : leave.getToDate();

                int daysInMonth = 0;
                for (LocalDate d = from; !d.isAfter(to); d = d.plusDays(1)) {
                    if (shift == null || (isWorkingDay(shift.getShiftId(), d.getDayOfWeek()) && !holidayRepository.existsByDate(d))) {
                        daysInMonth++;
                    }
                }

                if (leave.getPaidLeaveDays() > 0) {
                    int paidDays = Math.min(daysInMonth, leave.getPaidLeaveDays());
                    paidLeaveDays = paidLeaveDays.add(BigDecimal.valueOf(paidDays));
                    int unpaidDays = daysInMonth - paidDays;
                    if (unpaidDays > 0) {
                        unpaidLeaveDays = unpaidLeaveDays.add(BigDecimal.valueOf(unpaidDays));
                    }
                } else {
                    unpaidLeaveDays = unpaidLeaveDays.add(BigDecimal.valueOf(daysInMonth));
                }
            }

            // 4. Tổng hợp Tăng ca (OT)
            List<OvertimeRecord> overtimes = overtimeRecordRepository.findAcceptedOvertimesByUserIdAndDateRange(
                    user.getUserId(), OvertimeRecordStatus.accepted, startOfMonth, endOfMonth);
            BigDecimal totalActualOtHours = BigDecimal.ZERO;
            BigDecimal totalPaidOtHours = BigDecimal.ZERO;
            List<StaffMonthlyTimesheetResponse.OvertimeDetailDto> otDetailList = new ArrayList<>();

            for (OvertimeRecord ot : overtimes) {
                double otHours = 0.0;
                if (ot.getClockInTime() != null && ot.getClockOutTime() != null) {
                    otHours = Duration.between(ot.getClockInTime(), ot.getClockOutTime()).toMinutes() / 60.0;
                } else if (ot.getApprovedStartTime() != null && ot.getApprovedEndTime() != null) {
                    otHours = Duration.between(ot.getApprovedStartTime(), ot.getApprovedEndTime()).toMinutes() / 60.0;
                }
                if (otHours <= 0) continue;

                double multiplier;
                String otTypeCode;
                String otLabel;
                if (ot.isHoliday()) {
                    if (ot.isNightTime()) {
                        multiplier = 3.9;
                        otTypeCode = "HOLIDAY_NIGHT";
                        otLabel = "Ngày lễ - Ban đêm (390%)";
                    } else {
                        multiplier = 3.0;
                        otTypeCode = "HOLIDAY_DAY";
                        otLabel = "Ngày lễ - Ban ngày (300%)";
                    }
                } else if (ot.isWeekend()) {
                    if (ot.isNightTime()) {
                        multiplier = 2.7;
                        otTypeCode = "WEEKEND_NIGHT";
                        otLabel = "Cuối tuần - Ban đêm (270%)";
                    } else {
                        multiplier = 2.0;
                        otTypeCode = "WEEKEND_DAY";
                        otLabel = "Cuối tuần - Ban ngày (200%)";
                    }
                } else {
                    if (ot.isNightTime()) {
                        multiplier = 2.0;
                        otTypeCode = "NORMAL_NIGHT";
                        otLabel = "Ngày thường - Ban đêm (200%)";
                    } else {
                        multiplier = 1.5;
                        otTypeCode = "NORMAL_DAY";
                        otLabel = "Ngày thường - Ban ngày (150%)";
                    }
                }

                double paidOt = otHours * multiplier;
                totalActualOtHours = totalActualOtHours.add(BigDecimal.valueOf(otHours));
                totalPaidOtHours = totalPaidOtHours.add(BigDecimal.valueOf(paidOt));

                otDetailList.add(StaffMonthlyTimesheetResponse.OvertimeDetailDto.builder()
                        .type(otTypeCode)
                        .label(otLabel)
                        .multiplier(multiplier)
                        .hours(BigDecimal.valueOf(otHours).setScale(2, RoundingMode.HALF_UP).doubleValue())
                        .paidHours(BigDecimal.valueOf(paidOt).setScale(2, RoundingMode.HALF_UP).doubleValue())
                        .build());
            }

            String otDetailsJson = null;
            if (!otDetailList.isEmpty()) {
                try {
                    otDetailsJson = objectMapper.writeValueAsString(otDetailList);
                } catch (Exception e) {
                    log.warn("Lỗi chuyển đổi otDetails sang JSON", e);
                }
            }

            actualWorkedDays = actualWorkedDays.setScale(2, RoundingMode.HALF_UP);
            actualWorkHours = actualWorkHours.setScale(2, RoundingMode.HALF_UP);
            absentDays = absentDays.setScale(2, RoundingMode.HALF_UP);
            paidLeaveDays = paidLeaveDays.setScale(2, RoundingMode.HALF_UP);
            unpaidLeaveDays = unpaidLeaveDays.setScale(2, RoundingMode.HALF_UP);
            totalActualOtHours = totalActualOtHours.setScale(2, RoundingMode.HALF_UP);
            totalPaidOtHours = totalPaidOtHours.setScale(2, RoundingMode.HALF_UP);

            MonthlyTimesheet ts = MonthlyTimesheet.builder()
                    .user(user)
                    .periodMonth(month)
                    .periodYear(year)
                    .standardWorkingDays(standardWorkingDays)
                    .actualWorkedDays(actualWorkedDays)
                    .actualWorkHours(actualWorkHours)
                    .lateCount(lateCount)
                    .totalLateMinutes(totalLateMinutes)
                    .earlyDepartureCount(earlyDepartureCount)
                    .absentDays(absentDays)
                    .paidLeaveDays(paidLeaveDays)
                    .unpaidLeaveDays(unpaidLeaveDays)
                    .totalActualOtHours(totalActualOtHours)
                    .totalPaidOtHours(totalPaidOtHours)
                    .otDetails(otDetailsJson)
                    .status(TimesheetStatus.DRAFT)
                    .build();

            monthlyTimesheetRepository.save(ts);
            calculatedCount++;
        }

        log.info("Tổng hợp bảng chấm công tháng {}/{} hoàn tất cho {} nhân viên bởi {}", month, year, calculatedCount, userRole.getUserId());
        return Map.of(
                "msg", "Tổng hợp bảng chấm công tháng " + month + "/" + year + " thành công",
                "calculatedCount", calculatedCount,
                "status", TimesheetStatus.DRAFT.name()
        );
    }

    @Transactional
    public CompanyMonthlyTimesheetResponse editMonthlyTimesheet(
            UUID timesheetId, MonthlyTimesheetEditRequest request, UserRole userRole) {
        validateHROrExecutive(userRole);

        MonthlyTimesheet ts = monthlyTimesheetRepository.findById(timesheetId)
                .orElseThrow(() -> new AttendanceException(AttendanceErrorCode.TIMESHEET_NOT_FOUND,
                        "Không tìm thấy bản ghi bảng chấm công"));

        if (ts.getStatus() == TimesheetStatus.LOCKED) {
            throw new AttendanceException(AttendanceErrorCode.TIMESHEET_ALREADY_LOCKED,
                    "Bảng chấm công đã được khóa sổ (LOCKED), không thể chỉnh sửa.");
        }

        if (request.getActualWorkedDays() != null) {
            ts.setActualWorkedDays(request.getActualWorkedDays().setScale(2, RoundingMode.HALF_UP));
        }
        if (request.getActualWorkHours() != null) {
            ts.setActualWorkHours(request.getActualWorkHours().setScale(2, RoundingMode.HALF_UP));
        }
        if (request.getTotalActualOtHours() != null) {
            ts.setTotalActualOtHours(request.getTotalActualOtHours().setScale(2, RoundingMode.HALF_UP));
        }
        if (request.getTotalPaidOtHours() != null) {
            ts.setTotalPaidOtHours(request.getTotalPaidOtHours().setScale(2, RoundingMode.HALF_UP));
        }
        if (request.getPaidLeaveDays() != null) {
            ts.setPaidLeaveDays(request.getPaidLeaveDays().setScale(2, RoundingMode.HALF_UP));
        }
        if (request.getUnpaidLeaveDays() != null) {
            ts.setUnpaidLeaveDays(request.getUnpaidLeaveDays().setScale(2, RoundingMode.HALF_UP));
        }
        if (request.getLateCount() != null) {
            ts.setLateCount(request.getLateCount());
        }
        if (request.getTotalLateMinutes() != null) {
            ts.setTotalLateMinutes(request.getTotalLateMinutes());
        }
        if (request.getEarlyDepartureCount() != null) {
            ts.setEarlyDepartureCount(request.getEarlyDepartureCount());
        }
        if (request.getAbsentDays() != null) {
            ts.setAbsentDays(request.getAbsentDays().setScale(2, RoundingMode.HALF_UP));
        }
        if (request.getNote() != null) {
            ts.setNote(request.getNote());
        }

        ts = monthlyTimesheetRepository.save(ts);
        log.info("HR {} đã điều chỉnh bảng công nhân viên {} kỳ {}/{}",
                userRole.getUserId(), ts.getUser() != null ? ts.getUser().getUserId() : null, ts.getPeriodMonth(), ts.getPeriodYear());

        return mapToCompanyResponse(ts);
    }

    @Transactional
    public Map<String, Object> lockMonthlyTimesheet(int month, int year, UserRole userRole) {
        validateHeadOfHROrExecutive(userRole);

        List<MonthlyTimesheet> list = monthlyTimesheetRepository.findByPeriodMonthAndPeriodYear(month, year);
        if (list.isEmpty()) {
            throw new AttendanceException(AttendanceErrorCode.TIMESHEET_NOT_FOUND,
                    "Không tìm thấy dữ liệu bảng chấm công tháng " + month + "/" + year);
        }

        boolean allLocked = list.stream().allMatch(t -> t.getStatus() == TimesheetStatus.LOCKED);
        if (allLocked) {
            throw new AttendanceException(AttendanceErrorCode.TIMESHEET_ALREADY_LOCKED,
                    "Bảng chấm công tháng " + month + "/" + year + " đã được khóa sổ trước đó.");
        }

        LocalDateTime now = LocalDateTime.now();
        for (MonthlyTimesheet t : list) {
            t.setStatus(TimesheetStatus.LOCKED);
            t.setLockedAt(now);
            t.setLockedBy(userRole.getUserId());
        }
        monthlyTimesheetRepository.saveAll(list);

        log.info("Trưởng phòng HR {} đã chốt sổ (LOCKED) bảng chấm công tháng {}/{} cho {} nhân viên",
                userRole.getUserId(), month, year, list.size());

        return Map.of(
                "msg", "Chốt sổ bảng chấm công tháng " + month + "/" + year + " thành công",
                "lockedCount", list.size(),
                "status", TimesheetStatus.LOCKED.name()
        );
    }

    // =================== HELPER & EXCEL BUILDERS ===================

    private void validateHeadOfHROrExecutive(UserRole userRole) {
        String dept = userRole.getDepartment() != null ? userRole.getDepartment() : "";
        String job = userRole.getJob() != null ? userRole.getJob() : "";
        boolean isExecutive = "Executive Leadership".equals(dept);
        boolean isHR = "Human Resources".equals(dept);
        boolean isHead = job.startsWith("Department Head") || job.contains("Head") || job.contains("Manager") || job.contains("Trưởng");
        if (!isExecutive && !(isHR && isHead)) {
            throw new AttendanceException(AttendanceErrorCode.UNAUTHORIZED_ACTION,
                    "Chỉ Trưởng phòng Nhân sự hoặc Ban Giám Đốc mới có quyền chốt sổ bảng chấm công tháng");
        }
    }

    private void validateDepartmentHeadOrExecutive(UserRole userRole) {
        String job = userRole.getJob() != null ? userRole.getJob() : "";
        String dept = userRole.getDepartment() != null ? userRole.getDepartment() : "";
        boolean isExecutive = "Executive Leadership".equals(dept);
        boolean isHead = job.startsWith("Department Head") || job.contains("Head") || job.contains("Manager");
        if (!isHead && !isExecutive) {
            throw new AttendanceException(AttendanceErrorCode.UNAUTHORIZED_ACTION,
                    "Chỉ Trưởng phòng ban hoặc Ban Giám Đốc mới có quyền thao tác dữ liệu chấm công phòng ban");
        }
    }

    private void validateHROrExecutive(UserRole userRole) {
        String dept = userRole.getDepartment() != null ? userRole.getDepartment() : "";
        boolean isHR = "Human Resources".equals(dept);
        boolean isExecutive = "Executive Leadership".equals(dept);
        if (!isHR && !isExecutive) {
            throw new AttendanceException(AttendanceErrorCode.INSUFFICIENT_PERMISSION,
                    "Chỉ phòng Nhân sự (HR) hoặc Ban Giám Đốc mới có quyền thao tác dữ liệu chấm công toàn công ty");
        }
    }

    private List<StaffMonthlyTimesheetResponse.OvertimeDetailDto> parseOtDetails(String json) {
        if (json == null || json.isBlank()) {
            return Collections.emptyList();
        }
        try {
            return objectMapper.readValue(json, new TypeReference<List<StaffMonthlyTimesheetResponse.OvertimeDetailDto>>() {});
        } catch (Exception e) {
            log.warn("Failed to parse otDetails JSON: {}", json, e);
            return Collections.emptyList();
        }
    }

    private StaffMonthlyTimesheetResponse mapToStaffResponse(MonthlyTimesheet entity) {
        return StaffMonthlyTimesheetResponse.builder()
                .timesheetId(entity.getTimesheetId())
                .month(entity.getPeriodMonth())
                .year(entity.getPeriodYear())
                .status(entity.getStatus())
                .note(entity.getNote())
                .attendance(StaffMonthlyTimesheetResponse.AttendanceSummaryDto.builder()
                        .standardWorkingDays(entity.getStandardWorkingDays())
                        .actualWorkedDays(entity.getActualWorkedDays() != null ? entity.getActualWorkedDays().doubleValue() : 0.0)
                        .actualWorkHours(entity.getActualWorkHours() != null ? entity.getActualWorkHours().doubleValue() : 0.0)
                        .lateCount(entity.getLateCount())
                        .totalLateMinutes(entity.getTotalLateMinutes())
                        .earlyDepartureCount(entity.getEarlyDepartureCount())
                        .absentDays(entity.getAbsentDays() != null ? entity.getAbsentDays().doubleValue() : 0.0)
                        .build())
                .leave(StaffMonthlyTimesheetResponse.LeaveSummaryDto.builder()
                        .paidLeaveDays(entity.getPaidLeaveDays() != null ? entity.getPaidLeaveDays().doubleValue() : 0.0)
                        .unpaidLeaveDays(entity.getUnpaidLeaveDays() != null ? entity.getUnpaidLeaveDays().doubleValue() : 0.0)
                        .remainingAnnualLeaveDays(0.0)
                        .build())
                .overtime(StaffMonthlyTimesheetResponse.OvertimeSummaryDto.builder()
                        .totalActualHours(entity.getTotalActualOtHours() != null ? entity.getTotalActualOtHours().doubleValue() : 0.0)
                        .totalPaidHours(entity.getTotalPaidOtHours() != null ? entity.getTotalPaidOtHours().doubleValue() : 0.0)
                        .details(parseOtDetails(entity.getOtDetails()))
                        .build())
                .build();
    }

    private CompanyMonthlyTimesheetResponse mapToCompanyResponse(MonthlyTimesheet entity) {
        User u = entity.getUser();
        String fullName = "";
        String deptName = "";
        String jobTitle = "";
        String empCode = "";
        UUID userId = null;

        if (u != null) {
            userId = u.getUserId();
            empCode = u.getEmployeeCode() != null ? u.getEmployeeCode() : "";
            fullName = ((u.getFirstName() != null ? u.getFirstName() : "") + " " + (u.getLastName() != null ? u.getLastName() : "")).trim();
            if (u.getDepartment() != null) {
                deptName = u.getDepartment().getName();
            }
            if (u.getJob() != null) {
                jobTitle = u.getJob().getTitle();
            }
        }

        return CompanyMonthlyTimesheetResponse.builder()
                .timesheetId(entity.getTimesheetId())
                .userId(userId)
                .employeeCode(empCode)
                .fullName(fullName)
                .department(deptName)
                .job(jobTitle)
                .month(entity.getPeriodMonth())
                .year(entity.getPeriodYear())
                .status(entity.getStatus())
                .note(entity.getNote())
                .lockedAt(entity.getLockedAt())
                .lockedBy(entity.getLockedBy())
                .attendance(StaffMonthlyTimesheetResponse.AttendanceSummaryDto.builder()
                        .standardWorkingDays(entity.getStandardWorkingDays())
                        .actualWorkedDays(entity.getActualWorkedDays() != null ? entity.getActualWorkedDays().doubleValue() : 0.0)
                        .actualWorkHours(entity.getActualWorkHours() != null ? entity.getActualWorkHours().doubleValue() : 0.0)
                        .lateCount(entity.getLateCount())
                        .totalLateMinutes(entity.getTotalLateMinutes())
                        .earlyDepartureCount(entity.getEarlyDepartureCount())
                        .absentDays(entity.getAbsentDays() != null ? entity.getAbsentDays().doubleValue() : 0.0)
                        .build())
                .leave(StaffMonthlyTimesheetResponse.LeaveSummaryDto.builder()
                        .paidLeaveDays(entity.getPaidLeaveDays() != null ? entity.getPaidLeaveDays().doubleValue() : 0.0)
                        .unpaidLeaveDays(entity.getUnpaidLeaveDays() != null ? entity.getUnpaidLeaveDays().doubleValue() : 0.0)
                        .remainingAnnualLeaveDays(0.0)
                        .build())
                .overtime(StaffMonthlyTimesheetResponse.OvertimeSummaryDto.builder()
                        .totalActualHours(entity.getTotalActualOtHours() != null ? entity.getTotalActualOtHours().doubleValue() : 0.0)
                        .totalPaidHours(entity.getTotalPaidOtHours() != null ? entity.getTotalPaidOtHours().doubleValue() : 0.0)
                        .details(parseOtDetails(entity.getOtDetails()))
                        .build())
                .build();
    }

    private byte[] generateStaffTimesheetExcel(List<MonthlyTimesheet> list) {
        try (Workbook workbook = new XSSFWorkbook(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Sheet sheet = workbook.createSheet("Bang Cong Ca Nhan");

            CellStyle headerStyle = createHeaderCellStyle(workbook);
            String[] columns = {
                "STT", "Tháng/Năm", "Trạng Thái", "Ngày Chuẩn", "Ngày Làm Thực Tế",
                "Giờ Làm Thực Tế", "Đi Muộn (lần)", "Phút Đi Muộn", "Về Sớm (lần)",
                "Vắng Không Phép (ngày)", "Nghỉ Có Lương (ngày)", "Nghỉ Không Lương (ngày)",
                "Giờ OT Thực Tế", "Giờ OT Tính Lương", "Ghi Chú"
            };

            Row headerRow = sheet.createRow(0);
            for (int i = 0; i < columns.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(columns[i]);
                cell.setCellStyle(headerStyle);
            }

            int rowIdx = 1;
            for (MonthlyTimesheet t : list) {
                Row row = sheet.createRow(rowIdx);
                row.createCell(0).setCellValue(rowIdx);
                row.createCell(1).setCellValue(t.getPeriodMonth() + "/" + t.getPeriodYear());
                row.createCell(2).setCellValue(t.getStatus() != null ? t.getStatus().name() : "");
                row.createCell(3).setCellValue(t.getStandardWorkingDays());
                row.createCell(4).setCellValue(t.getActualWorkedDays() != null ? t.getActualWorkedDays().doubleValue() : 0.0);
                row.createCell(5).setCellValue(t.getActualWorkHours() != null ? t.getActualWorkHours().doubleValue() : 0.0);
                row.createCell(6).setCellValue(t.getLateCount());
                row.createCell(7).setCellValue(t.getTotalLateMinutes());
                row.createCell(8).setCellValue(t.getEarlyDepartureCount());
                row.createCell(9).setCellValue(t.getAbsentDays() != null ? t.getAbsentDays().doubleValue() : 0.0);
                row.createCell(10).setCellValue(t.getPaidLeaveDays() != null ? t.getPaidLeaveDays().doubleValue() : 0.0);
                row.createCell(11).setCellValue(t.getUnpaidLeaveDays() != null ? t.getUnpaidLeaveDays().doubleValue() : 0.0);
                row.createCell(12).setCellValue(t.getTotalActualOtHours() != null ? t.getTotalActualOtHours().doubleValue() : 0.0);
                row.createCell(13).setCellValue(t.getTotalPaidOtHours() != null ? t.getTotalPaidOtHours().doubleValue() : 0.0);
                row.createCell(14).setCellValue(t.getNote() != null ? t.getNote() : "");
                rowIdx++;
            }

            for (int i = 0; i < columns.length; i++) {
                sheet.autoSizeColumn(i);
            }

            workbook.write(out);
            return out.toByteArray();
        } catch (IOException e) {
            log.error("Failed to generate Staff Monthly Timesheet Excel", e);
            throw new RuntimeErrorException(null);
        }
    }

    private byte[] generateCompanyTimesheetExcel(List<MonthlyTimesheet> list, String sheetName) {
        try (Workbook workbook = new XSSFWorkbook(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Sheet sheet = workbook.createSheet(sheetName.length() > 30 ? sheetName.substring(0, 30) : sheetName);

            CellStyle headerStyle = createHeaderCellStyle(workbook);
            String[] columns = {
                "STT", "Mã NV", "Họ và Tên", "Phòng Ban", "Chức Vụ",
                "Tháng/Năm", "Trạng Thái", "Ngày Chuẩn", "Ngày Làm Thực Tế",
                "Giờ Làm Thực Tế", "Đi Muộn (lần)", "Phút Đi Muộn", "Về Sớm (lần)",
                "Vắng Không Phép (ngày)", "Nghỉ Có Lương (ngày)", "Nghỉ Không Lương (ngày)",
                "Giờ OT Thực Tế", "Giờ OT Tính Lương", "Ghi Chú"
            };

            Row headerRow = sheet.createRow(0);
            for (int i = 0; i < columns.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(columns[i]);
                cell.setCellStyle(headerStyle);
            }

            int rowIdx = 1;
            for (MonthlyTimesheet t : list) {
                Row row = sheet.createRow(rowIdx);
                User u = t.getUser();

                row.createCell(0).setCellValue(rowIdx);
                row.createCell(1).setCellValue(u != null && u.getEmployeeCode() != null ? u.getEmployeeCode() : "");
                row.createCell(2).setCellValue(u != null ? ((u.getFirstName() != null ? u.getFirstName() : "") + " " + (u.getLastName() != null ? u.getLastName() : "")).trim() : "");
                row.createCell(3).setCellValue(u != null && u.getDepartment() != null ? u.getDepartment().getName() : "");
                row.createCell(4).setCellValue(u != null && u.getJob() != null ? u.getJob().getTitle() : "");
                row.createCell(5).setCellValue(t.getPeriodMonth() + "/" + t.getPeriodYear());
                row.createCell(6).setCellValue(t.getStatus() != null ? t.getStatus().name() : "");
                row.createCell(7).setCellValue(t.getStandardWorkingDays());
                row.createCell(8).setCellValue(t.getActualWorkedDays() != null ? t.getActualWorkedDays().doubleValue() : 0.0);
                row.createCell(9).setCellValue(t.getActualWorkHours() != null ? t.getActualWorkHours().doubleValue() : 0.0);
                row.createCell(10).setCellValue(t.getLateCount());
                row.createCell(11).setCellValue(t.getTotalLateMinutes());
                row.createCell(12).setCellValue(t.getEarlyDepartureCount());
                row.createCell(13).setCellValue(t.getAbsentDays() != null ? t.getAbsentDays().doubleValue() : 0.0);
                row.createCell(14).setCellValue(t.getPaidLeaveDays() != null ? t.getPaidLeaveDays().doubleValue() : 0.0);
                row.createCell(15).setCellValue(t.getUnpaidLeaveDays() != null ? t.getUnpaidLeaveDays().doubleValue() : 0.0);
                row.createCell(16).setCellValue(t.getTotalActualOtHours() != null ? t.getTotalActualOtHours().doubleValue() : 0.0);
                row.createCell(17).setCellValue(t.getTotalPaidOtHours() != null ? t.getTotalPaidOtHours().doubleValue() : 0.0);
                row.createCell(18).setCellValue(t.getNote() != null ? t.getNote() : "");
                rowIdx++;
            }

            for (int i = 0; i < columns.length; i++) {
                sheet.autoSizeColumn(i);
            }

            workbook.write(out);
            return out.toByteArray();
        } catch (IOException e) {
            log.error("Failed to generate Company Monthly Timesheet Excel", e);
            throw new RuntimeErrorException(null);
        }
    }

    private CellStyle createHeaderCellStyle(Workbook workbook) {
        CellStyle headerStyle = workbook.createCellStyle();
        Font headerFont = workbook.createFont();
        headerFont.setBold(true);
        headerStyle.setFont(headerFont);
        headerStyle.setFillForegroundColor(IndexedColors.LIGHT_TURQUOISE.getIndex());
        headerStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);
        headerStyle.setAlignment(HorizontalAlignment.CENTER);
        return headerStyle;
    }
}
