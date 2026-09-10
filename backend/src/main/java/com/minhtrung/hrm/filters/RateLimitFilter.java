package com.minhtrung.hrm.filters;

import java.io.IOException;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.minhtrung.hrm.auth.services.ClientInfoService;
import com.minhtrung.hrm.auth.services.RateLimitService;
import com.minhtrung.hrm.auth.services.RateLimitService.RateLimitResult;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;

@Component
@Slf4j
public class RateLimitFilter extends OncePerRequestFilter {

    private final RateLimitService rateLimitService;
    private final ClientInfoService clientInfoService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    // Hạn mức cho /auth (30 requests / 60 giây)
    private static final int AUTH_MAX_REQUESTS = 30;
    private static final int AUTH_WINDOW_SECONDS = 60;

    // Hạn mức chung cho toàn bộ các route khác (100 requests / 60 giây)
    private static final int GENERAL_MAX_REQUESTS = 1000000000;
    private static final int GENERAL_WINDOW_SECONDS = 60;

    public RateLimitFilter(RateLimitService rateLimitService, ClientInfoService clientInfoService) {
        this.rateLimitService = rateLimitService;
        this.clientInfoService = clientInfoService;
    }

    private boolean isExcludedPath(String path) {
        return path.startsWith("/swagger-ui") ||
               path.startsWith("/v3/api-docs") ||
               path.startsWith("/favicon.ico");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        String path = request.getRequestURI();

        // Bỏ qua rate limit cho tài liệu API Swagger / OpenAPI
        if (isExcludedPath(path)) {
            filterChain.doFilter(request, response);
            return;
        }

        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            filterChain.doFilter(request, response);
            return;
        }

        String clientIp = clientInfoService.extractRealIp(request);

        // Chuẩn hóa địa chỉ local loopback IPv6 thành IPv4 cho dễ đọc và thống nhất
        if ("0:0:0:0:0:0:0:1".equals(clientIp) || "::1".equals(clientIp)) {
            clientIp = "127.0.0.1";
        }

        String rateLimitKey;
        int maxRequests;
        int windowSeconds;

        if (path.startsWith("/auth")) {
            rateLimitKey = "rate_limit:auth:" + clientIp;
            maxRequests = AUTH_MAX_REQUESTS;
            windowSeconds = AUTH_WINDOW_SECONDS;
        } else {
            rateLimitKey = "rate_limit:general:" + clientIp;
            maxRequests = GENERAL_MAX_REQUESTS;
            windowSeconds = GENERAL_WINDOW_SECONDS;
        }

        RateLimitResult result = rateLimitService.checkRateLimit(rateLimitKey, maxRequests, windowSeconds);

        // Gắn các headers chuẩn về Rate Limit vào response
        response.setHeader("X-RateLimit-Limit", String.valueOf(maxRequests));
        response.setHeader("X-RateLimit-Remaining", String.valueOf(Math.max(0, maxRequests - result.currentCount())));

        if (!result.allowed()) {
            response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value()); // HTTP 429
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.setCharacterEncoding("UTF-8");
            response.setHeader("Retry-After", String.valueOf(result.retryAfterSeconds()));

            Map<String, Object> errorBody = Map.of(
                "errorCode", "TOO_MANY_REQUESTS",
                "message", String.format("Quá nhiều yêu cầu. Vui lòng thử lại sau %d giây.", result.retryAfterSeconds()),
                "retryAfterSeconds", result.retryAfterSeconds()
            );

            response.getWriter().write(objectMapper.writeValueAsString(errorBody));
            return;
        }

        filterChain.doFilter(request, response);
    }
}
