package com.minhtrung.hrm.exceptions;

import java.util.HashMap;
import java.util.Map;
import java.util.function.BiFunction;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

import com.minhtrung.hrm.attendance.enums.AttendanceErrorCode;
import com.minhtrung.hrm.attendance.exceptions.AttendanceException;
import com.minhtrung.hrm.leave.enums.LeaveErrorCode;
import com.minhtrung.hrm.leave.exceptions.LeaveException;
import com.minhtrung.hrm.overtime.enums.OvertimeErrorCode;
import com.minhtrung.hrm.overtime.exceptions.OvertimeException;
import com.minhtrung.hrm.payroll.enums.PayrollErrorCode;
import com.minhtrung.hrm.payroll.exceptions.PayrollException;

import lombok.extern.slf4j.Slf4j;

@ControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    // ─── BEAN VALIDATION ───────────────────────────────────────
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleMethodArgumentNotValid(MethodArgumentNotValidException ex) {
        Map<String, String> fieldErrors = new HashMap<>();
        for (FieldError error : ex.getBindingResult().getFieldErrors()) {
            fieldErrors.put(error.getField(), error.getDefaultMessage());
        }

        String firstErrorMessage = ex.getBindingResult().getFieldErrors().isEmpty()
                ? "Dữ liệu yêu cầu không hợp lệ"
                : ex.getBindingResult().getFieldErrors().get(0).getDefaultMessage();

        log.warn("Lỗi xác thực dữ liệu (Validation error): {}", fieldErrors);

        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of(
                "errorCode", "VALIDATION_FAILED",
                "msg", firstErrorMessage,
                "errors", fieldErrors
        ));
    }

    // ─── DATA INTEGRITY ────────────────────────────────────────
    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<?> handleDataIntegrityViolationException(DataIntegrityViolationException ex) {
        String msg = ex.getMostSpecificCause().getMessage();
        log.warn("Data integrity violation: {}", msg);

        BiFunction<String, String, ResponseEntity<?>> error = (code, message) ->
            ResponseEntity.status(404).body(Map.of("errorCode", code, "msg", message));

        BiFunction<String, String, ResponseEntity<?>> conflict = (code, message) ->
            ResponseEntity.status(409).body(Map.of("errorCode", code, "msg", message));

        // 1. Friendship
        if (msg.contains("fk_friendship_requester")) {
            return error.apply("REFERENCED_USER_NOT_FOUND", "Requester not found");
        }
        if (msg.contains("fk_friendship_addressee") || msg.contains("uk_friendship_addressee")) {
            return error.apply("REFERENCED_USER_NOT_FOUND", "Addressee not found");
        }
        if (msg.contains("uk_friendship")) {
            return conflict.apply("FRIENDSHIP_ALREADY_EXISTS", "Friendship already exists");
        }

        // 2. Post
        if (msg.contains("fk_post_user")) {
            return error.apply("REFERENCED_USER_NOT_FOUND", "User not exists");
        }

        // 3. Post reaction
        if (msg.contains("fk_post_reaction_interactable")) {
            return error.apply("REFERENCED_POST_NOT_FOUND", "Post not exists");
        }
        if (msg.contains("uk_user_interactable")) {
            return conflict.apply("REACTION_ALREADY_EXISTS", "User has already reacted to the post");
        }

        // 4. Comment
        if (msg.contains("fk_comment_interactable")) {
            return error.apply("REFERENCED_POST_NOT_FOUND", "Post not exists");
        }
        if (msg.contains("fk_comment_user")) {
            return error.apply("REFERENCED_USER_NOT_FOUND", "User not exists");
        }

        // 5. Comment reaction
        if (msg.contains("fk_comment_reaction_user")) {
            return error.apply("REFERENCED_USER_NOT_FOUND", "User not exists");
        }
        if (msg.contains("fk_comment_reaction_comment")) {
            return error.apply("REFERENCED_COMMENT_NOT_FOUND", "Comment not exists");
        }
        if (msg.contains("uk_user_comment")) {
            return conflict.apply("REACTION_ALREADY_EXISTS", "User already reacted to this comment");
        }

        // 6. Share
        if (msg.contains("fk_share_user")) {
            return error.apply("REFERENCED_USER_NOT_FOUND", "User not exists");
        }
        if (msg.contains("fk_share_post")) {
            return error.apply("REFERENCED_POST_NOT_FOUND", "Referenced post not exists");
        }

        return ResponseEntity.status(500).body(Map.of(
            "errorCode", "DATA_INTEGRITY_ERROR",
            "msg", "Database constraint violation"));
    }

    // ─── GENERIC EXCEPTION ────────────────────────────────────
    @ExceptionHandler(Exception.class)
    public ResponseEntity<?> handleException(Exception ex) {
        Throwable rootCause = ex;
        while (rootCause.getCause() != null && rootCause.getCause() != rootCause) {
            rootCause = rootCause.getCause();
        }
        log.error("Lỗi hệ thống không xác định: [{}] {}", rootCause.getClass().getSimpleName(), rootCause.getMessage());
        return ResponseEntity.status(500).body("Internal Server Error");
    }

    // ─── ATTENDANCE EXCEPTION ─────────────────────────────────
    @ExceptionHandler(AttendanceException.class)
    public ResponseEntity<Map<String, Object>> handleAttendanceException(AttendanceException ex) {
        HttpStatus status = mapAttendanceECToStatus(ex.getErrorCode());
        log.warn("Lỗi nghiệp vụ chấm công: Mã lỗi: {}, Thông báo: {}", ex.getErrorCode(), ex.getMessage());
        return ResponseEntity.status(status).body(Map.of(
                "errorCode", ex.getErrorCode().name(),
                "msg", ex.getMessage()));
    }

    private HttpStatus mapAttendanceECToStatus(AttendanceErrorCode errorCode) {
        switch (errorCode) {
            case SHIFT_NOT_FOUND:
            case ATTENDANCE_NOT_FOUND:
            case USER_NOT_FOUND:
            case TIMESHEET_NOT_FOUND:
                return HttpStatus.NOT_FOUND;
            case NOT_WORK_DAY:
            case INSUFFICIENT_WORK_TIME:
            case INVALID_CLOCK_TIME:
            case INSUFFICIENT_PERMISSION:
            case UNAUTHORIZED_ACTION:
                return HttpStatus.FORBIDDEN;
            case TIMESHEET_ALREADY_LOCKED:
                return HttpStatus.BAD_REQUEST;
            default:
                return HttpStatus.INTERNAL_SERVER_ERROR;
        }
    }

    // ─── LEAVE EXCEPTION ──────────────────────────────────────
    @ExceptionHandler(LeaveException.class)
    public ResponseEntity<Map<String, Object>> handleLeaveException(LeaveException ex) {
        HttpStatus status = mapLeaveECToStatus(ex.getErrorCode());
        log.warn("Lỗi nghiệp vụ nghỉ phép: Mã lỗi: {}, Thông báo: {}", ex.getErrorCode(), ex.getMessage());
        return ResponseEntity.status(status).body(Map.of(
                "errorCode", ex.getErrorCode().name(),
                "msg", ex.getMessage()));
    }

    private HttpStatus mapLeaveECToStatus(LeaveErrorCode errorCode) {
        if (errorCode == null) {
            return HttpStatus.INTERNAL_SERVER_ERROR;
        }

        switch (errorCode) {
            case USER_NOT_FOUND:
            case REQUEST_NOT_FOUND:
                return HttpStatus.NOT_FOUND;
            case INSUFFICIENT_PERMISSION:
                return HttpStatus.FORBIDDEN;
            case CHAIRMAN_CANNOT_LEAVE:
            case OUT_OF_ANNUAL_LEAVE_DAYS:
            case ALREADY_PROCESSED_REQUEST:
            case OVERLAPPING_LEAVE_REQUEST:
            case INVALID_LEAVE_DATE:
            case MAXIMUM_LEAVE_DAYS:
            case ALL_REST_DAYS:
                return HttpStatus.BAD_REQUEST;
            case INTERNAL_SERVER_ERROR:
            default:
                return HttpStatus.INTERNAL_SERVER_ERROR;
        }
    }

    // ─── OVERTIME EXCEPTION ────────────────────────────────────
    @ExceptionHandler(OvertimeException.class)
    public ResponseEntity<Map<String, Object>> handleOvertimeException(OvertimeException ex) {
        HttpStatus status = mapOvertimeECToStatus(ex.getErrorCode());
        log.warn("Lỗi nghiệp vụ tăng ca: Mã lỗi: {}, Thông báo: {}", ex.getErrorCode(), ex.getMessage());
        return ResponseEntity.status(status).body(Map.of(
                "errorCode", ex.getErrorCode().name(),
                "msg", ex.getMessage()));
    }

    private HttpStatus mapOvertimeECToStatus(OvertimeErrorCode errorCode) {
        if (errorCode == null) {
            return HttpStatus.INTERNAL_SERVER_ERROR;
        }

        switch (errorCode) {
            // 404 Not Found
            case SHIFT_NOT_FOUND:
            case RECORD_NOT_FOUND:
                return HttpStatus.NOT_FOUND;

            // 403 Forbidden
            case NOT_RECORD_OWNER:
            case INSUFFICIENT_PERMISSION:
            case INVALID_STATUS:
                return HttpStatus.FORBIDDEN;

            // 400 Bad Request – lỗi dữ liệu đầu vào (giới hạn OT, thời gian, nghỉ...)
            case EXCEED_MAXIMUM_OVERTIME:
            case EXCEED_DAILY_TOTAL:
            case EXCEED_50_PERCENT:
            case INSUFFICIENT_REST:
            case OVERLAP_WORK_HOURS:
            case USER_NO_SHIFT:
            case EXCEED_MONTHLY_OVERTIME:
            case EXCEED_YEARLY_OVERTIME:
            case INVALID_TIME:
            case INVALID_TIME_RANGE:
            case ALREADY_PROCESSED_REQUEST:
            case INSUFFICIENT_TIME:
                return HttpStatus.BAD_REQUEST;

            // 500 Internal Server Error
            case GENERIC:
            default:
                return HttpStatus.INTERNAL_SERVER_ERROR;
        }
    }

    @ExceptionHandler(org.springframework.security.access.AccessDeniedException.class)
    public ResponseEntity<Map<String, Object>> handleAccessDenied(org.springframework.security.access.AccessDeniedException ex) {
        log.warn("Access denied: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of(
                "errorCode", "FORBIDDEN",
                "msg", ex.getMessage()
        ));
    }

    // ─── PAYROLL EXCEPTION ─────────────────────────────────────
    @ExceptionHandler(PayrollException.class)
    public ResponseEntity<Map<String, Object>> handlePayrollException(PayrollException ex) {
        HttpStatus status = mapPayrollECToStatus(ex.getErrorCode());
        log.warn("Lỗi nghiệp vụ bảng lương: Mã lỗi: {}, Thông báo: {}", ex.getErrorCode(), ex.getMessage());
        return ResponseEntity.status(status).body(Map.of(
                "errorCode", ex.getErrorCode().name(),
                "msg", ex.getMessage()
        ));
    }

    private HttpStatus mapPayrollECToStatus(PayrollErrorCode errorCode) {
        if (errorCode == null) {
            return HttpStatus.INTERNAL_SERVER_ERROR;
        }

        switch (errorCode) {
            case TIMESHEET_NOT_FOUND:
            case PAYROLL_NOT_FOUND:
            case SUMMARY_NOT_FOUND:
            case SALARY_NOT_CONFIGURED:
                return HttpStatus.NOT_FOUND;

            case INSUFFICIENT_PERMISSION:
                return HttpStatus.FORBIDDEN;

            case TIMESHEET_NOT_LOCKED:
            case PAYROLL_ALREADY_EXISTS:
            case PAYROLL_ALREADY_APPROVED:
            case PAYROLL_ALREADY_PAID:
            case INVALID_PAYROLL_PERIOD:
                return HttpStatus.BAD_REQUEST;

            case GENERIC:
            default:
                return HttpStatus.INTERNAL_SERVER_ERROR;
        }
    }
}