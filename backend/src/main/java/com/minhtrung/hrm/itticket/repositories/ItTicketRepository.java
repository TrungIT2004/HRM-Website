package com.minhtrung.hrm.itticket.repositories;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.minhtrung.hrm.itticket.entities.ItTicket;
import com.minhtrung.hrm.itticket.enums.ItTicketStatus;

@Repository
public interface ItTicketRepository extends JpaRepository<ItTicket, UUID> {
    List<ItTicket> findByReporter_UserIdOrderByCreatedAtDesc(UUID reporterId);

    List<ItTicket> findByStatusInOrderByCreatedAtDesc(List<ItTicketStatus> statuses);

    List<ItTicket> findByStatusOrderByCreatedAtDesc(ItTicketStatus status);

    List<ItTicket> findByCreatedAtBetweenOrderByCreatedAtDesc(LocalDateTime from, LocalDateTime to);
}
