package com.minhtrung.hrm.performance.services;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.minhtrung.hrm.employees.dtos.internals.UserRole;
import com.minhtrung.hrm.employees.entities.User;
import com.minhtrung.hrm.employees.repositories.UserRepository;
import com.minhtrung.hrm.performance.dtos.requests.ManagerScoreRequest;
import com.minhtrung.hrm.performance.dtos.requests.PerformanceFilterRequest;
import com.minhtrung.hrm.performance.dtos.requests.ScoreItemRequest;
import com.minhtrung.hrm.performance.dtos.requests.SelfSubmitRequest;
import com.minhtrung.hrm.performance.dtos.responses.PerformanceOverviewResponse;
import com.minhtrung.hrm.performance.dtos.responses.PerformanceReviewResponse;
import com.minhtrung.hrm.performance.entities.PerformanceReview;
import com.minhtrung.hrm.performance.entities.PerformanceScore;
import com.minhtrung.hrm.performance.enums.PerformanceErrorCode;
import com.minhtrung.hrm.performance.enums.PeriodType;
import com.minhtrung.hrm.performance.enums.ReviewStatus;
import com.minhtrung.hrm.performance.exceptions.PerformanceException;
import com.minhtrung.hrm.performance.repositories.PerformanceReviewRepository;
import com.minhtrung.hrm.performance.repositories.PerformanceScoreRepository;
import com.minhtrung.hrm.performance.specifications.PerformanceSpecification;
import com.minhtrung.hrm.permissions.enums.PermissionKey;
import com.minhtrung.hrm.permissions.services.PermissionService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class PerformanceService {

    // 10 tieu chi Form 6 [base.vn] — seed cung khi tao bai
    private static final String[][] CRITERIA = {
        {"KT", "Kiến thức công việc"}, {"CL", "Chất lượng công việc"},
        {"ST", "Tư duy sáng tạo"}, {"CC", "Chấm công/chuyên cần"},
        {"NS", "Năng suất làm việc"}, {"GT", "Giao tiếp"},
        {"TT", "Trung thực/đáng tin cậy"}, {"GQVD", "Giải quyết vấn đề"},
        {"TN", "Trách nhiệm công việc"}, {"QL", "Quản lý công việc"},
    };

    private final PerformanceReviewRepository reviewRepository;
    private final PerformanceScoreRepository scoreRepository;
    private final UserRepository userRepository;
    private final PermissionService permissionService;

    // ─── LAZY-CREATE: mo trang la co bai DRAFT, khong cron ───
    @Transactional
    public PerformanceReviewResponse getOrCreate(UserRole role, String periodTypeStr, Integer year, Integer month) {
        PeriodType type;
        try {
            type = periodTypeStr == null ? PeriodType.MONTHLY : PeriodType.valueOf(periodTypeStr.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new PerformanceException(PerformanceErrorCode.INVALID_STATUS, "Loại kỳ chỉ nhận MONTHLY hoặc YEARLY");
        }
        LocalDate now = LocalDate.now();
        int y = year != null ? year : now.getYear();
        // ponytail: YEARLY dung month=0 de UNIQUE (user, type, month, year) van bat trung
        int m = type == PeriodType.YEARLY ? 0 : (month != null ? month : now.getMonthValue());
        if (type == PeriodType.MONTHLY && (m < 1 || m > 12)) {
            throw new PerformanceException(PerformanceErrorCode.INVALID_STATUS, "Tháng phải từ 1-12");
        }

        PerformanceReview review = reviewRepository
                .findByUser_UserIdAndPeriodTypeAndPeriodMonthAndPeriodYear(role.getUserId(), type, m, y)
                .orElseGet(() -> {
                    User userProxy = userRepository.getReferenceById(role.getUserId());
                    PerformanceReview r = PerformanceReview.builder()
                            .user(userProxy).periodType(type).periodMonth(m).periodYear(y)
                            .status(ReviewStatus.DRAFT).build();
                    r = reviewRepository.save(r);
                    List<PerformanceScore> seeds = new ArrayList<>();
                    for (int i = 0; i < CRITERIA.length; i++) {
                        seeds.add(PerformanceScore.builder().review(r)
                                .criterionCode(CRITERIA[i][0]).criterionText(CRITERIA[i][1])
                                .sortOrder(i + 1).build());
                    }
                    scoreRepository.saveAll(seeds);
                    return r;
                });
        return toResponse(review);
    }

    @Transactional
    public PerformanceReviewResponse submitSelf(UUID currentUserId, UUID reviewId, SelfSubmitRequest req) {
        PerformanceReview review = findOrThrow(reviewId);
        if (!review.getUser().getUserId().equals(currentUserId)) {
            throw new PerformanceException(PerformanceErrorCode.NOT_RECORD_OWNER, "Chỉ chủ bài đánh giá mới được tự chấm");
        }
        if (review.getStatus() != ReviewStatus.DRAFT) {
            throw new PerformanceException(PerformanceErrorCode.INVALID_STATUS, "Bài này đã nộp, không sửa được nữa");
        }
        List<PerformanceScore> scores = scoresOf(reviewId);
        applyScores(scores, req.getScores(), true);
        review.setAvgSelf(avg(scores, true));
        review.setStatus(ReviewStatus.SELF_SUBMITTED);
        review.setSelfAt(LocalDateTime.now());
        log.info("Nhan vien tu cham xong. ReviewId: {}, UserId: {}", reviewId, currentUserId);
        return toResponse(review);
    }

    @Transactional
    public PerformanceReviewResponse scoreManager(UUID reviewId, ManagerScoreRequest req, UserRole role) {
        PerformanceReview review = findOrThrow(reviewId);
        if (review.getUser().getUserId().equals(role.getUserId())) {
            throw new PerformanceException(PerformanceErrorCode.SELF_APPROVAL_NOT_ALLOWED, "Không được tự chấm điểm chính thức cho chính mình");
        }
        if (review.getStatus() != ReviewStatus.SELF_SUBMITTED) {
            throw new PerformanceException(PerformanceErrorCode.INVALID_STATUS, "Chỉ chấm khi nhân viên đã nộp tự đánh giá");
        }
        assertCanScore(role, review);

        List<PerformanceScore> scores = scoresOf(reviewId);
        applyScores(scores, req.getScores(), false);
        review.setEvaluator(userRepository.getReferenceById(role.getUserId()));
        review.setAvgManager(avg(scores, false));
        review.setOverallSummary(req.getOverallSummary());
        review.setNextGoals(req.getNextGoals());
        review.setStatus(ReviewStatus.MANAGER_SCORED);
        review.setManagerAt(LocalDateTime.now());
        log.info("Manager cham xong. ReviewId: {}, EvaluatorId: {}", reviewId, role.getUserId());
        return toResponse(review);
    }

    @Transactional
    public PerformanceReviewResponse lock(UUID reviewId, UserRole role) {
        PerformanceReview review = findOrThrow(reviewId);
        // Lock = khoa so: chi nguoi co APPROVE toan cong ty (HR/Ban Giam Doc/SUPER_ADMIN)
        if (!permissionService.hasPermission(role.getUserId(), PermissionKey.EVALUATION_APPROVE)) {
            throw new PerformanceException(PerformanceErrorCode.INSUFFICIENT_PERMISSION, "Chỉ phòng Nhân sự hoặc Ban Giám Đốc mới được khóa sổ");
        }
        if (review.getStatus() != ReviewStatus.MANAGER_SCORED) {
            throw new PerformanceException(PerformanceErrorCode.INVALID_STATUS, "Chỉ khóa khi manager đã chấm xong");
        }
        User u = review.getUser();
        review.setRevieweeName(u.getFirstName() + " " + u.getLastName());
        review.setDepartmentName(u.getDepartment() != null ? u.getDepartment().getName() : null);
        if (review.getEvaluator() != null) {
            User e = review.getEvaluator();
            review.setEvaluatorName(e.getFirstName() + " " + e.getLastName());
        }
        review.setStatus(ReviewStatus.LOCKED);
        review.setLockedBy(role.getUserId());
        review.setLockedAt(LocalDateTime.now());
        log.info("Khoa so danh gia. ReviewId: {}, LockedBy: {}", reviewId, role.getUserId());
        return toResponse(review);
    }

    // ─── KHOA SO HANG LOAT: tick N dong tren bang records, chot 1 lan ───
    // ponytail: 1 tx duy nhat, item loi thi bo qua (ghi skipped) thay vi rollback tat ca; cap 200 id/lan
    @Transactional
    public Map<String, Object> lockBatch(List<UUID> reviewIds, UserRole role) {
        assertIds(reviewIds);
        int locked = 0;
        List<Map<String, String>> skipped = new ArrayList<>();
        for (UUID id : reviewIds) {
            try {
                lock(id, role);
                locked++;
            } catch (PerformanceException e) {
                skipped.add(Map.of("reviewId", id.toString(), "reason", e.getMessage()));
            }
        }
        log.info("Khoa so danh gia hang loat. Locked: {}, Skipped: {}, By: {}", locked, skipped.size(), role.getUserId());
        return Map.of("locked", locked, "skipped", skipped);
    }

    // ─── XUAT EXCEL: sheet Tong hop + 1 sheet/bai theo mau BANG DANH GIA ───
    @Transactional(readOnly = true)
    public byte[] exportReviewsToExcel(List<UUID> reviewIds, UserRole role) {
        assertIds(reviewIds);
        List<PerformanceReviewResponse> rows = reviewIds.stream()
                .map(id -> findOrThrow(id)).peek(r -> assertCanSee(role, r))
                .map(this::toResponse).toList();
        try (Workbook workbook = new XSSFWorkbook(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            writeSummarySheet(workbook, rows);
            for (PerformanceReviewResponse r : rows) writeReviewSheet(workbook, r);
            workbook.write(out);
            return out.toByteArray();
        } catch (IOException e) {
            log.error("Failed to generate performance Excel", e);
            throw new PerformanceException(PerformanceErrorCode.INTERNAL_SERVER_ERROR,
                    "Có lỗi xảy ra khi đang tạo và xuất báo cáo Excel");
        }
    }

    private void assertIds(List<UUID> reviewIds) {
        if (reviewIds == null || reviewIds.isEmpty()) {
            throw new PerformanceException(PerformanceErrorCode.INVALID_STATUS, "Chưa chọn bài đánh giá nào");
        }
        if (reviewIds.size() > 200) {
            throw new PerformanceException(PerformanceErrorCode.INVALID_STATUS, "Mỗi lần chỉ xử lý tối đa 200 bài");
        }
    }

    private void assertCanSee(UserRole role, PerformanceReview review) {
        if (permissionService.hasPermission(role.getUserId(), PermissionKey.EVALUATION_APPROVE)) return;
        String dept = userRepository.findUsersDepartment(review.getUser().getUserId());
        if (role.getDepartment() != null && role.getDepartment().equals(dept)
                && (isManagerOf(role, dept)
                        || permissionService.hasPermission(role.getUserId(), PermissionKey.EVALUATION_APPROVE_DEPT)
                        || permissionService.hasPermission(role.getUserId(), PermissionKey.EVALUATION_VIEW_DEPT))) return;
        throw new PerformanceException(PerformanceErrorCode.INSUFFICIENT_PERMISSION, "Bạn không có quyền xem bài này");
    }

    private void writeSummarySheet(Workbook workbook, List<PerformanceReviewResponse> rows) {
        Sheet sheet = workbook.createSheet("Tổng hợp");
        // ponytail: tat luoi mac dinh cua Excel — chi giu vien minh ke; muon in meme grid thi bat PrintGridlines
        sheet.setDisplayGridlines(false);
        CellStyle header = headerStyle(workbook);
        CellStyle band = headerStyle(workbook);
        String[] columns = {"STT", "Mã NV", "Họ và Tên", "Phòng Ban", "Tự Chấm", "Quản Lý", "Trạng Thái",
                "KT", "CL", "ST", "CC", "NS", "GT", "TT", "GQVD", "TN", "QL"};
        int[] widths = {6, 12, 24, 22, 10, 10, 18, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8};
        Row title = sheet.createRow(0);
        title.createCell(0).setCellValue("TỔNG HỢP ĐÁNH GIÁ (" + rows.size() + " bài)");
        title.getCell(0).setCellStyle(titleStyle(workbook));
        Row b = sheet.createRow(1);
        Cell b0 = b.createCell(0);
        b0.setCellValue("THÔNG TIN CHUNG");
        b0.setCellStyle(band);
        sheet.addMergedRegion(new org.apache.poi.ss.util.CellRangeAddress(1, 1, 0, 6));
        for (int i = 1; i <= 6; i++) b.createCell(i).setCellStyle(band);
        Cell b1 = b.createCell(7);
        b1.setCellValue("ĐIỂM QUẢN LÝ THEO TIÊU CHÍ");
        b1.setCellStyle(band);
        sheet.addMergedRegion(new org.apache.poi.ss.util.CellRangeAddress(1, 1, 7, 16));
        for (int i = 8; i <= 16; i++) b.createCell(i).setCellStyle(band);
        Row h = sheet.createRow(2);
        for (int i = 0; i < columns.length; i++) {
            Cell c = h.createCell(i);
            c.setCellValue(columns[i]);
            c.setCellStyle(header);
        }
        int idx = 3;
        for (int i = 0; i < rows.size(); i++) {
            PerformanceReviewResponse r = rows.get(i);
            Row row = sheet.createRow(idx++);
            row.createCell(0).setCellValue(i + 1);
            row.createCell(1).setCellValue(nz(r.getEmployeeCode()));
            row.createCell(2).setCellValue(nz(r.getRevieweeName()));
            row.createCell(3).setCellValue(nz(r.getDepartment()));
            if (r.getAvgSelf() != null) row.createCell(4).setCellValue(r.getAvgSelf());
            if (r.getAvgManager() != null) row.createCell(5).setCellValue(r.getAvgManager());
            row.createCell(6).setCellValue(statusVi(r.getStatus()));
            Map<String, Integer> mgrByCode = new HashMap<>();
            if (r.getScores() != null) {
                for (PerformanceReviewResponse.ScoreResponse s : r.getScores()) {
                    if (s.getManagerScore() != null) mgrByCode.put(s.getCriterionCode(), s.getManagerScore());
                }
            }
            for (int j = 0; j < CRITERIA.length; j++) {
                Integer v = mgrByCode.get(CRITERIA[j][0]);
                if (v != null) row.createCell(7 + j).setCellValue(v);
            }
        }
        for (int i = 0; i < widths.length; i++) sheet.setColumnWidth(i, widths[i] * 256);
    }

    // Thang diem 1-5 mac dinh (chua co dinh nghia trong DB) — doi text o day neu HR co quy dinh rieng
    private static final String[][] SCORE_LEGEND = {
        {"5", "Xuất sắc", "Vượt trội, tạo ảnh hưởng tích cực, nêu gương cho tập thể."},
        {"4", "Tốt", "Hoàn thành tốt, vượt yêu cầu ở một số mặt."},
        {"3", "Đạt yêu cầu", "Hoàn thành công việc ở mức chấp nhận được."},
        {"2", "Cần cải thiện", "Đáp ứng một phần, còn lỗi thiếu sót cần khắc phục."},
        {"1", "Không đạt", "Không đáp ứng yêu cầu, cần đào tạo lại hoặc xem xét bố trí khác."},
    };

    private void writeReviewSheet(Workbook workbook, PerformanceReviewResponse r) {
        String name = nz(r.getEmployeeCode()).replaceAll("[\\[\\]*?/:\\\\]", "");
        if (name.isEmpty()) name = r.getReviewId().toString().substring(0, 8);
        Sheet sheet = workbook.createSheet(name.substring(0, Math.min(name.length(), 31)));
        sheet.setDisplayGridlines(false);
        CellStyle title = titleStyle(workbook);
        CellStyle band = headerStyle(workbook);
        CellStyle header = headerStyle(workbook);
        CellStyle cell = bordered(workbook, false);
        CellStyle wrapCell = bordered(workbook, true);
        CellStyle noteLabel = workbook.createCellStyle();
        Font noteFont = workbook.createFont();
        noteFont.setItalic(true);
        noteFont.setColor(IndexedColors.GREY_50_PERCENT.getIndex());
        noteLabel.setFont(noteFont);

        int row = 0;
        Row r0 = sheet.createRow(row++);
        r0.createCell(1).setCellValue("Tên đơn vị:");
        r0.createCell(3).setCellValue("CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM");
        Row r1 = sheet.createRow(row++);
        r1.createCell(1).setCellValue("Số hiệu văn bản:");
        r1.createCell(3).setCellValue("Độc lập - Tự do - Hạnh Phúc");
        row++;
        Row rt = sheet.createRow(row++);
        rt.createCell(0).setCellValue("BẢNG ĐÁNH GIÁ THỰC HIỆN CÔNG VIỆC");
        rt.getCell(0).setCellStyle(title);
        sheet.addMergedRegion(new org.apache.poi.ss.util.CellRangeAddress(rt.getRowNum(), rt.getRowNum(), 0, 4));
        Row r4 = sheet.createRow(row++);
        r4.createCell(1).setCellValue("Thời gian đánh giá: T" + r.getPeriodMonth() + "/" + r.getPeriodYear());
        r4.createCell(2).setCellValue("Người đánh giá: " + nz(r.getEvaluatorName()));
        r4.createCell(4).setCellValue("Chức vụ: " + nz(r.getJob()));
        Row r5 = sheet.createRow(row++);
        r5.createCell(2).setCellValue("Nhân viên đánh giá: " + nz(r.getRevieweeName()));
        r5.createCell(4).setCellValue("Chức vụ: " + nz(r.getJob()));
        row++;

        Row b = sheet.createRow(row++);
        Cell b0 = b.createCell(0);
        b0.setCellValue("STT");
        b0.setCellStyle(band);
        Cell b1 = b.createCell(1);
        b1.setCellValue("ĐÁNH GIÁ THEO ĐIỂM");
        b1.setCellStyle(band);
        sheet.addMergedRegion(new org.apache.poi.ss.util.CellRangeAddress(b.getRowNum(), b.getRowNum(), 1, 4));
        for (int i = 2; i <= 4; i++) b.createCell(i).setCellStyle(band);
        Row h = sheet.createRow(row++);
        String[] columns = {"", "TIÊU CHÍ", "TỰ CHẤM", "QUẢN LÝ", "GHI CHÚ"};
        for (int i = 0; i < columns.length; i++) {
            Cell c = h.createCell(i);
            c.setCellValue(columns[i]);
            c.setCellStyle(header);
        }
        List<PerformanceReviewResponse.ScoreResponse> scores = r.getScores() != null ? r.getScores() : List.of();
        for (int i = 0; i < scores.size(); i++) {
            PerformanceReviewResponse.ScoreResponse s = scores.get(i);
            Row d = sheet.createRow(row++);
            Cell stt = d.createCell(0);
            stt.setCellValue(i + 1);
            stt.setCellStyle(cell);
            Cell crit = d.createCell(1);
            crit.setCellValue(nz(s.getCriterionText()));
            crit.setCellStyle(cell);
            Cell self = d.createCell(2);
            if (s.getSelfScore() != null) self.setCellValue(s.getSelfScore());
            self.setCellStyle(cell);
            Cell mgr = d.createCell(3);
            if (s.getManagerScore() != null) mgr.setCellValue(s.getManagerScore());
            mgr.setCellStyle(cell);
            d.createCell(4).setCellStyle(cell);
            Row n = sheet.createRow(row++);
            n.createCell(0).setCellStyle(cell);
            n.createCell(1).setCellValue("Ghi chú");
            n.getCell(1).setCellStyle(noteLabel);
            Cell note = n.createCell(2);
            note.setCellValue(nz(s.getNote()));
            note.setCellStyle(wrapCell);
            sheet.addMergedRegion(new org.apache.poi.ss.util.CellRangeAddress(n.getRowNum(), n.getRowNum(), 2, 4));
            n.createCell(3).setCellStyle(wrapCell);
            n.createCell(4).setCellStyle(wrapCell);
        }
        Row avg = sheet.createRow(row++);
        avg.createCell(0).setCellStyle(cell);
        Cell avgLabel = avg.createCell(1);
        avgLabel.setCellValue("ĐIỂM TRUNG BÌNH");
        avgLabel.setCellStyle(header);
        Cell avgSelf = avg.createCell(2);
        if (r.getAvgSelf() != null) avgSelf.setCellValue(r.getAvgSelf());
        avgSelf.setCellStyle(cell);
        Cell avgMgr = avg.createCell(3);
        if (r.getAvgManager() != null) avgMgr.setCellValue(r.getAvgManager());
        avgMgr.setCellStyle(cell);
        avg.createCell(4).setCellStyle(cell);
        Row sum = sheet.createRow(row++);
        sum.createCell(1).setCellValue("Nhận xét chung: " + nz(r.getOverallSummary()));
        Row goal = sheet.createRow(row++);
        goal.createCell(1).setCellValue("Mục tiêu tiếp theo: " + nz(r.getNextGoals()));
        row++;
        Row leg = sheet.createRow(row++);
        leg.createCell(1).setCellValue("THANG ĐIỂM ĐÁNH GIÁ (1-5):");
        leg.getCell(1).setCellStyle(header);
        for (String[] entry : SCORE_LEGEND) {
            Row lr = sheet.createRow(row++);
            Cell lv = lr.createCell(1);
            lv.setCellValue(entry[0] + " – " + entry[1]);
            lv.setCellStyle(cell);
            Cell ld = lr.createCell(2);
            ld.setCellValue(entry[2]);
            ld.setCellStyle(wrapCell);
            sheet.addMergedRegion(new org.apache.poi.ss.util.CellRangeAddress(lr.getRowNum(), lr.getRowNum(), 2, 4));
            lr.createCell(3).setCellStyle(wrapCell);
            lr.createCell(4).setCellStyle(wrapCell);
        }

        // ponytail: cot dan full chieu rong nhu form mau — muon vua khit giay in thi chinh o day
        sheet.setColumnWidth(0, 6 * 256);
        sheet.setColumnWidth(1, 42 * 256);
        sheet.setColumnWidth(2, 14 * 256);
        sheet.setColumnWidth(3, 14 * 256);
        sheet.setColumnWidth(4, 75 * 256);
    }

    private CellStyle bordered(Workbook workbook, boolean wrap) {
        CellStyle s = workbook.createCellStyle();
        s.setBorderTop(BorderStyle.THIN);
        s.setBorderBottom(BorderStyle.THIN);
        s.setBorderLeft(BorderStyle.THIN);
        s.setBorderRight(BorderStyle.THIN);
        s.setVerticalAlignment(VerticalAlignment.TOP);
        if (wrap) s.setWrapText(true);
        return s;
    }

    private CellStyle titleStyle(Workbook workbook) {
        CellStyle s = workbook.createCellStyle();
        Font f = workbook.createFont();
        f.setBold(true);
        f.setFontHeightInPoints((short) 14);
        f.setColor(IndexedColors.DARK_BLUE.getIndex());
        s.setFont(f);
        s.setAlignment(HorizontalAlignment.CENTER);
        return s;
    }

    private CellStyle headerStyle(Workbook workbook) {
        CellStyle s = workbook.createCellStyle();
        Font f = workbook.createFont();
        f.setBold(true);
        f.setColor(IndexedColors.WHITE.getIndex());
        s.setFont(f);
        s.setFillForegroundColor(IndexedColors.DARK_BLUE.getIndex());
        s.setFillPattern(FillPatternType.SOLID_FOREGROUND);
        s.setAlignment(HorizontalAlignment.CENTER);
        s.setVerticalAlignment(VerticalAlignment.CENTER);
        return s;
    }

    private String nz(String v) {
        return v != null ? v : "";
    }

    private String statusVi(ReviewStatus status) {
        if (status == null) return "";
        return switch (status) {
            case DRAFT -> "Nháp";
            case SELF_SUBMITTED -> "Đã tự đánh giá";
            case MANAGER_SCORED -> "Đã chấm";
            case LOCKED -> "Đã khóa";
        };
    }

    // ─── DANH SACH ───
    @Transactional(readOnly = true)
    public Page<PerformanceReviewResponse> getMyReviews(UUID currentUserId, PerformanceFilterRequest filter, Pageable pageable) {
        return reviewRepository.findAll(PerformanceSpecification.forMyRecords(currentUserId, filter), pageable)
                .map(this::toResponse);
    }

    @Transactional(readOnly = true)
    public Page<PerformanceReviewResponse> getApprovals(UserRole role, PerformanceFilterRequest filter, Pageable pageable) {
        boolean head = role.getJob() != null && role.getJob().startsWith("Department Head");
        boolean exec = "Executive Leadership".equals(role.getDepartment());
        if (!head && !exec
                && !permissionService.hasPermission(role.getUserId(), PermissionKey.EVALUATION_VIEW_DEPT)
                && !permissionService.hasPermission(role.getUserId(), PermissionKey.EVALUATION_APPROVE_DEPT)
                && !permissionService.hasPermission(role.getUserId(), PermissionKey.EVALUATION_APPROVE)) {
            throw new PerformanceException(PerformanceErrorCode.INSUFFICIENT_PERMISSION, "Bạn không có quyền xem đánh giá phòng ban");
        }
        Specification<PerformanceReview> spec = PerformanceSpecification.forApprovals(role, filter);
        return reviewRepository.findAll(spec, pageable).map(this::toResponse);
    }

    @Transactional(readOnly = true)
    public Page<PerformanceReviewResponse> getCompanyRecords(UserRole role, PerformanceFilterRequest filter, Pageable pageable) {
        assertCompanyViewer(role);
        return reviewRepository.findAll(PerformanceSpecification.forCompanyWide(filter), pageable)
                .map(this::toResponse);
    }

    // ─── DASHBOARD: bieu do + tuyen duong (<- dung AVG manager, nguong 4.5/3.0) ───
    @Transactional(readOnly = true)
    public PerformanceOverviewResponse getOverview(UserRole role, Integer year, Integer month, String scope) {
        LocalDate now = LocalDate.now();
        // mac dinh = thang truoc (thang 1 -> thang 12 nam truoc)
        LocalDate prev = now.minusMonths(1);
        int y = year != null ? year : (month != null ? now.getYear() : prev.getYear());
        int m = month != null ? month : prev.getMonthValue();
        boolean company = "company".equalsIgnoreCase(scope);
        if (company) {
            assertCompanyViewer(role);
        } else if (!isManagerOf(role, role.getDepartment())
                && !permissionService.hasPermission(role.getUserId(), PermissionKey.EVALUATION_VIEW_DEPT)
                && !permissionService.hasPermission(role.getUserId(), PermissionKey.EVALUATION_APPROVE_DEPT)
                && !permissionService.hasPermission(role.getUserId(), PermissionKey.EVALUATION_APPROVE)) {
            throw new PerformanceException(PerformanceErrorCode.INSUFFICIENT_PERMISSION, "Bạn không có quyền xem dashboard phòng ban");
        }

        PerformanceFilterRequest f = new PerformanceFilterRequest();
        f.setPeriodType("MONTHLY");
        f.setYear(y);
        f.setMonth(m);
        Specification<PerformanceReview> spec = company
                ? PerformanceSpecification.forCompanyWide(f)
                : PerformanceSpecification.forDeptScope(role.getDepartment(), f);
        // ponytail: overview tinh tren Java thay vi N query aggregate — cong ty vai tram NV la du
        List<PerformanceReview> all = reviewRepository.findAll(spec);
        List<PerformanceReview> scored = all.stream().filter(r -> r.getAvgManager() != null).toList();

        Double avg = scored.isEmpty() ? null
                : Math.round(scored.stream().mapToDouble(PerformanceReview::getAvgManager).average().orElse(0) * 100.0) / 100.0;
        Map<String, Long> byStatus = all.stream()
                .collect(Collectors.groupingBy(r -> r.getStatus().name(), Collectors.counting()));
        Map<String, List<PerformanceReview>> byDept = scored.stream()
                .filter(r -> r.getUser().getDepartment() != null)
                .collect(Collectors.groupingBy(r -> r.getUser().getDepartment().getName()));
        List<PerformanceOverviewResponse.DeptAvg> avgByDept = byDept.entrySet().stream()
                .map(e -> PerformanceOverviewResponse.DeptAvg.builder().department(e.getKey())
                        .avg(Math.round(e.getValue().stream().mapToDouble(PerformanceReview::getAvgManager).average().orElse(0) * 100.0) / 100.0)
                        .count(e.getValue().size()).build())
                .toList();

        return PerformanceOverviewResponse.builder()
                .total(all.size()).avgScore(avg).byStatus(byStatus).avgByDept(avgByDept)
                .excellent(scored.stream().filter(r -> r.getAvgManager() >= 4.5).map(this::toResponse).toList())
                .belowTarget(scored.stream().filter(r -> r.getAvgManager() < 3.0).map(this::toResponse).toList())
                .build();
    }

    // ─── HELPERS ───
    private PerformanceReview findOrThrow(UUID id) {
        return reviewRepository.findById(id).orElseThrow(() ->
                new PerformanceException(PerformanceErrorCode.REVIEW_NOT_FOUND, "Không tìm thấy bài đánh giá"));
    }

    private List<PerformanceScore> scoresOf(UUID reviewId) {
        return scoreRepository.findByReview_ReviewIdOrderBySortOrderAsc(reviewId);
    }

    private void applyScores(List<PerformanceScore> entities, List<ScoreItemRequest> items, boolean self) {
        if (items == null || items.size() != CRITERIA.length) {
            throw new PerformanceException(PerformanceErrorCode.INVALID_SCORE, "Phải chấm đủ 10 tiêu chí");
        }
        Map<String, ScoreItemRequest> byCode = new HashMap<>();
        for (ScoreItemRequest i : items) byCode.put(i.getCriterionCode(), i);
        for (PerformanceScore s : entities) {
            ScoreItemRequest i = byCode.get(s.getCriterionCode());
            if (i == null || i.getScore() == null) {
                throw new PerformanceException(PerformanceErrorCode.INVALID_SCORE, "Thiếu điểm tiêu chí " + s.getCriterionCode());
            }
            if (self) s.setSelfScore(i.getScore());
            else s.setManagerScore(i.getScore());
            if (i.getNote() != null) s.setNote(i.getNote());
        }
        scoreRepository.saveAll(entities);
    }

    private Double avg(List<PerformanceScore> scores, boolean self) {
        double v = scores.stream().mapToInt(s -> self ? s.getSelfScore() : s.getManagerScore()).average().orElse(0);
        return Math.round(v * 100.0) / 100.0;
    }

    private boolean isManagerOf(UserRole role, String dept) {
        return role.getDepartment() != null && role.getDepartment().equals(dept)
                && role.getJob() != null && role.getJob().startsWith("Department Head");
    }

    // Copy luat duyet Leave: truong phong cung phong / exec / grant — kem guard Ban Giam Doc
    private void assertCanScore(UserRole role, PerformanceReview review) {
        UUID revieweeId = review.getUser().getUserId();
        String revieweeDept = userRepository.findUsersDepartment(revieweeId);
        String revieweeJob = userRepository.findUsersJob(revieweeId);
        boolean sameDeptHead = isManagerOf(role, revieweeDept);
        boolean isExecutive = "Executive Leadership".equals(role.getDepartment());
        boolean canApproveDept = role.getDepartment() != null && role.getDepartment().equals(revieweeDept)
                && permissionService.hasPermission(role.getUserId(), PermissionKey.EVALUATION_APPROVE_DEPT);

        if ("Executive Leadership".equals(revieweeDept)) {
            boolean isDepartmentHead = role.getJob() != null && role.getJob().startsWith("Department Head of");
            boolean isDeputy = isExecutive && "Deputy Director".equals(role.getJob());
            boolean revieweeIsDirector = "Director".equals(revieweeJob);
            if ((isDeputy && revieweeIsDirector) || (isDepartmentHead && "Executive Leadership".equals(revieweeDept))) {
                throw new PerformanceException(PerformanceErrorCode.INSUFFICIENT_PERMISSION, "Bạn không có thẩm quyền chấm bài này");
            }
        }
        if (!(sameDeptHead || isExecutive || canApproveDept
                || permissionService.hasPermission(role.getUserId(), PermissionKey.EVALUATION_APPROVE))) {
            throw new PerformanceException(PerformanceErrorCode.INSUFFICIENT_PERMISSION, "Bạn không có thẩm quyền chấm bài này");
        }
    }

    private void assertCompanyViewer(UserRole role) {
        String dept = role.getDepartment() != null ? role.getDepartment() : "";
        if (!dept.equals("Human Resources") && !dept.equals("Executive Leadership")
                && !permissionService.hasPermission(role.getUserId(), PermissionKey.EVALUATION_VIEW_ALL)) {
            throw new PerformanceException(PerformanceErrorCode.INSUFFICIENT_PERMISSION, "Chỉ phòng Nhân sự hoặc Ban Giám Đốc mới xem được toàn công ty");
        }
    }

    private PerformanceReviewResponse toResponse(PerformanceReview r) {
        User u = r.getUser();
        User e = r.getEvaluator();
        List<PerformanceReviewResponse.ScoreResponse> scores = scoresOf(r.getReviewId()).stream()
                .map(s -> PerformanceReviewResponse.ScoreResponse.builder()
                        .scoreId(s.getScoreId()).criterionCode(s.getCriterionCode())
                        .criterionText(s.getCriterionText()).sortOrder(s.getSortOrder())
                        .selfScore(s.getSelfScore()).managerScore(s.getManagerScore())
                        .note(s.getNote()).build())
                .toList();
        return PerformanceReviewResponse.builder()
                .reviewId(r.getReviewId()).userId(u.getUserId()).employeeCode(u.getEmployeeCode())
                .revieweeName(r.getRevieweeName() != null ? r.getRevieweeName() : (u.getFirstName() + " " + u.getLastName()))
                .department(u.getDepartment() != null ? u.getDepartment().getName() : r.getDepartmentName())
                .job(u.getJob() != null ? u.getJob().getTitle() : null)
                .periodType(r.getPeriodType()).periodMonth(r.getPeriodMonth()).periodYear(r.getPeriodYear())
                .status(r.getStatus()).avgSelf(r.getAvgSelf()).avgManager(r.getAvgManager())
                .overallSummary(r.getOverallSummary()).nextGoals(r.getNextGoals())
                .selfAt(r.getSelfAt()).managerAt(r.getManagerAt())
                .evaluatorId(e != null ? e.getUserId() : null)
                .evaluatorName(r.getEvaluatorName() != null ? r.getEvaluatorName()
                        : (e != null ? (e.getFirstName() + " " + e.getLastName()) : null))
                .departmentName(r.getDepartmentName())
                .lockedBy(r.getLockedBy()).lockedAt(r.getLockedAt())
                .leaderConfirmed(r.isLeaderConfirmed()).scores(scores)
                .build();
    }
}
