package com.minhtrung.hrm.auth.services;

import java.util.concurrent.TimeUnit;

import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class RateLimitService {

    private final StringRedisTemplate redisTemplate;

    public RateLimitService(StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    public record RateLimitResult(
        boolean allowed,
        long currentCount,
        long limit,
        long retryAfterSeconds
    ) {}

    /**
     * Kiểm tra và áp dụng rate limit cho một key cụ thể.
     *
     * @param key           Redis key (ví dụ: rate_limit:auth:127.0.0.1)
     * @param maxRequests   Số lượng request tối đa trong khoảng thời gian
     * @param windowSeconds Độ dài cửa sổ thời gian (giây)
     * @return RateLimitResult chứa trạng thái được phép, số lượt hiện tại, và thời gian chờ nếu bị chặn
     */
    public RateLimitResult checkRateLimit(String key, int maxRequests, int windowSeconds) {
        Long currentCount = redisTemplate.opsForValue().increment(key);
        if (currentCount == null) {
            currentCount = 1L;
        }

        // Lần đầu tiên gọi trong cửa sổ: thiết lập thời gian hết hạn (TTL)
        if (currentCount == 1L) {
            redisTemplate.expire(key, windowSeconds, TimeUnit.SECONDS);
        }

        // Đảm bảo key luôn có TTL ngay cả khi xảy ra sự cố bất thường ( trường hợp TTL = -1 là tồn tại vĩnh viễn )
        Long ttl = redisTemplate.getExpire(key, TimeUnit.SECONDS);
        if (ttl != null && ttl < 0) {
            redisTemplate.expire(key, windowSeconds, TimeUnit.SECONDS);
            ttl = (long) windowSeconds;
        }

        long retryAfter = (ttl != null && ttl > 0) ? ttl : windowSeconds;

        if (currentCount > maxRequests) {
            log.warn("Vượt quá giới hạn Rate Limit cho key: [{}]. Lượt gọi: {}/{}, Thử lại sau: {}s",
                    key, currentCount, maxRequests, retryAfter);
            return new RateLimitResult(false, currentCount, maxRequests, retryAfter);
        }

        return new RateLimitResult(true, currentCount, maxRequests, 0);
    }
}
