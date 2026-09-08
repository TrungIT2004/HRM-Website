package com.minhtrung.social_app.seeder;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping("/api/seeder")
@RequiredArgsConstructor
@Slf4j
public class DataSeederController {

    private final DataSeederService dataSeederService;

    @PostMapping("/mock-data")
    public ResponseEntity<Map<String, Object>> seedMockData(
            @RequestParam(defaultValue = "2026") int year,
            @RequestParam(defaultValue = "1") int fromMonth,
            @RequestParam(defaultValue = "8") int toMonth,
            @RequestParam(defaultValue = "true") boolean clearExisting,
            @RequestParam(defaultValue = "true") boolean autoGenerateTimesheets) {
        log.info("REST request to seed mock data: year={}, fromMonth={}, toMonth={}, clearExisting={}, autoGenerateTimesheets={}",
                year, fromMonth, toMonth, clearExisting, autoGenerateTimesheets);
        Map<String, Object> result = dataSeederService.seedMockData(year, fromMonth, toMonth, clearExisting, autoGenerateTimesheets);
        return ResponseEntity.ok(result);
    }
}
