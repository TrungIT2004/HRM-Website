package com.minhtrung.hrm.itticket.services;

import java.io.IOException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;
import com.minhtrung.hrm.employees.repositories.UserRepository;
import com.minhtrung.hrm.itticket.entities.ItTicket;
import com.minhtrung.hrm.itticket.enums.ItTicketErrorCode;
import com.minhtrung.hrm.itticket.enums.ItTicketStatus;
import com.minhtrung.hrm.itticket.exceptions.ItTicketException;
import com.minhtrung.hrm.itticket.repositories.ItTicketRepository;
import com.minhtrung.hrm.permissions.enums.PermissionKey;
import com.minhtrung.hrm.permissions.services.PermissionService;
import com.minhtrung.hrm.services.FileStorageService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class ItTicketService {

    private final ItTicketRepository ticketRepository;
    private final UserRepository userRepository;
    private final PermissionService permissionService;
    private final FileStorageService fileStorageService;

    // ponytail: copy định nghĩa sysadmin của AssetService — gom về 1 helper chung khi cần chỗ thứ 3
    private boolean isSysAdmin(TokenPayload me) {
        if (me == null || me.getJob() == null) return false;
        boolean isIT = "Information Technology".equalsIgnoreCase(me.getDepartment())
                || "IT".equalsIgnoreCase(me.getDepartment());
        if (!isIT) return false;
        String job = me.getJob();
        return job.contains("System Administrator") || job.contains("Admin")
                || job.equalsIgnoreCase("SUPER_ADMIN") || job.toLowerCase().contains("super admin");
    }

    private boolean canHandle(TokenPayload me) {
        return me != null && (isSysAdmin(me)
                || permissionService.hasPermission(me.getUserId(), PermissionKey.IT_TICKET_HANDLE));
    }

    private void requireHandle(TokenPayload me) {
        if (!canHandle(me)) {
            throw new ItTicketException(ItTicketErrorCode.INSUFFICIENT_PERMISSION,
                    "Bạn cần quyền xử lý IT ticket (IT_TICKET_HANDLE) để thực hiện thao tác này");
        }
    }

    public boolean canHandleTicket(TokenPayload me) {
        return canHandle(me);
    }

    @Transactional
    public ItTicket create(ItTicket ticket, MultipartFile image, TokenPayload me) {
        if (me == null) throw new ItTicketException(ItTicketErrorCode.INSUFFICIENT_PERMISSION, "Yêu cầu đăng nhập");
        if (ticket.getDeviceInfo() == null || ticket.getDeviceInfo().isBlank()) {
            throw new ItTicketException(ItTicketErrorCode.VALIDATION_ERROR, "Thiết bị hỏng không được để trống");
        }
        if (ticket.getDescription() == null || ticket.getDescription().isBlank()) {
            throw new ItTicketException(ItTicketErrorCode.VALIDATION_ERROR, "Mô tả không được để trống");
        }
        if (ticket.getCategory() == null) {
            throw new ItTicketException(ItTicketErrorCode.VALIDATION_ERROR, "Loại sự cố không được để trống");
        }
        ticket.setTicketId(null);
        ticket.setReporter(userRepository.getReferenceById(me.getUserId()));
        ticket.setAssignee(null);
        ticket.setStatus(ItTicketStatus.OPEN);
        ticket.setResolveNote(null);
        ticket.setResolvedAt(null);
        if (image != null && !image.isEmpty()) {
            try {
                ticket.setImageUrl("/uploads/it-tickets/" + fileStorageService.storeFile(image, "it-tickets"));
            } catch (IOException e) {
                throw new ItTicketException(ItTicketErrorCode.VALIDATION_ERROR, "Không thể lưu ảnh: " + e.getMessage());
            }
        }
        return ticketRepository.save(ticket);
    }

    @Transactional
    public ItTicket attachImage(UUID ticketId, MultipartFile image, TokenPayload me) {
        if (me == null) throw new ItTicketException(ItTicketErrorCode.INSUFFICIENT_PERMISSION, "Yêu cầu đăng nhập");
        ItTicket ticket = ticketRepository.findById(ticketId)
                .orElseThrow(() -> new ItTicketException(ItTicketErrorCode.TICKET_NOT_FOUND, "Không tìm thấy ticket"));
        boolean owner = me.getUserId().equals(ticket.getReporterId());
        if (!owner && !canHandle(me)) {
            throw new ItTicketException(ItTicketErrorCode.NOT_RECORD_OWNER, "Bạn chỉ có thể thêm ảnh cho ticket của chính mình");
        }
        try {
            ticket.setImageUrl("/uploads/it-tickets/" + fileStorageService.storeFile(image, "it-tickets"));
        } catch (IOException e) {
            throw new ItTicketException(ItTicketErrorCode.VALIDATION_ERROR, "Không thể lưu ảnh: " + e.getMessage());
        }
        return ticketRepository.save(ticket);
    }

    @Transactional(readOnly = true)
    public List<ItTicket> myTickets(UUID userId) {
        return ticketRepository.findByReporter_UserIdOrderByCreatedAtDesc(userId);
    }

    @Transactional(readOnly = true)
    public List<ItTicket> queue(TokenPayload me, String status) {
        requireHandle(me);
        if (status == null || status.isBlank() || "QUEUE".equalsIgnoreCase(status)) {
            return ticketRepository.findByStatusInOrderByCreatedAtDesc(List.of(ItTicketStatus.OPEN, ItTicketStatus.IN_PROGRESS));
        }
        return ticketRepository.findByStatusOrderByCreatedAtDesc(ItTicketStatus.valueOf(status));
    }

    @Transactional
    public ItTicket claim(UUID ticketId, TokenPayload me) {
        requireHandle(me);
        ItTicket ticket = ticketRepository.findById(ticketId)
                .orElseThrow(() -> new ItTicketException(ItTicketErrorCode.TICKET_NOT_FOUND, "Không tìm thấy ticket"));
        if (ticket.getStatus() != ItTicketStatus.OPEN) {
            throw new ItTicketException(ItTicketErrorCode.INVALID_STATUS_TRANSITION, "Chỉ nhận ticket đang mở");
        }
        ticket.setAssignee(userRepository.getReferenceById(me.getUserId()));
        ticket.setStatus(ItTicketStatus.IN_PROGRESS);
        log.info("IT ticket {} được nhận bởi {}", ticketId, me.getUserId());
        return ticketRepository.save(ticket);
    }

    @Transactional
    public ItTicket resolve(UUID ticketId, String resolveNote, TokenPayload me) {
        requireHandle(me);
        ItTicket ticket = ticketRepository.findById(ticketId)
                .orElseThrow(() -> new ItTicketException(ItTicketErrorCode.TICKET_NOT_FOUND, "Không tìm thấy ticket"));
        if (ticket.getStatus() != ItTicketStatus.IN_PROGRESS) {
            throw new ItTicketException(ItTicketErrorCode.INVALID_STATUS_TRANSITION, "Chỉ đóng ticket đang xử lý");
        }
        if (ticket.getAssigneeId() != null && !ticket.getAssigneeId().equals(me.getUserId()) && !isSysAdmin(me)) {
            throw new ItTicketException(ItTicketErrorCode.NOT_RECORD_OWNER, "Chỉ người đã nhận mới được đóng ticket này");
        }
        ticket.setStatus(ItTicketStatus.DONE);
        ticket.setResolveNote(resolveNote);
        ticket.setResolvedAt(LocalDateTime.now());
        return ticketRepository.save(ticket);
    }

    @Transactional
    public ItTicket cancel(UUID ticketId, TokenPayload me) {
        if (me == null) throw new ItTicketException(ItTicketErrorCode.INSUFFICIENT_PERMISSION, "Yêu cầu đăng nhập");
        ItTicket ticket = ticketRepository.findById(ticketId)
                .orElseThrow(() -> new ItTicketException(ItTicketErrorCode.TICKET_NOT_FOUND, "Không tìm thấy ticket"));
        boolean owner = me.getUserId().equals(ticket.getReporterId());
        if (!owner && !canHandle(me)) {
            throw new ItTicketException(ItTicketErrorCode.NOT_RECORD_OWNER, "Bạn chỉ có thể hủy ticket của chính mình");
        }
        if (ticket.getStatus() != ItTicketStatus.OPEN && ticket.getStatus() != ItTicketStatus.IN_PROGRESS) {
            throw new ItTicketException(ItTicketErrorCode.INVALID_STATUS_TRANSITION, "Chỉ hủy được ticket chưa hoàn thành");
        }
        ticket.setStatus(ItTicketStatus.CANCELLED);
        return ticketRepository.save(ticket);
    }

    // ponytail: đếm bằng Java stream thay vì JPQL group-by — đủ cho V1 (vài trăm ticket/tháng), chuyển query khi >10k
    // ponytail: 1 call trả luôn tháng trước + tồn đọng + trend 6 tháng — khỏi 3 roundtrip, data nhỏ nên gộp trong service
    @Transactional(readOnly = true)
    public Map<String, Object> overview(int year, int month, TokenPayload me) {
        requireHandle(me);
        LocalDateTime from = LocalDate.of(year, month, 1).atStartOfDay();
        LocalDateTime to = from.plusMonths(1);
        LocalDateTime prevFrom = from.minusMonths(1);
        List<ItTicket> tickets = ticketRepository.findByCreatedAtBetweenOrderByCreatedAtDesc(from, to);
        List<ItTicket> prev = ticketRepository.findByCreatedAtBetweenOrderByCreatedAtDesc(prevFrom, from);
        Map<String, Long> byCategory = tickets.stream()
                .collect(Collectors.groupingBy(t -> t.getCategory().name(), Collectors.counting()));
        Map<String, Long> byStatus = tickets.stream()
                .collect(Collectors.groupingBy(t -> t.getStatus().name(), Collectors.counting()));
        Map<UUID, Long> byHandler = tickets.stream()
                .filter(t -> t.getAssigneeId() != null)
                .collect(Collectors.groupingBy(ItTicket::getAssigneeId, Collectors.counting()));
        List<Map<String, Object>> topHandlers = byHandler.entrySet().stream()
                .sorted(Map.Entry.<UUID, Long>comparingByValue().reversed())
                .limit(5)
                .map(e -> {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("assigneeId", e.getKey());
                    m.put("count", e.getValue());
                    return m;
                })
                .collect(Collectors.toList());
        long mine = tickets.stream().filter(t -> me.getUserId().equals(t.getAssigneeId())).count();
        long mineDone = tickets.stream()
                .filter(t -> me.getUserId().equals(t.getAssigneeId()) && t.getStatus() == ItTicketStatus.DONE)
                .count();
        long open = tickets.stream()
                .filter(t -> t.getStatus() == ItTicketStatus.OPEN || t.getStatus() == ItTicketStatus.IN_PROGRESS)
                .count();
        // tồn đọng lâu nhất mọi thời điểm (không giới hạn tháng) — IT lead nhìn là biết việc nào ì
        List<ItTicket> attention = ticketRepository.findByStatusInOrderByCreatedAtDesc(
                List.of(ItTicketStatus.OPEN, ItTicketStatus.IN_PROGRESS)).stream().limit(5).toList();
        // trend 6 tháng (1 query duy nhất, gom bằng Java)
        LocalDateTime trendFrom = from.minusMonths(5);
        List<Map<String, Object>> trend = ticketRepository.findByCreatedAtBetweenOrderByCreatedAtDesc(trendFrom, to).stream()
                .collect(Collectors.groupingBy(t -> t.getCreatedAt().getYear() * 100 + t.getCreatedAt().getMonthValue(),
                        Collectors.toList()))
                .entrySet().stream()
                .sorted(Map.Entry.comparingByKey())
                .map(e -> {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("ym", e.getKey());
                    m.put("total", (long) e.getValue().size());
                    m.put("done", e.getValue().stream().filter(t -> t.getStatus() == ItTicketStatus.DONE).count());
                    return m;
                })
                .collect(Collectors.toList());
        return Map.of(
                "total", tickets.size(),
                "mine", mine,
                "mineDone", mineDone,
                "open", open,
                "byCategory", byCategory,
                "byStatus", byStatus,
                "topHandlers", topHandlers,
                "prev", counts(prev, me.getUserId()),
                "attention", attention,
                "trend", trend);
    }

    private Map<String, Long> counts(List<ItTicket> tickets, UUID me) {
        long open = tickets.stream()
                .filter(t -> t.getStatus() == ItTicketStatus.OPEN || t.getStatus() == ItTicketStatus.IN_PROGRESS)
                .count();
        long done = tickets.stream().filter(t -> t.getStatus() == ItTicketStatus.DONE).count();
        long mineDone = tickets.stream()
                .filter(t -> me.equals(t.getAssigneeId()) && t.getStatus() == ItTicketStatus.DONE)
                .count();
        Map<String, Long> m = new LinkedHashMap<>();
        m.put("total", (long) tickets.size());
        m.put("done", done);
        m.put("mineDone", mineDone);
        m.put("open", open);
        return m;
    }
}
