package com.minhtrung.hrm.overtime.entities;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.UUID;

import org.hibernate.annotations.UuidGenerator;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.minhtrung.hrm.employees.entities.User;
import com.minhtrung.hrm.overtime.enums.OvertimeRecordStatus;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@NoArgsConstructor
@Getter
@Setter
@Entity
@Table(name = "overtime_records", uniqueConstraints = { @UniqueConstraint(name = "uk_requestorId_overtimeDate", columnNames = {"requestorId", "approvedDate"})})
public class OvertimeRecord {
    @Id
    @UuidGenerator(style = UuidGenerator.Style.TIME)
    private UUID overtimeRecordId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "requestorId", referencedColumnName = "userId", foreignKey = @ForeignKey(name = "fk_overtime_requestor"))
    @JsonIgnore
    private User requestor;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "approverId", referencedColumnName = "userId", foreignKey = @ForeignKey(name = "fk_overtime_approver"))
    @JsonIgnore
    private User approver;

    @Column(name = "approved_start_time", nullable = false)
    private LocalDateTime approvedStartTime;

    @Column(name = "approved_end_time", nullable = false)
    private LocalDateTime approvedEndTime;

    private LocalDateTime clockInTime;

    private LocalDateTime clockOutTime;

    @Column(nullable = false)
    private boolean isNightTime;

    @Column(nullable = false)
    private boolean isWeekend;

    @Column(nullable = false)
    private boolean isHoliday;

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private OvertimeRecordStatus status = OvertimeRecordStatus.pending;

    @Column(name = "approved_date", nullable = false)
    private LocalDate approvedDate;

    @Column(name = "reason")
    private String reason;

    @Column(name = "rejection_reason")
    private String rejectionReason;

    @PrePersist
    public void setFlags() {
        if (approvedStartTime == null)
            return;

        // Set weekend flag
        DayOfWeek day = approvedStartTime.getDayOfWeek();
        this.isWeekend = (day == DayOfWeek.SATURDAY || day == DayOfWeek.SUNDAY);

        // Lấy giờ bắt đầu và kết thúc (giả sử có approvedEndTime)
        LocalTime start = approvedStartTime.toLocalTime();
        LocalTime end = approvedEndTime != null ? approvedEndTime.toLocalTime() : start;

        // Kiểm tra nếu start rơi vào khoảng 22-6 hoặc end rơi vào khoảng 22-6 hoặc ca kéo dài qua đêm
        boolean startInNight = isInNightRange(start);
        boolean endInNight = isInNightRange(end);

        // Nếu start hoặc end nằm trong khoảng đêm => là night
        if (startInNight || endInNight) {
            this.isNightTime = true;
        } else {
            // Nếu ca kéo dài qua đêm (end < start), thì chắc chắn có phần trong đêm
            // vì nếu không thì cả start và end đều nằm ngoài khoảng đêm nhưng vẫn có thể qua đêm (ví dụ 20h-7h)
            // Nên cần kiểm tra thêm: nếu end < start => ca qua đêm => isNightTime = true
            if (end.isBefore(start)) {
                this.isNightTime = true;
            } else {
                this.isNightTime = false;
            }
        }
    }

    private boolean isInNightRange(LocalTime time) {
        return time.isAfter(LocalTime.of(22, 0)) || time.isBefore(LocalTime.of(6, 0));
    }

    public UUID getRequestorId() {
        return this.requestor != null ? requestor.getUserId() : null;
    }
}
