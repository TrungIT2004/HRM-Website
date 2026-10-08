package com.minhtrung.hrm.asset.controllers;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import com.minhtrung.hrm.asset.entities.Asset;
import com.minhtrung.hrm.asset.entities.AssetAssignment;
import com.minhtrung.hrm.asset.entities.AssetCategory;
import com.minhtrung.hrm.asset.entities.AssetImage;
import com.minhtrung.hrm.asset.entities.AssetInventoryLog;
import com.minhtrung.hrm.asset.entities.AssetMaintenance;
import com.minhtrung.hrm.asset.entities.AssetRequest;
import com.minhtrung.hrm.asset.services.AssetService;
import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;
import com.minhtrung.hrm.common.context.RequestContextHolder;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/assets")
@RequiredArgsConstructor
public class AssetController {

    private final AssetService assetService;

    private TokenPayload me() {
        return RequestContextHolder.get().getTokenPayload();
    }

    // ─── DANH MỤC ───
    @PostMapping("/categories")
    public ResponseEntity<AssetCategory> createCategory(@Valid @RequestBody AssetCategory category) {
        return ResponseEntity.status(HttpStatus.CREATED).body(assetService.createCategory(category, me()));
    }

    @GetMapping("/categories")
    public ResponseEntity<List<AssetCategory>> listCategories() {
        return ResponseEntity.ok(assetService.listCategories());
    }

    // ─── TÀI SẢN ───
    @PostMapping
    public ResponseEntity<Asset> createAsset(@Valid @RequestBody Asset asset) {
        return ResponseEntity.status(HttpStatus.CREATED).body(assetService.createAsset(asset, me()));
    }

    @GetMapping
    public ResponseEntity<List<Asset>> listAssets() {
        return ResponseEntity.ok(assetService.listAssets(me()));
    }

    @GetMapping("/{assetId}")
    public ResponseEntity<Asset> getAsset(@PathVariable UUID assetId) {
        return ResponseEntity.ok(assetService.getAsset(assetId, me()));
    }

    @PutMapping("/{assetId}")
    public ResponseEntity<Asset> updateAsset(@PathVariable UUID assetId, @RequestBody Asset patch) {
        return ResponseEntity.ok(assetService.updateAsset(assetId, patch, me()));
    }

    @DeleteMapping("/{assetId}")
    public ResponseEntity<Map<String, String>> deleteAsset(@PathVariable UUID assetId) {
        assetService.deleteAsset(assetId, me());
        return ResponseEntity.ok(Map.of("message", "Đã xóa tài sản"));
    }

    @GetMapping("/{assetId}/images")
    public ResponseEntity<List<AssetImage>> assetImages(@PathVariable UUID assetId) {
        return ResponseEntity.ok(assetService.assetImages(assetId, me()));
    }

    @PostMapping(value = "/{assetId}/images", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<AssetImage> uploadImage(@PathVariable UUID assetId,
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "caption", required = false) String caption) {
        return ResponseEntity.status(HttpStatus.CREATED).body(assetService.uploadImage(assetId, file, caption, me()));
    }

    @DeleteMapping("/images/{imageId}")
    public ResponseEntity<Map<String, String>> deleteImage(@PathVariable UUID imageId) {
        assetService.deleteImage(imageId, me());
        return ResponseEntity.ok(Map.of("message", "Đã xóa ảnh"));
    }

    @PutMapping("/categories/{categoryId}")
    public ResponseEntity<AssetCategory> updateCategory(@PathVariable UUID categoryId, @RequestBody AssetCategory patch) {
        return ResponseEntity.ok(assetService.updateCategory(categoryId, patch, me()));
    }

    @DeleteMapping("/categories/{categoryId}")
    public ResponseEntity<Map<String, String>> deleteCategory(@PathVariable UUID categoryId) {
        assetService.deleteCategory(categoryId, me());
        return ResponseEntity.ok(Map.of("message", "Đã xóa loại tài sản"));
    }

    @GetMapping("/{assetId}/timeline")
    public ResponseEntity<List<Map<String, Object>>> timeline(@PathVariable UUID assetId) {
        return ResponseEntity.ok(assetService.timeline(assetId, me()));
    }

    // ─── ĐƠN XIN ───
    @PostMapping("/requests")
    public ResponseEntity<AssetRequest> createRequest(@Valid @RequestBody AssetRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(assetService.createRequest(request, me()));
    }

    @GetMapping("/requests/my")
    public ResponseEntity<List<AssetRequest>> myRequests() {
        return ResponseEntity.ok(assetService.myRequests(me().getUserId()));
    }

    @GetMapping("/requests/approvals")
    public ResponseEntity<List<AssetRequest>> pendingRequests() {
        return ResponseEntity.ok(assetService.pendingRequests(me()));
    }

    @PatchMapping("/requests/{requestId}/handle")
    public ResponseEntity<AssetRequest> handleRequest(@PathVariable UUID requestId,
            @RequestBody Map<String, String> body) {
        boolean approve = Boolean.parseBoolean(body.getOrDefault("approve", "false"));
        return ResponseEntity.ok(assetService.handleRequest(requestId, approve, body.get("rejectionReason"), me()));
    }

    @DeleteMapping("/requests/{requestId}")
    public ResponseEntity<Map<String, String>> cancelRequest(@PathVariable UUID requestId) {
        assetService.cancelRequest(requestId, me().getUserId());
        return ResponseEntity.ok(Map.of("message", "Đã hủy đơn xin tài sản"));
    }

    @GetMapping("/requests/urgent")
    public ResponseEntity<List<AssetRequest>> urgentRequests(@RequestParam(defaultValue = "7") int days) {
        return ResponseEntity.ok(assetService.urgentRequests(days, me()));
    }

    // ─── CẤP PHÁT / THU HỒI ───
    @PostMapping("/assignments")
    public ResponseEntity<AssetAssignment> assign(@RequestBody Map<String, String> body) {
        UUID departmentId = body.get("departmentId") != null && !body.get("departmentId").isBlank()
                ? UUID.fromString(body.get("departmentId")) : null;
        return ResponseEntity.status(HttpStatus.CREATED).body(assetService.assign(
                UUID.fromString(body.get("requestId")), UUID.fromString(body.get("assetId")),
                departmentId, body.get("conditionOnAssign"), me()));
    }

    @GetMapping("/assignments/my")
    public ResponseEntity<List<AssetAssignment>> myAssets() {
        return ResponseEntity.ok(assetService.myAssets(me()));
    }

    @GetMapping("/assignments/pending-returns")
    public ResponseEntity<List<AssetAssignment>> pendingReturns() {
        return ResponseEntity.ok(assetService.pendingReturns(me()));
    }

    @PostMapping("/assignments/{assignmentId}/request-return")
    public ResponseEntity<AssetAssignment> requestReturn(@PathVariable UUID assignmentId) {
        return ResponseEntity.ok(assetService.requestReturn(assignmentId, me().getUserId()));
    }

    @PostMapping("/assignments/{assignmentId}/confirm-return")
    public ResponseEntity<AssetAssignment> confirmReturn(@PathVariable UUID assignmentId,
            @RequestBody Map<String, String> body) {
        return ResponseEntity.ok(assetService.confirmReturn(assignmentId, body.get("conditionOnReturn"), me()));
    }

    @PostMapping("/assignments/{assignmentId}/mark-lost")
    public ResponseEntity<AssetAssignment> markLost(@PathVariable UUID assignmentId) {
        return ResponseEntity.ok(assetService.markLost(assignmentId, me()));
    }

    @GetMapping("/assignments/due-return")
    public ResponseEntity<List<AssetAssignment>> dueReturns(@RequestParam(defaultValue = "7") int days) {
        return ResponseEntity.ok(assetService.dueReturns(days, me()));
    }

    // ─── BẢO TRÌ / KIỂM KÊ / ẢNH ───
    @PostMapping("/maintenances")
    public ResponseEntity<AssetMaintenance> reportMaintenance(@RequestBody AssetMaintenance maintenance) {
        return ResponseEntity.status(HttpStatus.CREATED).body(assetService.reportMaintenance(maintenance, me()));
    }

    @GetMapping("/{assetId}/maintenances")
    public ResponseEntity<List<AssetMaintenance>> maintenances(@PathVariable UUID assetId) {
        return ResponseEntity.ok(assetService.maintenances(assetId, me()));
    }

    @PostMapping("/inventory")
    public ResponseEntity<AssetInventoryLog> inventoryCheck(@RequestBody AssetInventoryLog log) {
        return ResponseEntity.status(HttpStatus.CREATED).body(assetService.inventoryCheck(log, me()));
    }

    @PostMapping("/images")
    public ResponseEntity<AssetImage> addImage(@Valid @RequestBody AssetImage image) {
        return ResponseEntity.status(HttpStatus.CREATED).body(assetService.addImage(image, me()));
    }
}
