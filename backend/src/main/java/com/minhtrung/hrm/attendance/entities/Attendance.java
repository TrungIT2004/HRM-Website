package com.minhtrung.hrm.attendance.entities;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

import org.hibernate.annotations.SQLDelete;
import org.hibernate.annotations.SQLRestriction;
import org.hibernate.annotations.UuidGenerator;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.minhtrung.hrm.attendance.enums.AttendanceStatus;
import com.minhtrung.hrm.employees.entities.User;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
@Entity
@Table(name = "attendances", uniqueConstraints = @UniqueConstraint(name = "uk_attendance_user", columnNames = {
        "userId", "workDate" }))
// 1. Ghi đè lệnh DELETE mặc định thành câu lệnh UPDATE
@SQLDelete(sql = "UPDATE attendances SET is_deleted = true WHERE attendance_id = ?")
// 2. Tự động thêm điều kiện "is_deleted = false" vào TẤT CẢ các câu lệnh SELECT
@SQLRestriction("is_deleted = false")
public class Attendance {
    @Id
    @UuidGenerator(style = UuidGenerator.Style.TIME)
    private UUID attendanceId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "userId", referencedColumnName = "userId", foreignKey = @ForeignKey(name = "fk_attendance_user"))
    @JsonIgnore
    private User user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "shiftId", referencedColumnName = "shiftId", foreignKey = @ForeignKey(name = "fk_attendance_shift"))
    @JsonIgnore
    private WorkShift shift;

    @Column(nullable = false)
    private LocalDate workDate;

    @Column()
    private LocalTime clockInTime;

    @Column()
    private LocalTime clockOutTime;

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private AttendanceStatus status;

    @Column()
    private boolean isEdited = false;
    
    @Column()
    private String editedReason;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "edited_by", referencedColumnName = "userId", foreignKey = @ForeignKey(name = "fk_attendance_editor"))
    @JsonIgnore
    private User editor;

    @Column()
    private boolean isDeleted = false;

    public UUID getUserId() {
        return this.user != null ? user.getUserId() : null;
    }
}
