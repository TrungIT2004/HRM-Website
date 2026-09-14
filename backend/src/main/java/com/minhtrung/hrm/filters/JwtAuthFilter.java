package com.minhtrung.hrm.filters;

import java.io.IOException;
import java.util.List;
import java.util.UUID;

import org.slf4j.MDC;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import com.minhtrung.hrm.auth.dtos.internals.ClientMetaData;
import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;
import com.minhtrung.hrm.auth.services.ClientInfoService;
import com.minhtrung.hrm.auth.services.JwtService;
import com.minhtrung.hrm.auth.services.SessionBlacklistService;
import com.minhtrung.hrm.common.context.RequestContext;
import com.minhtrung.hrm.common.context.RequestContextHolder;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;

@Component
@Slf4j
public class JwtAuthFilter extends OncePerRequestFilter {
    private final JwtService jwtService;
    private final ClientInfoService clientInfoService;
    private final SessionBlacklistService sessionBlacklistService;

    @Value("${jwt.secret.access}")
    private String secretAccessKey;

    private static final List<String> PROTECTED_PATHS = List.of(
        "/api/attendances",
        "/api/leave",
        "/api/overtime",
        "/api/employees",
                        
        "/api/payrolls",
        "/api/dashboard",
        "/api/work-shifts",
        "/api/departments",
        "/api/jobs",
        "/api/resignations",
        "/api/resignation",
        "/auth/change-password",
        "/api/admin"
    );

    JwtAuthFilter(JwtService jwtService, ClientInfoService clientInfoService,
            SessionBlacklistService sessionBlacklistService) {
        this.jwtService = jwtService;
        this.clientInfoService = clientInfoService;
        this.sessionBlacklistService = sessionBlacklistService;
    }

    private boolean isCameraCheckInEndpoint(String path, String method) {
        if ("PUT".equalsIgnoreCase(method)) {
            return path.matches("^/api/attendances/[0-9a-fA-F-]+$") ||
                   path.matches("^/api/overtime/[0-9a-fA-F-]+$");
        }
        return false;
    }

    private boolean isProtectedPath(String path, String method) {
        if (isCameraCheckInEndpoint(path, method)) {
            return false;
        }
        return PROTECTED_PATHS.stream().anyMatch(path::startsWith);
    }
    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String traceId = UUID.randomUUID().toString();
        MDC.put("traceId", traceId);
        
        ClientMetaData clientMetaData = clientInfoService.getClientMetaData(request);
        
        RequestContext.RequestContextBuilder builder = RequestContext.builder().metaData(clientMetaData);
        String path = request.getRequestURI();
        String method = request.getMethod();
        TokenPayload payload = null;
        
        if (isProtectedPath(path, method)) {
            String header = request.getHeader("Authorization");

            if (header == null || !header.startsWith("Bearer ")) {
                log.warn("[{}] {} | Từ chối truy cập: Thiếu hoặc sai header Authorization | Trace: {}", method, path, traceId);
                response.setStatus(401);
                response.getWriter().write("Invalid Header or Missing Token");
                return;
            }

            String token = header.substring(7);

            try {
                if (jwtService.isTokenValid(token, secretAccessKey)) {
                    payload = jwtService.extractAll(token, secretAccessKey);

                    if (sessionBlacklistService.isSessionBlacklisted(payload.getSessionId())) {
                        log.warn("[{}] {} | Từ chối truy cập: Phiên làm việc đã bị thu hồi | SessionId: {} | Trace: {}",
                                method, path, payload.getSessionId(), traceId);
                        response.setStatus(401);
                        response.getWriter().write("Session has been revoked");
                        return;
                    }

                    builder.tokenPayload(payload);
                } else {
                    log.warn("[{}] {} | Từ chối truy cập: Token không hợp lệ hoặc đã hết hạn | Trace: {}", method, path, traceId);
                    response.setStatus(401);
                    response.getWriter().write("Invalid Token");
                    return;
                }
            } catch (Exception ex) {
                log.error("[{}] {} | Lỗi máy chủ khi xác thực token | Trace: {} | Error: {}", method, path, traceId, ex.getMessage());
                response.setStatus(500);
                response.getWriter().write("Server Error");
                return;
            } 
        }
        
        RequestContext ctx = builder.build();
        RequestContextHolder.set(ctx);

        // Log thông tin chi tiết của từng request API
        log.info("[{}] {} | User: {} | IP: {} | Trace: {}",
                method,
                path,
                payload != null ? payload.getUserId() : "Ẩn danh",
                clientMetaData != null ? clientMetaData.getIpAddr() : "N/A",
                traceId);

        try {
            filterChain.doFilter(request, response);
        } finally {
            RequestContextHolder.clear();
            MDC.clear();
        }
    }
}
