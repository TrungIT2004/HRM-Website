package com.minhtrung.hrm.payroll.services;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
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

import com.minhtrung.hrm.attendance.entities.MonthlyTimesheet;
import com.minhtrung.hrm.attendance.enums.TimesheetStatus;
import com.minhtrung.hrm.attendance.repositories.MonthlyTimesheetRepository;
import com.minhtrung.hrm.employees.dtos.internals.UserRole;
import com.minhtrung.hrm.permissions.enums.PermissionKey;
import com.minhtrung.hrm.permissions.services.PermissionService;
import com.minhtrung.hrm.employees.entities.Salary;
import com.minhtrung.hrm.employees.entities.User;
import com.minhtrung.hrm.employees.repositories.SalaryRepository;
import com.minhtrung.hrm.payroll.dtos.requests.CompanyPayrollFilterRequest;
import com.minhtrung.hrm.payroll.dtos.requests.EditPayrollRequest;
import com.minhtrung.hrm.payroll.dtos.requests.StaffPayrollFilterRequest;
import com.minhtrung.hrm.payroll.dtos.responses.CompanyPayrollResponse;
import com.minhtrung.hrm.payroll.dtos.responses.MonthlyPayrollSummaryResponse;
import com.minhtrung.hrm.payroll.dtos.responses.StaffPayrollResponse;
import com.minhtrung.hrm.payroll.entities.MonthlyPayrollSummary;
import com.minhtrung.hrm.payroll.entities.Payroll;
import com.minhtrung.hrm.payroll.enums.PayrollErrorCode;
import com.minhtrung.hrm.payroll.enums.PayrollStatus;
import com.minhtrung.hrm.payroll.exceptions.PayrollException;
import com.minhtrung.hrm.payroll.repositories.MonthlyPayrollSummaryRepository;
import com.minhtrung.hrm.payroll.repositories.PayrollRepository;
import com.minhtrung.hrm.payroll.specifications.PayrollSpecification;

import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class PayrollService {

    private final PayrollRepository payrollRepository;
    private final MonthlyPayrollSummaryRepository monthlyPayrollSummaryRepository;
    private final MonthlyTimesheetRepository monthlyTimesheetRepository;
    private final SalaryRepository salaryRepository;
    private final PermissionService permissionService;

    public PayrollService(
            PayrollRepository payrollRepository,
            MonthlyPayrollSummaryRepository monthlyPayrollSummaryRepository,
            MonthlyTimesheetRepository monthlyTimesheetRepository,
            SalaryRepository salaryRepository,
            PermissionService permissionService) {
        this.payrollRepository = payrollRepository;
        this.monthlyPayrollSummaryRepository = monthlyPayrollSummaryRepository;
        this.monthlyTimesheetRepository = monthlyTimesheetRepository;
        this.salaryRepository = salaryRepository;
        this.permissionService = permissionService;
    }

    // =========================================================================
    // 1. CÁ NHÂN: XEM PHIẾU LƯƠNG & XUẤT EXCEL
    // =========================================================================

    @Transactional(readOnly = true)
    public Page<StaffPayrollResponse> getMyPayrolls(UUID currentUserId, StaffPayrollFilterRequest filter, Pageable pageable) {
        Specification<Payroll> spec = PayrollSpecification.filterForStaff(currentUserId, filter);
        return payrollRepository.findAll(spec, pageable).map(this::mapToStaffResponse);
    }

    @Transactional(readOnly = true)
    public byte[] exportMyPayrollsToExcel(UUID currentUserId, StaffPayrollFilterRequest filter) {
        Specification<Payroll> spec = PayrollSpecification.filterForStaff(currentUserId, filter);
        Sort sort = Sort.by(Sort.Direction.ASC, "periodYear", "periodMonth");
        List<Payroll> list = payrollRepository.findAll(spec, sort);
        return generateStaffPayrollExcel(list);
    }

    // =========================================================================
    // 2. TOÀN CÔNG TY: KẾ TOÁN & BAN GIÁM ĐỐC XEM BẢNG LƯƠNG & XUẤT EXCEL
    // =========================================================================

    @Transactional(readOnly = true)
    public Page<CompanyPayrollResponse> getCompanyPayrolls(UserRole userRole, CompanyPayrollFilterRequest filter, Pageable pageable) {
        validatePayrollManagementPermission(userRole);
        Specification<Payroll> spec = PayrollSpecification.filterForCompany(filter);
        return payrollRepository.findAll(spec, pageable).map(this::mapToCompanyResponse);
    }

    @Transactional(readOnly = true)
    public byte[] exportCompanyPayrollsToExcel(UserRole userRole, CompanyPayrollFilterRequest filter) {
        validatePayrollManagementPermission(userRole);
        Specification<Payroll> spec = PayrollSpecification.filterForCompany(filter);
        Sort sort = Sort.by(Sort.Direction.ASC, "user.department.name", "user.employeeCode", "periodYear", "periodMonth");
        List<Payroll> list = payrollRepository.findAll(spec, sort);
        return generateCompanyPayrollExcel(list);
    }

    @Transactional(readOnly = true)
    public MonthlyPayrollSummaryResponse getMonthlyPayrollSummary(int month, int year, UserRole userRole) {
        validatePayrollManagementPermission(userRole);
        MonthlyPayrollSummary summary = monthlyPayrollSummaryRepository.findByPeriodMonthAndPeriodYear(month, year)
                .orElseThrow(() -> new PayrollException(PayrollErrorCode.SUMMARY_NOT_FOUND,
                        "Không tìm thấy dữ liệu tổng hợp chi phí lương tháng " + month + "/" + year));
        return mapToSummaryResponse(summary);
    }

    // =========================================================================
    // 3. TÍNH TOÁN BẢNG LƯƠNG TỰ ĐỘNG (GENERATE / RE-CALCULATE)
    // =========================================================================

    /**
     * Tính lương một kỳ. Phạm vi theo thứ tự ưu tiên:
     * {@code userIds} (vùng người dùng tick trên bảng) → {@code filter} (từ khoá / phòng ban)
     * → toàn bộ tháng khi cả hai rỗng.
     */
    @Transactional
    public Map<String, Object> generatePayroll(int month, int year, UserRole userRole,
                                               CompanyPayrollFilterRequest filter, List<UUID> userIds) {
        validatePayrollManagementPermission(userRole);

        // Chỉ tính lương được kỳ ĐÃ KẾT THÚC: hôm 27/09 thì tháng 09 chưa tính lương được,
        // phải chờ sang ngày 01/10. So sánh year*12+month để không cần parse ngày.
        int currentPeriod = LocalDate.now().getYear() * 12 + LocalDate.now().getMonthValue();
        if (year * 12 + month >= currentPeriod) {
            throw new PayrollException(PayrollErrorCode.INVALID_PAYROLL_PERIOD,
                    "Kỳ lương " + month + "/" + year + " chưa kết thúc, chỉ tính lương cho kỳ đã qua.");
        }

        // 1. Kiểm tra bảng chấm công đã khóa chưa
        List<MonthlyTimesheet> allTimesheets = monthlyTimesheetRepository.findByPeriodMonthAndPeriodYearAndStatus(month, year, TimesheetStatus.LOCKED);
        if (allTimesheets == null || allTimesheets.isEmpty()) {
            throw new PayrollException(PayrollErrorCode.TIMESHEET_NOT_LOCKED,
                    "Bảng chấm công tháng " + month + "/" + year + " chưa được khóa sổ (LOCKED). Vui lòng chốt và khóa chấm công trước khi tính lương.");
        }

        // Thu hẹp phạm vi tính theo vùng đang chọn, nếu không thì theo bộ lọc đang xem.
        List<MonthlyTimesheet> timesheets;
        String scope;
        if (userIds != null && !userIds.isEmpty()) {
            timesheets = allTimesheets.stream()
                    .filter(ts -> ts.getUser() != null && userIds.contains(ts.getUser().getUserId()))
                    .toList();
            scope = "vùng chọn";
        } else {
            timesheets = allTimesheets.stream().filter(ts -> matchesFilter(ts.getUser(), filter)).toList();
            boolean hasKeyword = filter != null && filter.getKeyword() != null && !filter.getKeyword().isBlank();
            boolean hasDept = filter != null && filter.getDepartmentNames() != null && !filter.getDepartmentNames().isEmpty();
            scope = (hasKeyword || hasDept) ? "bộ lọc" : "toàn tháng";
        }
        if (timesheets.isEmpty()) {
            throw new PayrollException(PayrollErrorCode.TIMESHEET_NOT_LOCKED,
                    "Không có nhân viên nào khớp phạm vi đang chọn có bảng chấm công đã khoá tháng " + month + "/" + year + ".");
        }

        // 2. Kiểm tra xem kỳ lương đã APPROVED hoặc PAID chưa
        boolean alreadyApprovedOrPaid = payrollRepository.existsByPeriodMonthAndPeriodYear(month, year)
                && (payrollRepository.countByPeriodMonthAndPeriodYearAndStatus(month, year, PayrollStatus.APPROVED) > 0
                    || payrollRepository.countByPeriodMonthAndPeriodYearAndStatus(month, year, PayrollStatus.PAID) > 0);

        if (alreadyApprovedOrPaid) {
            throw new PayrollException(PayrollErrorCode.PAYROLL_ALREADY_APPROVED,
                    "Bảng lương tháng " + month + "/" + year + " đã được phê duyệt hoặc chi trả, không thể tính toán lại.");
        }

        // 3. Xóa dữ liệu DRAFT cũ trong phạm vi lọc để re-calculate sạch sẽ.
        // Chỉ xoá nhóm đang lọc — xoá cả tháng sẽ mất bản ghi DRAFT của các phòng ban khác.
        List<UUID> scopedUserIds = timesheets.stream().map(ts -> ts.getUser().getUserId()).toList();
        payrollRepository.deleteByPeriodMonthAndPeriodYearAndStatusAndUser_UserIdIn(
                month, year, PayrollStatus.DRAFT, scopedUserIds);
        // Bắt buộc: Hibernate xếp INSERT trước DELETE trong cùng một flush, nên nếu không flush
        // thì bản ghi mới sẽ vi phạm uk_payroll_user_period trước khi bản ghi cũ được xoá.
        payrollRepository.flush();

        LocalDateTime now = LocalDateTime.now();
        int calculatedCount = 0;

        for (MonthlyTimesheet ts : timesheets) {
            User u = ts.getUser();
            if (u == null) continue;

            Optional<Salary> salaryOpt = salaryRepository.findByUser_UserIdAndIsActiveTrue(u.getUserId())
                    .or(() -> salaryRepository.findByUser_UserId(u.getUserId()));

            BigDecimal baseSalary = salaryOpt.map(s -> BigDecimal.valueOf(s.getBaseSalary())).orElse(BigDecimal.ZERO);
            int standardWorkingDays = ts.getStandardWorkingDays() > 0 ? ts.getStandardWorkingDays() : 22;
            BigDecimal standardDaysBd = BigDecimal.valueOf(standardWorkingDays);
            BigDecimal hoursInMonth = standardDaysBd.multiply(BigDecimal.valueOf(8));

            // Lương giờ
            BigDecimal hourlyRate = (baseSalary.compareTo(BigDecimal.ZERO) > 0 && hoursInMonth.compareTo(BigDecimal.ZERO) > 0)
                    ? baseSalary.divide(hoursInMonth, 2, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO;

            // Lương cơ bản theo ngày làm thực tế + ngày nghỉ phép có lương (hưởng 100% lương)
            BigDecimal actualWorkedDays = ts.getActualWorkedDays() != null ? ts.getActualWorkedDays() : BigDecimal.ZERO;
            BigDecimal paidLeaveDays = ts.getPaidLeaveDays() != null ? ts.getPaidLeaveDays() : BigDecimal.ZERO;
            BigDecimal payableDays = actualWorkedDays.add(paidLeaveDays);

            BigDecimal basicPay;
            if (payableDays.compareTo(standardDaysBd) >= 0) {
                basicPay = baseSalary;
            } else {
                basicPay = baseSalary.multiply(payableDays).divide(standardDaysBd, 2, RoundingMode.HALF_UP);
            }

            // Lương tăng ca (totalPaidOtHours đã nhân hệ số luật định)
            BigDecimal paidOtHours = ts.getTotalPaidOtHours() != null ? ts.getTotalPaidOtHours() : BigDecimal.ZERO;
            BigDecimal overtimePay = hourlyRate.multiply(paidOtHours).setScale(2, RoundingMode.HALF_UP);

            BigDecimal allowancePay = BigDecimal.ZERO;
            BigDecimal bonusPay = BigDecimal.ZERO;
            BigDecimal otherDeduction = BigDecimal.ZERO;

            // Tổng thu nhập Gross
            BigDecimal grossPay = basicPay.add(overtimePay).add(allowancePay).add(bonusPay);

            // Bảo hiểm người lao động (10.5% lương cơ sở)
            BigDecimal insuranceDeduction = baseSalary.multiply(BigDecimal.valueOf(0.105)).setScale(2, RoundingMode.HALF_UP);

            // Thuế TNCN (sau giảm trừ gia cảnh bản thân 11 triệu)
            BigDecimal taxableIncome = grossPay.subtract(insuranceDeduction).subtract(BigDecimal.valueOf(11_000_000));
            BigDecimal taxDeduction = calculatePitTax(taxableIncome);

            // Tổng khấu trừ & Thực nhận Net
            BigDecimal totalDeduction = insuranceDeduction.add(taxDeduction).add(otherDeduction);
            BigDecimal netPay = grossPay.subtract(totalDeduction);

            Payroll payroll = Payroll.builder()
                    .user(u)
                    .timesheet(ts)
                    .periodMonth(month)
                    .periodYear(year)
                    .baseSalary(baseSalary)
                    .hourlyRate(hourlyRate)
                    .basicPay(basicPay)
                    .overtimePay(overtimePay)
                    .allowancePay(allowancePay)
                    .bonusPay(bonusPay)
                    .grossPay(grossPay)
                    .insuranceDeduction(insuranceDeduction)
                    .taxDeduction(taxDeduction)
                    .otherDeduction(otherDeduction)
                    .totalDeduction(totalDeduction)
                    .netPay(netPay)
                    .status(PayrollStatus.DRAFT)
                    .calculatedAt(now)
                    .build();

            payrollRepository.save(payroll);
            calculatedCount++;
        }

        // Tạo / Cập nhật bản ghi MonthlyPayrollSummary
        recalculateSummary(month, year);

        log.info("Tính toán bảng lương tháng {}/{} thành công cho {} nhân viên (phạm vi: {}). Người thực hiện: {}",
                month, year, calculatedCount, scope, userRole.getUserId());

        return Map.of(
                "msg", "Tính toán bảng lương tháng " + month + "/" + year + " thành công (" + calculatedCount + " nhân viên)",
                "calculatedCount", calculatedCount,
                "scope", scope,
                "status", PayrollStatus.DRAFT.name()
        );
    }

    // =========================================================================
    // 4. KẾ TOÁN ĐIỀU CHỈNH LƯƠNG (EDIT KHI DRAFT)
    // =========================================================================

    @Transactional
    public CompanyPayrollResponse editPayroll(UUID payrollId, EditPayrollRequest request, UserRole userRole) {
        validatePayrollManagementPermission(userRole);

        Payroll payroll = payrollRepository.findById(payrollId)
                .orElseThrow(() -> new PayrollException(PayrollErrorCode.PAYROLL_NOT_FOUND, "Không tìm thấy bản ghi bảng lương"));

        if (payroll.getStatus() != PayrollStatus.DRAFT) {
            throw new PayrollException(PayrollErrorCode.PAYROLL_ALREADY_APPROVED,
                    "Chỉ được phép chỉnh sửa bảng lương khi ở trạng thái DRAFT");
        }

        if (request.getAllowancePay() != null) {
            payroll.setAllowancePay(request.getAllowancePay().setScale(2, RoundingMode.HALF_UP));
        }
        if (request.getBonusPay() != null) {
            payroll.setBonusPay(request.getBonusPay().setScale(2, RoundingMode.HALF_UP));
        }
        if (request.getOtherDeduction() != null) {
            payroll.setOtherDeduction(request.getOtherDeduction().setScale(2, RoundingMode.HALF_UP));
        }
        if (request.getNote() != null) {
            payroll.setNote(request.getNote());
        }

        // Tính lại Gross
        BigDecimal gross = payroll.getBasicPay()
                .add(payroll.getOvertimePay())
                .add(payroll.getAllowancePay())
                .add(payroll.getBonusPay());
        payroll.setGrossPay(gross);

        // Tính lại Thuế TNCN
        BigDecimal tax;
        if (request.getTaxDeduction() != null && request.getTaxDeduction().compareTo(BigDecimal.ZERO) > 0) {
            tax = request.getTaxDeduction().setScale(2, RoundingMode.HALF_UP);
        } else {
            BigDecimal taxableIncome = gross.subtract(payroll.getInsuranceDeduction()).subtract(BigDecimal.valueOf(11_000_000));
            tax = calculatePitTax(taxableIncome);
        }
        payroll.setTaxDeduction(tax);

        // Tính lại Total Deduction & Net
        BigDecimal totalDeduction = payroll.getInsuranceDeduction().add(tax).add(payroll.getOtherDeduction());
        payroll.setTotalDeduction(totalDeduction);
        payroll.setNetPay(gross.subtract(totalDeduction));

        payroll = payrollRepository.save(payroll);

        // Cập nhật lại Summary
        recalculateSummary(payroll.getPeriodMonth(), payroll.getPeriodYear());

        return mapToCompanyResponse(payroll);
    }

    // =========================================================================
    // 5. KẾ TOÁN TRƯỞNG PHÊ DUYỆT (APPROVE)
    // =========================================================================

    @Transactional
    public Map<String, Object> approvePayroll(int month, int year, UserRole userRole) {
        validateChiefAccountantPermission(userRole);

        List<Payroll> payrolls = payrollRepository.findByPeriodMonthAndPeriodYear(month, year);
        if (payrolls.isEmpty()) {
            throw new PayrollException(PayrollErrorCode.PAYROLL_NOT_FOUND,
                    "Không tìm thấy bảng lương tháng " + month + "/" + year);
        }

        LocalDateTime now = LocalDateTime.now();
        for (Payroll p : payrolls) {
            if (p.getStatus() == PayrollStatus.PAID) {
                throw new PayrollException(PayrollErrorCode.PAYROLL_ALREADY_PAID,
                        "Bảng lương tháng " + month + "/" + year + " đã được thanh toán, không thể phê duyệt lại.");
            }
            p.setStatus(PayrollStatus.APPROVED);
            p.setApprovedAt(now);
        }
        payrollRepository.saveAll(payrolls);

        monthlyPayrollSummaryRepository.findByPeriodMonthAndPeriodYear(month, year)
                .ifPresent(s -> {
                    s.setStatus(PayrollStatus.APPROVED);
                    s.setApprovedBy(userRole.getUserId());
                    s.setApprovedAt(now);
                    monthlyPayrollSummaryRepository.save(s);
                });

        log.info("Kế toán trưởng {} đã phê duyệt bảng lương tháng {}/{}", userRole.getUserId(), month, year);

        return Map.of(
                "msg", "Phê duyệt bảng lương tháng " + month + "/" + year + " thành công",
                "approvedCount", payrolls.size(),
                "status", PayrollStatus.APPROVED.name()
        );
    }

    // =========================================================================
    // 6. KẾ TOÁN XÁC NHẬN CHI TRẢ (MARK AS PAID)
    // =========================================================================

    @Transactional
    public Map<String, Object> markAsPaid(int month, int year, UserRole userRole) {
        validatePayrollManagementPermission(userRole);

        List<Payroll> payrolls = payrollRepository.findByPeriodMonthAndPeriodYear(month, year);
        if (payrolls.isEmpty()) {
            throw new PayrollException(PayrollErrorCode.PAYROLL_NOT_FOUND,
                    "Không tìm thấy bảng lương tháng " + month + "/" + year);
        }

        LocalDateTime now = LocalDateTime.now();
        for (Payroll p : payrolls) {
            if (p.getStatus() == PayrollStatus.DRAFT) {
                throw new PayrollException(PayrollErrorCode.INSUFFICIENT_PERMISSION,
                        "Bảng lương tháng " + month + "/" + year + " chưa được Kế toán trưởng phê duyệt, không thể chi trả.");
            }
            p.setStatus(PayrollStatus.PAID);
            p.setPaidAt(now);
        }
        payrollRepository.saveAll(payrolls);

        monthlyPayrollSummaryRepository.findByPeriodMonthAndPeriodYear(month, year)
                .ifPresent(s -> {
                    s.setStatus(PayrollStatus.PAID);
                    monthlyPayrollSummaryRepository.save(s);
                });

        log.info("Kế toán {} đã xác nhận chi trả bảng lương tháng {}/{}", userRole.getUserId(), month, year);

        return Map.of(
                "msg", "Xác nhận chi trả bảng lương tháng " + month + "/" + year + " thành công",
                "paidCount", payrolls.size(),
                "status", PayrollStatus.PAID.name()
        );
    }

    // =========================================================================
    // HELPER TÍNH TOÁN & VALIDATION
    // =========================================================================

    public BigDecimal calculatePitTax(BigDecimal taxableIncome) {
        if (taxableIncome == null || taxableIncome.compareTo(BigDecimal.ZERO) <= 0) {
            return BigDecimal.ZERO;
        }

        double income = taxableIncome.doubleValue();
        double tax;

        // Biểu thuế lũy tiến từng phần 7 bậc chuẩn Việt Nam
        if (income <= 5_000_000) {
            tax = income * 0.05;
        } else if (income <= 10_000_000) {
            tax = income * 0.10 - 250_000;
        } else if (income <= 18_000_000) {
            tax = income * 0.15 - 750_000;
        } else if (income <= 32_000_000) {
            tax = income * 0.20 - 1_650_000;
        } else if (income <= 52_000_000) {
            tax = income * 0.25 - 3_250_000;
        } else if (income <= 80_000_000) {
            tax = income * 0.30 - 5_850_000;
        } else {
            tax = income * 0.35 - 9_850_000;
        }

        return BigDecimal.valueOf(Math.max(0, tax)).setScale(2, RoundingMode.HALF_UP);
    }

    private void recalculateSummary(int month, int year) {
        List<Payroll> payrolls = payrollRepository.findByPeriodMonthAndPeriodYear(month, year);
        if (payrolls.isEmpty()) return;

        BigDecimal totalGross = BigDecimal.ZERO;
        BigDecimal totalNet = BigDecimal.ZERO;
        BigDecimal totalBasic = BigDecimal.ZERO;
        BigDecimal totalOt = BigDecimal.ZERO;
        BigDecimal totalBonus = BigDecimal.ZERO;
        BigDecimal totalAllowance = BigDecimal.ZERO;
        BigDecimal totalTax = BigDecimal.ZERO;
        BigDecimal totalEmpInsurance = BigDecimal.ZERO;
        BigDecimal sumBaseSalary = BigDecimal.ZERO;

        for (Payroll p : payrolls) {
            totalGross = totalGross.add(p.getGrossPay());
            totalNet = totalNet.add(p.getNetPay());
            totalBasic = totalBasic.add(p.getBasicPay());
            totalOt = totalOt.add(p.getOvertimePay());
            totalBonus = totalBonus.add(p.getBonusPay());
            totalAllowance = totalAllowance.add(p.getAllowancePay());
            totalTax = totalTax.add(p.getTaxDeduction());
            totalEmpInsurance = totalEmpInsurance.add(p.getInsuranceDeduction());
            sumBaseSalary = sumBaseSalary.add(p.getBaseSalary());
        }

        // Bảo hiểm công ty đóng (21.5%) & Kinh phí công đoàn (2%)
        BigDecimal totalCompInsurance = sumBaseSalary.multiply(BigDecimal.valueOf(0.215)).setScale(2, RoundingMode.HALF_UP);
        BigDecimal totalUnionFee = sumBaseSalary.multiply(BigDecimal.valueOf(0.02)).setScale(2, RoundingMode.HALF_UP);
        BigDecimal totalCompanyCost = totalGross.add(totalCompInsurance).add(totalUnionFee);

        MonthlyPayrollSummary summary = monthlyPayrollSummaryRepository.findByPeriodMonthAndPeriodYear(month, year)
                .orElseGet(() -> MonthlyPayrollSummary.builder()
                        .periodMonth(month)
                        .periodYear(year)
                        .build());

        summary.setTotalEmployees(payrolls.size());
        summary.setTotalGrossPay(totalGross);
        summary.setTotalNetPay(totalNet);
        summary.setTotalBasicPay(totalBasic);
        summary.setTotalOvertimePay(totalOt);
        summary.setTotalBonusPay(totalBonus);
        summary.setTotalAllowancePay(totalAllowance);
        summary.setTotalPersonalIncomeTax(totalTax);
        summary.setTotalEmployeeInsurance(totalEmpInsurance);
        summary.setTotalCompanyInsurance(totalCompInsurance);
        summary.setTotalUnionFee(totalUnionFee);
        summary.setTotalCompanyCost(totalCompanyCost);

        if (summary.getStatus() == null) {
            summary.setStatus(PayrollStatus.DRAFT);
        }

        monthlyPayrollSummaryRepository.save(summary);
    }

    /**
     * Nhân viên có khớp bộ lọc đang xem không. Dùng lại đúng luật của
     * {@link PayrollSpecification#filterForCompany} (keyword + phòng ban) để
     * "Tính bảng lương" khớp với những dòng đang hiển thị.
     */
    private boolean matchesFilter(User u, CompanyPayrollFilterRequest filter) {
        if (u == null) return false;
        if (filter == null) return true;

        String keyword = filter.getKeyword();
        if (keyword != null && !keyword.isBlank()) {
            String kw = keyword.trim().toLowerCase();
            String code = u.getEmployeeCode() != null ? u.getEmployeeCode().toLowerCase() : "";
            String first = u.getFirstName() != null ? u.getFirstName().toLowerCase() : "";
            String last = u.getLastName() != null ? u.getLastName().toLowerCase() : "";
            if (!code.contains(kw) && !first.contains(kw) && !last.contains(kw)) return false;
        }

        List<String> departments = filter.getDepartmentNames();
        if (departments != null && !departments.isEmpty()) {
            String dept = (u.getDepartment() != null && u.getDepartment().getName() != null)
                    ? u.getDepartment().getName() : "";
            if (!departments.contains(dept)) return false;
        }

        return true;
    }

    private void validatePayrollManagementPermission(UserRole userRole) {
        String dept = userRole.getDepartment() != null ? userRole.getDepartment().toLowerCase() : "";
        String job = userRole.getJob() != null ? userRole.getJob().toLowerCase() : "";

        boolean isExecutive = "executive leadership".equals(dept);
        boolean isAccountingDept = dept.contains("accounting") || dept.contains("finance") || dept.contains("tài chính") || dept.contains("kế toán");
        boolean isAccountantJob = job.contains("accountant") || job.contains("kế toán");

        if (!isExecutive && !isAccountingDept && !isAccountantJob
                && !permissionService.hasPermission(userRole.getUserId(), PermissionKey.PAYROLL_MANAGE)) {
            throw new PayrollException(PayrollErrorCode.INSUFFICIENT_PERMISSION,
                    "Chỉ nhân viên Kế toán hoặc Ban Giám Đốc mới có quyền quản lý bảng lương toàn công ty");
        }
    }

    private void validateChiefAccountantPermission(UserRole userRole) {
        String dept = userRole.getDepartment() != null ? userRole.getDepartment().toLowerCase() : "";
        String job = userRole.getJob() != null ? userRole.getJob().toLowerCase() : "";

        boolean isExecutive = "executive leadership".equals(dept);
        boolean isFinanceOrAccounting = dept.contains("accounting") || dept.contains("finance") || dept.contains("tài chính") || dept.contains("kế toán");
        boolean isHead = job.contains("head") || job.contains("trưởng") || job.contains("manager") || job.contains("lead");
        boolean isChiefAccountant = job.contains("chief accountant")
                || job.contains("kế toán trưởng")
                || (isHead && isFinanceOrAccounting);

        if (!isExecutive && !isChiefAccountant
                && !permissionService.hasPermission(userRole.getUserId(), PermissionKey.PAYROLL_MANAGE)) {
            throw new PayrollException(PayrollErrorCode.INSUFFICIENT_PERMISSION,
                    "Chỉ Kế toán trưởng hoặc Ban Giám Đốc mới có quyền phê duyệt bảng lương toàn công ty");
        }
    }

    // =========================================================================
    // MAPPERS
    // =========================================================================

    private StaffPayrollResponse mapToStaffResponse(Payroll p) {
        MonthlyTimesheet ts = p.getTimesheet();
        return StaffPayrollResponse.builder()
                .payrollId(p.getPayrollId())
                .periodMonth(p.getPeriodMonth())
                .periodYear(p.getPeriodYear())
                .baseSalary(p.getBaseSalary())
                .hourlyRate(p.getHourlyRate())
                .standardWorkingDays(ts != null ? ts.getStandardWorkingDays() : 0)
                .actualWorkedDays(ts != null ? ts.getActualWorkedDays() : BigDecimal.ZERO)
                .actualWorkHours(ts != null ? ts.getActualWorkHours() : BigDecimal.ZERO)
                .paidOvertimeHours(ts != null ? ts.getTotalPaidOtHours() : BigDecimal.ZERO)
                .basicPay(p.getBasicPay())
                .overtimePay(p.getOvertimePay())
                .allowancePay(p.getAllowancePay())
                .bonusPay(p.getBonusPay())
                .grossPay(p.getGrossPay())
                .insuranceDeduction(p.getInsuranceDeduction())
                .taxDeduction(p.getTaxDeduction())
                .otherDeduction(p.getOtherDeduction())
                .totalDeduction(p.getTotalDeduction())
                .netPay(p.getNetPay())
                .status(p.getStatus())
                .note(p.getNote())
                .calculatedAt(p.getCalculatedAt())
                .paidAt(p.getPaidAt())
                .build();
    }

    private CompanyPayrollResponse mapToCompanyResponse(Payroll p) {
        User u = p.getUser();
        MonthlyTimesheet ts = p.getTimesheet();

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

        return CompanyPayrollResponse.builder()
                .payrollId(p.getPayrollId())
                .userId(userId)
                .employeeCode(empCode)
                .fullName(fullName)
                .department(deptName)
                .job(jobTitle)
                .periodMonth(p.getPeriodMonth())
                .periodYear(p.getPeriodYear())
                .baseSalary(p.getBaseSalary())
                .hourlyRate(p.getHourlyRate())
                .standardWorkingDays(ts != null ? ts.getStandardWorkingDays() : 0)
                .actualWorkedDays(ts != null ? ts.getActualWorkedDays() : BigDecimal.ZERO)
                .actualWorkHours(ts != null ? ts.getActualWorkHours() : BigDecimal.ZERO)
                .paidOvertimeHours(ts != null ? ts.getTotalPaidOtHours() : BigDecimal.ZERO)
                .basicPay(p.getBasicPay())
                .overtimePay(p.getOvertimePay())
                .allowancePay(p.getAllowancePay())
                .bonusPay(p.getBonusPay())
                .grossPay(p.getGrossPay())
                .insuranceDeduction(p.getInsuranceDeduction())
                .taxDeduction(p.getTaxDeduction())
                .otherDeduction(p.getOtherDeduction())
                .totalDeduction(p.getTotalDeduction())
                .netPay(p.getNetPay())
                .status(p.getStatus())
                .note(p.getNote())
                .calculatedAt(p.getCalculatedAt())
                .approvedAt(p.getApprovedAt())
                .paidAt(p.getPaidAt())
                .build();
    }

    private MonthlyPayrollSummaryResponse mapToSummaryResponse(MonthlyPayrollSummary s) {
        return MonthlyPayrollSummaryResponse.builder()
                .summaryId(s.getSummaryId())
                .periodMonth(s.getPeriodMonth())
                .periodYear(s.getPeriodYear())
                .totalEmployees(s.getTotalEmployees())
                .totalGrossPay(s.getTotalGrossPay())
                .totalNetPay(s.getTotalNetPay())
                .totalBasicPay(s.getTotalBasicPay())
                .totalOvertimePay(s.getTotalOvertimePay())
                .totalBonusPay(s.getTotalBonusPay())
                .totalAllowancePay(s.getTotalAllowancePay())
                .totalPersonalIncomeTax(s.getTotalPersonalIncomeTax())
                .totalEmployeeInsurance(s.getTotalEmployeeInsurance())
                .totalCompanyInsurance(s.getTotalCompanyInsurance())
                .totalUnionFee(s.getTotalUnionFee())
                .totalCompanyCost(s.getTotalCompanyCost())
                .status(s.getStatus())
                .approvedBy(s.getApprovedBy())
                .approvedAt(s.getApprovedAt())
                .createdAt(s.getCreatedAt())
                .build();
    }

    // =========================================================================
    // EXCEL GENERATORS
    // =========================================================================

    private byte[] generateStaffPayrollExcel(List<Payroll> list) {
        try (Workbook workbook = new XSSFWorkbook(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Sheet sheet = workbook.createSheet("Phieu Luong Ca Nhan");

            CellStyle headerStyle = createHeaderCellStyle(workbook);
            String[] columns = {
                "STT", "Kỳ Lương", "Trạng Thái", "Lương Cơ Sở", "Lương Theo Giờ",
                "Ngày Chuẩn", "Ngày Làm Thực Tế", "Giờ Làm Thực Tế", "Giờ OT Quy Đổi",
                "Lương Cơ Bản", "Lương Tăng Ca", "Phụ Cấp", "Tiền Thưởng",
                "Tổng Thu Nhập (Gross)", "Bảo Hiểm (10.5%)", "Thuế TNCN", "Giảm Trừ Khác",
                "Tổng Khấu Trừ", "Thực Nhận (Net)", "Ghi Chú"
            };

            Row headerRow = sheet.createRow(0);
            for (int i = 0; i < columns.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(columns[i]);
                cell.setCellStyle(headerStyle);
            }

            int rowIdx = 1;
            for (Payroll p : list) {
                Row row = sheet.createRow(rowIdx);
                MonthlyTimesheet ts = p.getTimesheet();

                row.createCell(0).setCellValue(rowIdx);
                row.createCell(1).setCellValue(p.getPeriodMonth() + "/" + p.getPeriodYear());
                row.createCell(2).setCellValue(p.getStatus() != null ? p.getStatus().name() : "");
                row.createCell(3).setCellValue(p.getBaseSalary() != null ? p.getBaseSalary().doubleValue() : 0.0);
                row.createCell(4).setCellValue(p.getHourlyRate() != null ? p.getHourlyRate().doubleValue() : 0.0);
                row.createCell(5).setCellValue(ts != null ? ts.getStandardWorkingDays() : 0);
                row.createCell(6).setCellValue(ts != null && ts.getActualWorkedDays() != null ? ts.getActualWorkedDays().doubleValue() : 0.0);
                row.createCell(7).setCellValue(ts != null && ts.getActualWorkHours() != null ? ts.getActualWorkHours().doubleValue() : 0.0);
                row.createCell(8).setCellValue(ts != null && ts.getTotalPaidOtHours() != null ? ts.getTotalPaidOtHours().doubleValue() : 0.0);
                row.createCell(9).setCellValue(p.getBasicPay() != null ? p.getBasicPay().doubleValue() : 0.0);
                row.createCell(10).setCellValue(p.getOvertimePay() != null ? p.getOvertimePay().doubleValue() : 0.0);
                row.createCell(11).setCellValue(p.getAllowancePay() != null ? p.getAllowancePay().doubleValue() : 0.0);
                row.createCell(12).setCellValue(p.getBonusPay() != null ? p.getBonusPay().doubleValue() : 0.0);
                row.createCell(13).setCellValue(p.getGrossPay() != null ? p.getGrossPay().doubleValue() : 0.0);
                row.createCell(14).setCellValue(p.getInsuranceDeduction() != null ? p.getInsuranceDeduction().doubleValue() : 0.0);
                row.createCell(15).setCellValue(p.getTaxDeduction() != null ? p.getTaxDeduction().doubleValue() : 0.0);
                row.createCell(16).setCellValue(p.getOtherDeduction() != null ? p.getOtherDeduction().doubleValue() : 0.0);
                row.createCell(17).setCellValue(p.getTotalDeduction() != null ? p.getTotalDeduction().doubleValue() : 0.0);
                row.createCell(18).setCellValue(p.getNetPay() != null ? p.getNetPay().doubleValue() : 0.0);
                row.createCell(19).setCellValue(p.getNote() != null ? p.getNote() : "");
                rowIdx++;
            }

            for (int i = 0; i < columns.length; i++) {
                sheet.autoSizeColumn(i);
            }

            workbook.write(out);
            return out.toByteArray();
        } catch (IOException e) {
            log.error("Failed to generate Staff Payroll Excel", e);
            throw new RuntimeErrorException(null);
        }
    }

    private byte[] generateCompanyPayrollExcel(List<Payroll> list) {
        try (Workbook workbook = new XSSFWorkbook(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Sheet sheet = workbook.createSheet("Bang Luong Toan Cong Ty");

            CellStyle headerStyle = createHeaderCellStyle(workbook);
            String[] columns = {
                "STT", "Mã NV", "Họ và Tên", "Phòng Ban", "Chức Vụ",
                "Kỳ Lương", "Trạng Thái", "Lương Cơ Sở", "Lương Giờ",
                "Ngày Chuẩn", "Ngày Làm Thực Tế", "Giờ OT Quy Đổi",
                "Lương Cơ Bản", "Lương Tăng Ca", "Phụ Cấp", "Tiền Thưởng",
                "Tổng Thu Nhập (Gross)", "Bảo Hiểm NLĐ (10.5%)", "Thuế TNCN", "Giảm Trừ Khác",
                "Tổng Khấu Trừ", "Thực Nhận (Net)", "Ghi Chú"
            };

            Row headerRow = sheet.createRow(0);
            for (int i = 0; i < columns.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(columns[i]);
                cell.setCellStyle(headerStyle);
            }

            int rowIdx = 1;
            for (Payroll p : list) {
                Row row = sheet.createRow(rowIdx);
                User u = p.getUser();
                MonthlyTimesheet ts = p.getTimesheet();

                row.createCell(0).setCellValue(rowIdx);
                row.createCell(1).setCellValue(u != null && u.getEmployeeCode() != null ? u.getEmployeeCode() : "");
                row.createCell(2).setCellValue(u != null ? ((u.getFirstName() != null ? u.getFirstName() : "") + " " + (u.getLastName() != null ? u.getLastName() : "")).trim() : "");
                row.createCell(3).setCellValue(u != null && u.getDepartment() != null ? u.getDepartment().getName() : "");
                row.createCell(4).setCellValue(u != null && u.getJob() != null ? u.getJob().getTitle() : "");
                row.createCell(5).setCellValue(p.getPeriodMonth() + "/" + p.getPeriodYear());
                row.createCell(6).setCellValue(p.getStatus() != null ? p.getStatus().name() : "");
                row.createCell(7).setCellValue(p.getBaseSalary() != null ? p.getBaseSalary().doubleValue() : 0.0);
                row.createCell(8).setCellValue(p.getHourlyRate() != null ? p.getHourlyRate().doubleValue() : 0.0);
                row.createCell(9).setCellValue(ts != null ? ts.getStandardWorkingDays() : 0);
                row.createCell(10).setCellValue(ts != null && ts.getActualWorkedDays() != null ? ts.getActualWorkedDays().doubleValue() : 0.0);
                row.createCell(11).setCellValue(ts != null && ts.getTotalPaidOtHours() != null ? ts.getTotalPaidOtHours().doubleValue() : 0.0);
                row.createCell(12).setCellValue(p.getBasicPay() != null ? p.getBasicPay().doubleValue() : 0.0);
                row.createCell(13).setCellValue(p.getOvertimePay() != null ? p.getOvertimePay().doubleValue() : 0.0);
                row.createCell(14).setCellValue(p.getAllowancePay() != null ? p.getAllowancePay().doubleValue() : 0.0);
                row.createCell(15).setCellValue(p.getBonusPay() != null ? p.getBonusPay().doubleValue() : 0.0);
                row.createCell(16).setCellValue(p.getGrossPay() != null ? p.getGrossPay().doubleValue() : 0.0);
                row.createCell(17).setCellValue(p.getInsuranceDeduction() != null ? p.getInsuranceDeduction().doubleValue() : 0.0);
                row.createCell(18).setCellValue(p.getTaxDeduction() != null ? p.getTaxDeduction().doubleValue() : 0.0);
                row.createCell(19).setCellValue(p.getOtherDeduction() != null ? p.getOtherDeduction().doubleValue() : 0.0);
                row.createCell(20).setCellValue(p.getTotalDeduction() != null ? p.getTotalDeduction().doubleValue() : 0.0);
                row.createCell(21).setCellValue(p.getNetPay() != null ? p.getNetPay().doubleValue() : 0.0);
                row.createCell(22).setCellValue(p.getNote() != null ? p.getNote() : "");
                rowIdx++;
            }

            for (int i = 0; i < columns.length; i++) {
                sheet.autoSizeColumn(i);
            }

            workbook.write(out);
            return out.toByteArray();
        } catch (IOException e) {
            log.error("Failed to generate Company Payroll Excel", e);
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
