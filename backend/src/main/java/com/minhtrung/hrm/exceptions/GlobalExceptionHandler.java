package com.minhtrung.hrm.exceptions;

import java.util.HashMap;
import java.util.Map;
import java.util.function.BiFunction;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.server.ResponseStatusException;

import com.minhtrung.hrm.auth.enums.AuthErrorCode;
import com.minhtrung.hrm.auth.exceptions.AuthenticationException;
import com.minhtrung.hrm.attendance.enums.AttendanceErrorCode;
import com.minhtrung.hrm.attendance.exceptions.AttendanceException;
import com.minhtrung.hrm.leave.enums.LeaveErrorCode;
import com.minhtrung.hrm.leave.exceptions.LeaveException;
import com.minhtrung.hrm.overtime.enums.OvertimeErrorCode;
import com.minhtrung.hrm.overtime.exceptions.OvertimeException;
import com.minhtrung.hrm.payroll.enums.PayrollErrorCode;
import com.minhtrung.hrm.payroll.exceptions.PayrollException;
import com.minhtrung.hrm.resignation.enums.ResignationErrorCode;
import com.minhtrung.hrm.resignation.exceptions.ResignationException;
import com.minhtrung.hrm.documents.enums.DocumentErrorCode;
import com.minhtrung.hrm.documents.exceptions.DocumentException;
import com.minhtrung.hrm.asset.enums.AssetErrorCode;
import com.minhtrung.hrm.asset.exceptions.AssetException;
import com.minhtrung.hrm.itticket.enums.ItTicketErrorCode;
import com.minhtrung.hrm.itticket.exceptions.ItTicketException;
import com.minhtrung.hrm.performance.enums.PerformanceErrorCode;
import com.minhtrung.hrm.performance.exceptions.PerformanceException;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseCookie;

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

    // ─── NO RESOURCE FOUND (404 STATIC / INVALID PATH) ───────
    /**
     * Xử lý trường hợp không tìm thấy tài nguyên tĩnh hoặc đường dẫn không hợp lệ (HTTP 404).
     * Bắt chặn NoResourceFoundException (ví dụ các polling request ngầm từ LuaTools/DevTools tới /json)
     * để tránh ghi log lỗi 500 [ERROR] hệ thống không xác định làm nhiễu console.
     */
    @ExceptionHandler(org.springframework.web.servlet.resource.NoResourceFoundException.class)
    public ResponseEntity<?> handleNoResourceFound(org.springframework.web.servlet.resource.NoResourceFoundException ex) {
        log.debug("Không tìm thấy tài nguyên tĩnh hoặc API: /{}", ex.getResourcePath());
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
                "errorCode", "RESOURCE_NOT_FOUND",
                "msg", "Đường dẫn không tồn tại: /" + ex.getResourcePath()
        ));
    }

    /**
     * ResponseStatusException mang sẵn HTTP status cụ thể (409 CONFLICT khi xoá master data
     * còn bị tham chiếu, 400 BAD_REQUEST...). Phải khai báo trước {@code Exception.class}
     * vì handler generic sẽ nuốt mất status và trả về 500.
     */
    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Map<String, Object>> handleResponseStatus(ResponseStatusException ex) {
        HttpStatusCode status = ex.getStatusCode();
        String reason = ex.getReason() != null ? ex.getReason() : status.toString();
        log.warn("Request bị từ chối [{}]: {}", status.value(), reason);
        return ResponseEntity.status(status).body(Map.of(
                "errorCode", "REQUEST_REJECTED",
                "msg", reason
        ));
    }

    // ─── MALFORMED JSON / TYPE MISMATCH (400, không phải 500) ───────
    @ExceptionHandler(org.springframework.http.converter.HttpMessageNotReadableException.class)
    public ResponseEntity<Map<String, Object>> handleNotReadable(org.springframework.http.converter.HttpMessageNotReadableException ex) {
        log.warn("Dữ liệu JSON không đọc được: {}", ex.getMostSpecificCause().getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of(
                "errorCode", "MALFORMED_REQUEST",
                "msg", "Dữ liệu gửi lên sai định dạng (ví dụ giờ làm việc phải là HH:mm)."
        ));
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
            case INVALID_TIMESHEET_PERIOD:
            case WORK_SHIFT_DAILY_HOURS_EXCEEDED:
            case WORK_SHIFT_WEEKLY_HOURS_EXCEEDED:
            case WORK_SHIFT_INVALID_TIME:
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
            case RECORD_NOT_FOUND:
                return HttpStatus.NOT_FOUND;

            // 403 Forbidden
            case NOT_RECORD_OWNER:
            case INSUFFICIENT_PERMISSION:
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
            case ALREADY_PROCESSED_REQUEST:
            case INSUFFICIENT_TIME:
                return HttpStatus.BAD_REQUEST;

            // 500 Internal Server Error
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

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, Object>> handleIllegalArgument(IllegalArgumentException ex) {
        log.warn("Invalid argument: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of(
                "errorCode", "BAD_REQUEST",
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
            case PAYROLL_NOT_FOUND:
            case SUMMARY_NOT_FOUND:
                return HttpStatus.NOT_FOUND;

            case INSUFFICIENT_PERMISSION:
                return HttpStatus.FORBIDDEN;

            case TIMESHEET_NOT_LOCKED:
            case PAYROLL_ALREADY_APPROVED:
            case PAYROLL_ALREADY_PAID:
            case INVALID_PAYROLL_PERIOD:
                return HttpStatus.BAD_REQUEST;

            default:
                return HttpStatus.INTERNAL_SERVER_ERROR;
        }
    }

    // ─── AUTHENTICATION EXCEPTION ─────────────────────────────
    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<Map<String, Object>> handleAuthenticationException(AuthenticationException ex) {
        HttpStatus status = mapAuthECToStatus(ex.getCode());
        log.warn("Lỗi xác thực (Authentication error): Mã lỗi: {}, Thông báo: {}", ex.getCode(), ex.getMessage());

        ResponseCookie deleteCookie = ResponseCookie.from("refreshToken", "")
                .httpOnly(true)
                .secure(false)
                .path("/")
                .maxAge(0)
                .sameSite("Lax")
                .build();

        ResponseCookie deleteDeviceCookie = ResponseCookie.from("deviceId", "")
                .httpOnly(true)
                .secure(false)
                .path("/")
                .maxAge(0)
                .sameSite("Lax")
                .build();

        String message = ex.getMessage();
        if ("Wrong credentials".equalsIgnoreCase(message)) {
            message = "Email hoặc mật khẩu không chính xác";
        } else if ("User doesn't exists".equalsIgnoreCase(message)) {
            message = "Tài khoản không tồn tại trong hệ thống";
        } else if (message == null || message.isBlank()) {
            message = getDefaultAuthMessage(ex.getCode());
        }

        ResponseEntity.BodyBuilder builder = ResponseEntity.status(status)
                .header(HttpHeaders.SET_COOKIE, deleteCookie.toString());

        if (ex.getCode() == AuthErrorCode.ACCOUNT_DISABLED) {
            builder.header(HttpHeaders.SET_COOKIE, deleteDeviceCookie.toString());
        }

        return builder.body(Map.of(
                "errorCode", ex.getCode().name(),
                "message", message,
                "msg", message
        ));
    }

    private HttpStatus mapAuthECToStatus(AuthErrorCode errorCode) {
        if (errorCode == null) {
            return HttpStatus.UNAUTHORIZED;
        }

        switch (errorCode) {
            case USER_NOT_FOUND:
                return HttpStatus.NOT_FOUND;
            case USER_CREDENTIALS_INVALID:
                return HttpStatus.UNAUTHORIZED;
            case ACCOUNT_DISABLED:
            case USER_MISMATCH:
            case DEVICE_MISMATCH:
            case DEVICE_COOKIE_MISMATCH:
                return HttpStatus.FORBIDDEN;
            case SESSION_COMPROMISED:
            case SESSION_NOT_FOUND:
            case SESSION_REVOKED:
            case SESSION_MISMATCH:
                return HttpStatus.UNAUTHORIZED;
            case INTERNAL_SERVER_ERROR:
                return HttpStatus.INTERNAL_SERVER_ERROR;
            default:
                return HttpStatus.UNAUTHORIZED;
        }
    }

    private String getDefaultAuthMessage(AuthErrorCode errorCode) {
        if (errorCode == null) {
            return "Lỗi xác thực người dùng";
        }
        switch (errorCode) {
            case USER_NOT_FOUND:
                return "Không tìm thấy người dùng trong hệ thống";
            case USER_CREDENTIALS_INVALID:
                return "Email hoặc mật khẩu không chính xác";
            case ACCOUNT_DISABLED:
                return "Tài khoản nhân viên này đã bị khóa do đã thôi việc.";
            case SESSION_COMPROMISED:
                return "Phiên làm việc có dấu hiệu bị xâm nhập. Vui lòng đăng nhập lại.";
            case SESSION_NOT_FOUND:
            case SESSION_REVOKED:
            case SESSION_MISMATCH:
                return "Phiên đăng nhập không hợp lệ hoặc đã hết hạn.";
            case USER_MISMATCH:
            case DEVICE_MISMATCH:
            case DEVICE_COOKIE_MISMATCH:
                return "Thông tin thiết bị hoặc phiên không khớp.";
            default:
                return "Xác thực thất bại";
        }
    }

    // ─── RESIGNATION EXCEPTION ────────────────────────────────
    @ExceptionHandler(ResignationException.class)
    public ResponseEntity<Map<String, Object>> handleResignationException(ResignationException ex) {
        HttpStatus status = mapResignationECToStatus(ex.getErrorCode());
        log.warn("Lỗi nghiệp vụ thôi việc: Mã lỗi: {}, Thông báo: {}", ex.getErrorCode(), ex.getMessage());
        return ResponseEntity.status(status).body(Map.of(
                "errorCode", ex.getErrorCode().name(),
                "msg", ex.getMessage()));
    }

    private HttpStatus mapResignationECToStatus(ResignationErrorCode errorCode) {
        switch (errorCode) {
            case RESIGNATION_NOT_FOUND:
            case CONTRACT_NOT_FOUND:
                return HttpStatus.NOT_FOUND;
            case SELF_APPROVAL_NOT_ALLOWED:
            case UNAUTHORIZED_ACTION:
                return HttpStatus.FORBIDDEN;
            case ACTIVE_REQUEST_EXISTS:
            case INVALID_NOTICE_PERIOD:
            case INVALID_STATUS_TRANSITION:
                return HttpStatus.BAD_REQUEST;
            default:
                return HttpStatus.INTERNAL_SERVER_ERROR;
        }
    }

    // ─── DOCUMENT EXCEPTION ─────────────────────────────────
    @ExceptionHandler(DocumentException.class)
    public ResponseEntity<Map<String, Object>> handleDocumentException(DocumentException ex) {
        HttpStatus status = mapDocumentECToStatus(ex.getErrorCode());
        log.warn("Lỗi nghiệp vụ mẫu đơn: Mã lỗi: {}, Thông báo: {}", ex.getErrorCode(), ex.getMessage());
        return ResponseEntity.status(status).body(Map.of(
                "errorCode", ex.getErrorCode().name(),
                "msg", ex.getMessage()));
    }

    private HttpStatus mapDocumentECToStatus(DocumentErrorCode errorCode) {
        switch (errorCode) {
            case DOCUMENT_NOT_FOUND:
                return HttpStatus.NOT_FOUND;
            case UNAUTHORIZED_ACTION:
                return HttpStatus.FORBIDDEN;
            case INVALID_FILE_TYPE:
            case FILE_TOO_LARGE:
                return HttpStatus.BAD_REQUEST;
            default:
                return HttpStatus.INTERNAL_SERVER_ERROR;
        }
    }

    // ─── ASSET EXCEPTION ────────────────────────────────────
    @ExceptionHandler(AssetException.class)
    public ResponseEntity<Map<String, Object>> handleAssetException(AssetException ex) {
        HttpStatus status = mapAssetECToStatus(ex.getErrorCode());
        log.warn("Lỗi nghiệp vụ tài sản: Mã lỗi: {}, Thông báo: {}", ex.getErrorCode(), ex.getMessage());
        return ResponseEntity.status(status).body(Map.of(
                "errorCode", ex.getErrorCode().name(),
                "msg", ex.getMessage()));
    }

    private HttpStatus mapAssetECToStatus(AssetErrorCode errorCode) {
        if (errorCode == null) {
            return HttpStatus.INTERNAL_SERVER_ERROR;
        }
        switch (errorCode) {
            case ASSET_NOT_FOUND:
            case CATEGORY_NOT_FOUND:
            case REQUEST_NOT_FOUND:
            case ASSIGNMENT_NOT_FOUND:
                return HttpStatus.NOT_FOUND;
            case NOT_RECORD_OWNER:
            case INSUFFICIENT_PERMISSION:
            case SELF_APPROVAL_NOT_ALLOWED:
                return HttpStatus.FORBIDDEN;
            default:
                return HttpStatus.BAD_REQUEST;
        }
    }

    // ─── IT TICKET EXCEPTION ─────────────────────────────────
    @ExceptionHandler(ItTicketException.class)
    public ResponseEntity<Map<String, Object>> handleItTicketException(ItTicketException ex) {
        HttpStatus status = mapItTicketECToStatus(ex.getErrorCode());
        log.warn("Lỗi nghiệp vụ IT ticket: Mã lỗi: {}, Thông báo: {}", ex.getErrorCode(), ex.getMessage());
        return ResponseEntity.status(status).body(Map.of(
                "errorCode", ex.getErrorCode().name(),
                "msg", ex.getMessage()));
    }

    private HttpStatus mapItTicketECToStatus(ItTicketErrorCode errorCode) {
        if (errorCode == null) {
            return HttpStatus.INTERNAL_SERVER_ERROR;
        }
        switch (errorCode) {
            case TICKET_NOT_FOUND:
                return HttpStatus.NOT_FOUND;
            case NOT_RECORD_OWNER:
            case INSUFFICIENT_PERMISSION:
                return HttpStatus.FORBIDDEN;
            default:
                return HttpStatus.BAD_REQUEST;
        }
    }

    // ─── PERFORMANCE EXCEPTION ───────────────────────────────
    @ExceptionHandler(PerformanceException.class)
    public ResponseEntity<Map<String, Object>> handlePerformanceException(PerformanceException ex) {
        HttpStatus status = mapPerformanceECToStatus(ex.getErrorCode());
        log.warn("Lỗi nghiệp vụ đánh giá hiệu suất: Mã lỗi: {}, Thông báo: {}", ex.getErrorCode(), ex.getMessage());
        return ResponseEntity.status(status).body(Map.of(
                "errorCode", ex.getErrorCode().name(),
                "msg", ex.getMessage()));
    }

    private HttpStatus mapPerformanceECToStatus(PerformanceErrorCode errorCode) {
        if (errorCode == null) {
            return HttpStatus.INTERNAL_SERVER_ERROR;
        }
        switch (errorCode) {
            case REVIEW_NOT_FOUND:
                return HttpStatus.NOT_FOUND;
            case INTERNAL_SERVER_ERROR:
                return HttpStatus.INTERNAL_SERVER_ERROR;
            case NOT_RECORD_OWNER:
            case INSUFFICIENT_PERMISSION:
            case SELF_APPROVAL_NOT_ALLOWED:
                return HttpStatus.FORBIDDEN;
            default:
                return HttpStatus.BAD_REQUEST;
        }
    }
}