package com.minhtrung.social_app.attendance.services;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.List;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import com.minhtrung.social_app.attendance.entities.Attendance;
import com.minhtrung.social_app.attendance.entities.WorkShift;
import com.minhtrung.social_app.attendance.enums.AttendanceStatus;
import com.minhtrung.social_app.attendance.repositories.AttendanceRepository;
import com.minhtrung.social_app.employees.entities.User;
import com.minhtrung.social_app.employees.repositories.UserRepository;

import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
@RequiredArgsConstructor
public class AttendanceScheduler {

    private final UserRepository userRepository;
    private final AttendanceRepository attendanceRepository;
    private final AttendanceService attendanceService;

    /**
     * Cron job 1: Chạy vào lúc 00:00:00 mỗi ngày
     * Nhiệm vụ: Khởi tạo record NOT_CHECKED
     */
    @Scheduled(cron = "0 0 0 * * ?")
    @Transactional
    public void generateDailyAttendances() {
        LocalDate today = LocalDate.now();
        DayOfWeek dayOfWeek = today.getDayOfWeek();
        log.info("CronJob: Khởi tạo dữ liệu chấm công cho ngày {}", today);

        // Lấy tất cả nhân viên
        List<User> users = userRepository.findAll();

        for (User user : users) {
            WorkShift shift = user.getShift();
            
            // Nếu user có ca làm việc và hôm nay là ngày làm việc của ca đó
            if (shift != null && attendanceService.isWorkingDay(shift.getShiftId(), dayOfWeek)) {
                
                // Kiểm tra xem đã có record chưa (tránh trường hợp server khởi động lại tạo trùng)
                boolean alreadyExists = attendanceRepository.findUsersTodayAttendance(user.getUserId(), today).isPresent();
                
                if (!alreadyExists) {
                    Attendance attendance = new Attendance();
                    attendance.setUser(user);
                    attendance.setShift(shift);
                    attendance.setWorkDate(today);
                    attendance.setStatus(AttendanceStatus.NOT_CHECKED);
                    
                    attendanceRepository.save(attendance);
                    log.info("Đã tạo record NOT_CHECKED cho user {}", user.getUserId());
                }
            }
        }
    }

    /**
     * Cron job 2: Chạy vào lúc 23:59:00 mỗi ngày
     * Nhiệm vụ: Chốt sổ, đánh dấu MISSING hoặc UNEXCUSED_ABSENCE
     */
    @Scheduled(cron = "0 59 23 * * ?")
    @Transactional
    public void closeDailyAttendances() {
        LocalDate today = LocalDate.now();
        log.info("CronJob: Chốt sổ chấm công ngày {}", today);

        List<Attendance> todayAttendances = attendanceRepository.findByWorkDate(today);

        for (Attendance att : todayAttendances) {
            if (att.getStatus() == AttendanceStatus.NOT_CHECKED) {
                // Cả ngày không quẹt mặt lần nào
                att.setStatus(AttendanceStatus.UNEXCUSED_ABSENCE);
                log.info("User {} vắng mặt không phép", att.getUser().getUserId());
                
            } else if (att.getStatus() == AttendanceStatus.WORKING && att.getClockOutTime() == null) {
                // Có quẹt vào buổi sáng nhưng chiều về quên quẹt ra
                att.setStatus(AttendanceStatus.MISSING);
                log.info("User {} quên chấm công lúc về", att.getUser().getUserId());
            }
        }

        // JPA với @Transactional sẽ tự động lưu thay đổi, nhưng gọi saveAll cho an toàn và tường minh
        attendanceRepository.saveAll(todayAttendances);
    }
}