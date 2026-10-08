package com.minhtrung.hrm.itticket.entities;

import java.time.LocalDateTime;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.annotations.UuidGenerator;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.minhtrung.hrm.employees.entities.User;
import com.minhtrung.hrm.itticket.enums.ItTicketCategory;
import com.minhtrung.hrm.itticket.enums.ItTicketPriority;
import com.minhtrung.hrm.itticket.enums.ItTicketStatus;

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
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@NoArgsConstructor
@Getter
@Setter
@Entity
@Table(name = "it_tickets")
public class ItTicket {
    @Id
    @UuidGenerator(style = UuidGenerator.Style.TIME)
    private UUID ticketId;

    @NotBlank(message = "Thiết bị hỏng không được để trống")
    @Column(name = "device_info", nullable = false, columnDefinition = "TEXT")
    private String deviceInfo;

    @NotNull(message = "Loại sự cố không được để trống")
    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private ItTicketCategory category;

    @NotBlank(message = "Mô tả không được để trống")
    @Column(nullable = false, columnDefinition = "TEXT")
    private String description;

    @Column(columnDefinition = "TEXT")
    private String location;

    @Column(name = "image_url")
    private String imageUrl;

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private ItTicketPriority priority = ItTicketPriority.NORMAL;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "reporterId", referencedColumnName = "userId", foreignKey = @ForeignKey(name = "fk_ticket_reporter"))
    @JsonIgnore
    private User reporter;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assigneeId", referencedColumnName = "userId", foreignKey = @ForeignKey(name = "fk_ticket_assignee"))
    @JsonIgnore
    private User assignee;

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private ItTicketStatus status = ItTicketStatus.OPEN;

    @Column(name = "resolve_note", columnDefinition = "TEXT")
    private String resolveNote;

    @Column(name = "resolved_at")
    private LocalDateTime resolvedAt;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    public UUID getReporterId() {
        return this.reporter != null ? reporter.getUserId() : null;
    }

    public UUID getAssigneeId() {
        return this.assignee != null ? assignee.getUserId() : null;
    }
}
