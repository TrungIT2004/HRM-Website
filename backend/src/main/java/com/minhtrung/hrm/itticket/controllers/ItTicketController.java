package com.minhtrung.hrm.itticket.controllers;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;
import com.minhtrung.hrm.common.context.RequestContextHolder;
import com.minhtrung.hrm.itticket.entities.ItTicket;
import com.minhtrung.hrm.itticket.services.ItTicketService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/it-tickets")
@RequiredArgsConstructor
public class ItTicketController {

    private final ItTicketService itTicketService;

    private TokenPayload me() {
        return RequestContextHolder.get().getTokenPayload();
    }

    @PostMapping
    public ResponseEntity<ItTicket> create(@RequestBody ItTicket ticket) {
        return ResponseEntity.status(HttpStatus.CREATED).body(itTicketService.create(ticket, null, me()));
    }

    @PostMapping(value = "/{ticketId}/image", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ItTicket> uploadImage(@PathVariable UUID ticketId,
            @RequestParam("file") MultipartFile file) {
        return ResponseEntity.ok(itTicketService.attachImage(ticketId, file, me()));
    }

    @GetMapping("/my")
    public ResponseEntity<List<ItTicket>> myTickets() {
        return ResponseEntity.ok(itTicketService.myTickets(me().getUserId()));
    }

    @GetMapping("/queue")
    public ResponseEntity<List<ItTicket>> queue(@RequestParam(defaultValue = "QUEUE") String status) {
        return ResponseEntity.ok(itTicketService.queue(me(), status));
    }

    @GetMapping("/overview")
    public ResponseEntity<Map<String, Object>> overview(@RequestParam int year, @RequestParam int month) {
        return ResponseEntity.ok(itTicketService.overview(year, month, me()));
    }

    @PatchMapping("/{ticketId}/claim")
    public ResponseEntity<ItTicket> claim(@PathVariable UUID ticketId) {
        return ResponseEntity.ok(itTicketService.claim(ticketId, me()));
    }

    @PatchMapping("/{ticketId}/resolve")
    public ResponseEntity<ItTicket> resolve(@PathVariable UUID ticketId, @RequestBody Map<String, String> body) {
        return ResponseEntity.ok(itTicketService.resolve(ticketId, body.get("resolveNote"), me()));
    }

    @PatchMapping("/{ticketId}/cancel")
    public ResponseEntity<ItTicket> cancel(@PathVariable UUID ticketId) {
        return ResponseEntity.ok(itTicketService.cancel(ticketId, me()));
    }
}
