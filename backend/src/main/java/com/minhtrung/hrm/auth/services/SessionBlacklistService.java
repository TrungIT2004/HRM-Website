package com.minhtrung.hrm.auth.services;

import java.util.UUID;
import java.util.concurrent.TimeUnit;

import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class SessionBlacklistService {

    private final StringRedisTemplate redisTemplate;
    private static final String BLACKLIST_KEY_PREFIX = "revoked:session:";

    public SessionBlacklistService(StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    /**
     * Thêm sessionId vào danh sách bị thu hồi trong Redis với thời gian hết hạn (TTL).
     *
     * @param sessionId       ID phiên làm việc
     * @param durationMinutes Thời gian giữ trong blacklist (thường tương ứng thời hạn sống của Access Token, ví dụ 15 phút)
     */
    public void blacklistSession(UUID sessionId, long durationMinutes) {
        if (sessionId == null) {
            return;
        }
        String key = BLACKLIST_KEY_PREFIX + sessionId;
        log.info("Đưa phiên làm việc vào Redis blacklist trong {} phút. SessionId: {}", durationMinutes, sessionId);
        redisTemplate.opsForValue().set(key, "true", durationMinutes, TimeUnit.MINUTES);
    }

    /**
     * Kiểm tra xem sessionId có nằm trong danh sách bị thu hồi hay không.
     *
     * @param sessionId ID phiên làm việc
     * @return true nếu phiên đã bị thu hồi
     */
    public boolean isSessionBlacklisted(UUID sessionId) {
        if (sessionId == null) {
            return false;
        }
        String key = BLACKLIST_KEY_PREFIX + sessionId;
        return Boolean.TRUE.equals(redisTemplate.hasKey(key));
    }
}
