package com.minhtrung.hrm.resignation.services;

import java.time.LocalDate;
import java.util.List;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.minhtrung.hrm.auth.entities.UserSession;
import com.minhtrung.hrm.auth.repositories.UserSessionRepository;
import com.minhtrung.hrm.auth.services.SessionBlacklistService;
import com.minhtrung.hrm.employees.entities.User;
import com.minhtrung.hrm.employees.repositories.UserRepository;
import com.minhtrung.hrm.resignation.entities.ResignationRequest;
import com.minhtrung.hrm.resignation.enums.ResignationStatus;
import com.minhtrung.hrm.resignation.repositories.ResignationRequestRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
@RequiredArgsConstructor
public class ResignationScheduler {

    private final ResignationRequestRepository resignationRequestRepository;
    private final UserRepository userRepository;
    private final UserSessionRepository userSessionRepository;
    private final SessionBlacklistService sessionBlacklistService;

    /**
     * Cron job: Chạy vào lúc 00:05:00 mỗi ngày
     * Nhiệm vụ: Tự động hoàn tất các đơn thôi việc đã được phê duyệt (APPROVED)
     * mà ngày làm việc cuối cùng (lastWorkingDate) đã kết thúc (trước ngày hôm nay),
     * đồng thời vô hiệu hóa (active = false) tài khoản nhân viên.
     */
    @Scheduled(cron = "0 5 0 * * ?")
    @Transactional
    public void processCompletedResignations() {
        LocalDate today = LocalDate.now();
        log.info("CronJob: Quét các đơn thôi việc đến hạn hoàn tất trước ngày {}", today);

        // Lấy các đơn APPROVED có lastWorkingDate <= hôm qua (ngày làm việc cuối cùng đã qua)
        LocalDate yesterday = today.minusDays(1);
        List<ResignationRequest> overdueRequests = resignationRequestRepository
                .findByStatusAndLastWorkingDateLessThanEqual(ResignationStatus.APPROVED, yesterday);

        if (overdueRequests.isEmpty()) {
            log.info("CronJob: Không có đơn thôi việc nào cần hoàn tất hôm nay.");
            return;
        }

        int count = 0;
        for (ResignationRequest request : overdueRequests) {
            request.setStatus(ResignationStatus.COMPLETED);

            User user = request.getUser();
            if (user != null) {
                user.setActive(false);
                userRepository.save(user);

                // Thu hồi toàn bộ session và blacklist trong Redis
                List<UserSession> activeSessions = userSessionRepository.findByUserId(user.getUserId());
                for (UserSession s : activeSessions) {
                    s.setRevoked(true);
                    userSessionRepository.save(s);
                    sessionBlacklistService.blacklistSession(s.getSessionId(), 15);
                }

                log.info("CronJob: Đã khóa tài khoản và thu hồi toàn bộ session của nhân viên {} ({} {}) do đã hoàn tất thôi việc.",
                        user.getUserId(), user.getLastName(), user.getFirstName());
            }

            resignationRequestRepository.save(request);
            count++;
        }

        log.info("CronJob: Đã xử lý hoàn tất {} đơn thôi việc và khóa tài khoản thành công.", count);
    }
}
