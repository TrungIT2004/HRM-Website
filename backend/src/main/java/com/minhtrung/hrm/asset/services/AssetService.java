package com.minhtrung.hrm.asset.services;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.multipart.MultipartFile;

import com.minhtrung.hrm.asset.entities.Asset;
import com.minhtrung.hrm.asset.entities.AssetAssignment;
import com.minhtrung.hrm.asset.entities.AssetCategory;
import com.minhtrung.hrm.asset.entities.AssetImage;
import com.minhtrung.hrm.asset.entities.AssetInventoryLog;
import com.minhtrung.hrm.asset.entities.AssetMaintenance;
import com.minhtrung.hrm.asset.entities.AssetRequest;
import com.minhtrung.hrm.asset.enums.AssetErrorCode;
import com.minhtrung.hrm.asset.enums.AssetRequestStatus;
import com.minhtrung.hrm.asset.enums.AssetStatus;
import com.minhtrung.hrm.asset.enums.AssignmentStatus;
import com.minhtrung.hrm.asset.enums.MaintenanceStatus;
import com.minhtrung.hrm.asset.exceptions.AssetException;
import com.minhtrung.hrm.asset.repositories.AssetAssignmentRepository;
import com.minhtrung.hrm.asset.repositories.AssetCategoryRepository;
import com.minhtrung.hrm.asset.repositories.AssetImageRepository;
import com.minhtrung.hrm.asset.repositories.AssetInventoryLogRepository;
import com.minhtrung.hrm.asset.repositories.AssetMaintenanceRepository;
import com.minhtrung.hrm.asset.repositories.AssetRepository;
import com.minhtrung.hrm.asset.repositories.AssetRequestRepository;
import com.minhtrung.hrm.auth.dtos.internals.TokenPayload;
import com.minhtrung.hrm.employees.entities.User;
import com.minhtrung.hrm.employees.repositories.DepartmentRepository;
import com.minhtrung.hrm.employees.repositories.UserRepository;
import com.minhtrung.hrm.permissions.enums.PermissionKey;
import com.minhtrung.hrm.permissions.services.PermissionService;
import com.minhtrung.hrm.services.FileStorageService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
@RequiredArgsConstructor
public class AssetService {

    private final AssetCategoryRepository categoryRepository;
    private final AssetRepository assetRepository;
    private final AssetRequestRepository requestRepository;
    private final AssetAssignmentRepository assignmentRepository;
    private final AssetMaintenanceRepository maintenanceRepository;
    private final AssetInventoryLogRepository inventoryRepository;
    private final AssetImageRepository imageRepository;
    private final UserRepository userRepository;
    private final DepartmentRepository departmentRepository;
    private final PermissionService permissionService;
    private final FileStorageService fileStorageService;

    // ─── PHÂN QUYỀN (không hardcode dept/job — chỉ đọc bảng grants, SUPER_ADMIN bypass) ───

    // ponytail: mirror định nghĩa sysadmin của AdminService — gom về 1 chỗ khi định nghĩa đổi lần thứ 2
    private boolean isSysAdmin(TokenPayload me) {
        if (me == null || me.getJob() == null) return false;
        boolean isIT = "Information Technology".equalsIgnoreCase(me.getDepartment())
                || "IT".equalsIgnoreCase(me.getDepartment());
        if (!isIT) return false;
        String job = me.getJob();
        return job.contains("System Administrator") || job.contains("Admin")
                || job.equalsIgnoreCase("SUPER_ADMIN") || job.toLowerCase().contains("super admin");
    }

    private boolean canManage(TokenPayload me) {
        return me != null && (isSysAdmin(me)
                || permissionService.hasPermission(me.getUserId(), PermissionKey.MANAGE_ASSETS));
    }

    private void requireManage(TokenPayload me) {
        if (!canManage(me)) {
            throw new AssetException(AssetErrorCode.INSUFFICIENT_PERMISSION,
                    "Bạn cần quyền quản lý tài sản (MANAGE_ASSETS) để thực hiện thao tác này");
        }
    }

    private void requireView(TokenPayload me) {
        if (me == null) throw new AssetException(AssetErrorCode.INSUFFICIENT_PERMISSION, "Yêu cầu đăng nhập");
        if (!canManage(me) && !permissionService.hasPermission(me.getUserId(), PermissionKey.VIEW_ASSETS)) {
            throw new AssetException(AssetErrorCode.INSUFFICIENT_PERMISSION,
                    "Bạn cần quyền xem tài sản (VIEW_ASSETS) để thực hiện thao tác này");
        }
    }

    // ─── DANH MỤC ───

    @Transactional
    public AssetCategory createCategory(AssetCategory category, TokenPayload me) {
        requireManage(me);
        category.setCategoryId(null);
        return categoryRepository.save(category);
    }

    @Transactional
    public AssetCategory updateCategory(UUID categoryId, AssetCategory patch, TokenPayload me) {
        requireManage(me);
        AssetCategory category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new AssetException(AssetErrorCode.CATEGORY_NOT_FOUND, "Không tìm thấy loại tài sản"));
        // ponytail: codePrefix bất biến (mã tài sản đã sinh từ nó)
        if (patch.getName() != null) category.setName(patch.getName());
        if (patch.getDescription() != null) category.setDescription(patch.getDescription());
        return categoryRepository.save(category);
    }

    @Transactional
    public void deleteCategory(UUID categoryId, TokenPayload me) {
        requireManage(me);
        AssetCategory category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new AssetException(AssetErrorCode.CATEGORY_NOT_FOUND, "Không tìm thấy loại tài sản"));
        if (assetRepository.countByCategory_CategoryId(categoryId) > 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Loại này còn tài sản trong kho — chuyển hết tài sản đi nơi khác trước khi xóa");
        }
        categoryRepository.delete(category);
    }

    @Transactional(readOnly = true)
    public List<AssetCategory> listCategories() {
        return categoryRepository.findAll();
    }

    // ─── TÀI SẢN (nhập kho, mã auto PREFIX-0001) ───

    @Transactional
    public Asset createAsset(Asset asset, TokenPayload me) {
        requireManage(me);
        AssetCategory category = categoryRepository.findById(asset.getCategoryId())
                .orElseThrow(() -> new AssetException(AssetErrorCode.CATEGORY_NOT_FOUND, "Không tìm thấy loại tài sản"));
        asset.setAssetId(null);
        asset.setCategory(category);
        asset.setStatus(AssetStatus.available);
        asset.setCreatedBy(userRepository.getReferenceById(me.getUserId()));
        // ponytail: count+1 đủ cho V1 (nhập kho là thao tác tay, hiếm) — unique constraint đỡ并发, đụng thì thử lại 1 lần
        asset.setAssetCode(nextAssetCode(category));
        try {
            return assetRepository.save(asset);
        } catch (DataIntegrityViolationException e) {
            asset.setAssetCode(nextAssetCode(category));
            return assetRepository.save(asset);
        }
    }

    private String nextAssetCode(AssetCategory category) {
        long n = categoryRepository.findById(category.getCategoryId())
                .map(c -> assetRepository.countByCategory_CategoryId(c.getCategoryId()))
                .orElse(0L);
        return String.format("%s-%04d", category.getCodePrefix(), n + 1);
    }

    @Transactional(readOnly = true)
    public List<Asset> listAssets(TokenPayload me) {
        requireView(me);
        return assetRepository.findAll();
    }

    @Transactional(readOnly = true)
    public Asset getAsset(UUID assetId, TokenPayload me) {
        if (me == null) throw new AssetException(AssetErrorCode.INSUFFICIENT_PERMISSION, "Yêu cầu đăng nhập");
        Asset asset = assetRepository.findById(assetId)
                .orElseThrow(() -> new AssetException(AssetErrorCode.ASSET_NOT_FOUND, "Không tìm thấy tài sản"));
        // ponytail: người đang giữ được xem đồ của mình dù không có VIEW_ASSETS
        boolean holder = asset.getCurrentHolder() != null && me.getUserId().equals(asset.getCurrentHolder().getUserId());
        if (!holder) requireView(me);
        return asset;
    }

    @Transactional
    public Asset updateAsset(UUID assetId, Asset patch, TokenPayload me) {
        requireManage(me);
        Asset asset = assetRepository.findById(assetId)
                .orElseThrow(() -> new AssetException(AssetErrorCode.ASSET_NOT_FOUND, "Không tìm thấy tài sản"));
        // ponytail: mã + loại bất biến (mã đã in QR), người giữ chỉ đổi qua luồng cấp/thu
        if (patch.getName() != null) asset.setName(patch.getName());
        if (patch.getSerialNumber() != null) asset.setSerialNumber(patch.getSerialNumber());
        if (patch.getSpecs() != null) asset.setSpecs(patch.getSpecs());
        if (patch.getPurchaseCost() != null) asset.setPurchaseCost(patch.getPurchaseCost());
        if (patch.getSupplier() != null) asset.setSupplier(patch.getSupplier());
        if (patch.getWarrantyUntil() != null) asset.setWarrantyUntil(patch.getWarrantyUntil());
        if (patch.getConditionNote() != null) asset.setConditionNote(patch.getConditionNote());
        if (patch.getLocation() != null) asset.setLocation(patch.getLocation());
        if (patch.getStatus() != null && patch.getStatus() != asset.getStatus()) {
            if (asset.getStatus() == AssetStatus.assigned) {
                throw new AssetException(AssetErrorCode.INVALID_STATUS_TRANSITION,
                        "Tài sản đang được mượn — đổi trạng thái qua luồng thu hồi, không sửa tay");
            }
            asset.setStatus(patch.getStatus());
        }
        return assetRepository.save(asset);
    }

    @Transactional
    public void deleteAsset(UUID assetId, TokenPayload me) {
        requireManage(me);
        Asset asset = assetRepository.findById(assetId)
                .orElseThrow(() -> new AssetException(AssetErrorCode.ASSET_NOT_FOUND, "Không tìm thấy tài sản"));
        if (!assignmentRepository.findByAsset_AssetIdOrderByAssignedAtDesc(assetId).isEmpty()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Tài sản đã từng cấp phát nên phải giữ lịch sử — chuyển sang 'retired' thay vì xóa");
        }
        imageRepository.deleteAll(imageRepository.findByAsset_AssetIdOrderByTakenAtDesc(assetId));
        inventoryRepository.deleteAll(inventoryRepository.findByAsset_AssetIdOrderByCheckedAtDesc(assetId));
        maintenanceRepository.deleteAll(maintenanceRepository.findByAsset_AssetIdOrderBySentAtDesc(assetId));
        assetRepository.delete(asset);
        log.info("Xóa tài sản {} bởi {}", asset.getAssetCode(), me.getUserId());
    }

    @Transactional(readOnly = true)
    public List<AssetImage> assetImages(UUID assetId, TokenPayload me) {
        getAsset(assetId, me); // tái dùng gate xem (MANAGE/VIEW/người giữ)
        return imageRepository.findByAsset_AssetIdOrderByTakenAtDesc(assetId);
    }

    @Transactional
    public AssetImage uploadImage(UUID assetId, MultipartFile file, String caption, TokenPayload me) {
        requireManage(me);
        Asset asset = assetRepository.findById(assetId)
                .orElseThrow(() -> new AssetException(AssetErrorCode.ASSET_NOT_FOUND, "Không tìm thấy tài sản"));
        final String fileName;
        try {
            fileName = fileStorageService.storeFile(file, "assets");
        } catch (IOException e) {
            throw new IllegalArgumentException("Không lưu được file ảnh: " + e.getMessage());
        }
        AssetImage image = new AssetImage();
        image.setAsset(asset);
        image.setImageUrl("/uploads/assets/" + fileName);
        image.setCaption(caption);
        // ponytail: ảnh đầu tiên tự làm cover — khỏi bắt user tick
        image.setCover(imageRepository.findByAsset_AssetIdOrderByTakenAtDesc(assetId).isEmpty());
        image.setTakenBy(userRepository.getReferenceById(me.getUserId()));
        return imageRepository.save(image);
    }

    @Transactional
    public void deleteImage(UUID imageId, TokenPayload me) {
        requireManage(me);
        AssetImage image = imageRepository.findById(imageId)
                .orElseThrow(() -> new AssetException(AssetErrorCode.ASSET_NOT_FOUND, "Không tìm thấy ảnh"));
        // ponytail: giữ file vật lý (tránh xóa nhầm khi trùng URL) — dọn batch khi ổ đầy
        imageRepository.delete(image);
    }

    // ─── ĐƠN XIN (mọi nhân viên) ───

    @Transactional
    public AssetRequest createRequest(AssetRequest request, TokenPayload me) {
        if (me == null) throw new AssetException(AssetErrorCode.INSUFFICIENT_PERMISSION, "Yêu cầu đăng nhập");
        AssetCategory category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new AssetException(AssetErrorCode.CATEGORY_NOT_FOUND, "Không tìm thấy loại tài sản"));
        request.setRequestId(null);
        request.setRequestor(userRepository.getReferenceById(me.getUserId()));
        request.setCategory(category);
        request.setStatus(AssetRequestStatus.pending);
        return requestRepository.save(request);
    }

    @Transactional(readOnly = true)
    public List<AssetRequest> myRequests(UUID userId) {
        return requestRepository.findByRequestor_UserIdOrderByCreatedAtDesc(userId);
    }

    @Transactional(readOnly = true)
    public List<AssetRequest> pendingRequests(TokenPayload me) {
        requireManage(me);
        return requestRepository.findByStatusInOrderByCreatedAtDesc(
                List.of(AssetRequestStatus.pending, AssetRequestStatus.approved));
    }

    @Transactional
    public AssetRequest handleRequest(UUID requestId, boolean approve, String rejectionReason, TokenPayload me) {
        requireManage(me);
        AssetRequest request = requestRepository.findById(requestId)
                .orElseThrow(() -> new AssetException(AssetErrorCode.REQUEST_NOT_FOUND, "Không tìm thấy đơn xin tài sản"));
        if (request.getStatus() != AssetRequestStatus.pending) {
            throw new AssetException(AssetErrorCode.ALREADY_PROCESSED_REQUEST, "Đơn đã được xử lý trước đó");
        }
        if (me.getUserId().equals(request.getRequestorId())) {
            throw new AssetException(AssetErrorCode.SELF_APPROVAL_NOT_ALLOWED, "Không thể tự duyệt đơn của chính mình");
        }
        request.setApprover(userRepository.getReferenceById(me.getUserId()));
        if (approve) {
            request.setStatus(AssetRequestStatus.approved);
        } else {
            request.setStatus(AssetRequestStatus.rejected);
            request.setRejectionReason(rejectionReason);
        }
        return requestRepository.save(request);
    }

    @Transactional
    public void cancelRequest(UUID requestId, UUID userId) {
        AssetRequest request = requestRepository.findById(requestId)
                .orElseThrow(() -> new AssetException(AssetErrorCode.REQUEST_NOT_FOUND, "Không tìm thấy đơn xin tài sản"));
        if (!userId.equals(request.getRequestorId())) {
            throw new AssetException(AssetErrorCode.NOT_RECORD_OWNER, "Bạn chỉ có thể hủy đơn của chính mình");
        }
        if (request.getStatus() != AssetRequestStatus.pending) {
            throw new AssetException(AssetErrorCode.CANNOT_CANCEL_NON_PENDING, "Chỉ hủy được đơn đang chờ duyệt");
        }
        request.setStatus(AssetRequestStatus.cancelled);
        requestRepository.save(request);
    }

    // ─── CẤP PHÁT / THU HỒI (trả 2 bước) ───

    @Transactional
    public AssetAssignment assign(UUID requestId, UUID assetId, String conditionOnAssign, TokenPayload me) {
        return assign(requestId, assetId, null, conditionOnAssign, me);
    }

    // ponytail: departmentId có → cấp cho cả phòng (user null); không có → cấp cá nhân như cũ
    @Transactional
    public AssetAssignment assign(UUID requestId, UUID assetId, UUID departmentId, String conditionOnAssign, TokenPayload me) {
        requireManage(me);
        AssetRequest request = requestRepository.findById(requestId)
                .orElseThrow(() -> new AssetException(AssetErrorCode.REQUEST_NOT_FOUND, "Không tìm thấy đơn xin tài sản"));
        if (request.getStatus() != AssetRequestStatus.approved) {
            throw new AssetException(AssetErrorCode.INVALID_STATUS_TRANSITION, "Chỉ cấp phát cho đơn đã duyệt");
        }
        Asset asset = assetRepository.findById(assetId)
                .orElseThrow(() -> new AssetException(AssetErrorCode.ASSET_NOT_FOUND, "Không tìm thấy tài sản"));
        if (asset.getStatus() != AssetStatus.available) {
            throw new AssetException(AssetErrorCode.ASSET_NOT_AVAILABLE, "Tài sản không ở trạng thái sẵn sàng cấp");
        }
        AssetAssignment assignment = new AssetAssignment();
        assignment.setAsset(asset);
        if (departmentId != null) {
            assignment.setUser(null);
            assignment.setDepartment(departmentRepository.getReferenceById(departmentId));
            asset.setCurrentHolder(null);
        } else {
            User holder = request.getRequestor();
            assignment.setUser(holder);
            asset.setCurrentHolder(holder);
        }
        assignment.setAssignedBy(userRepository.getReferenceById(me.getUserId()));
        assignment.setRequest(request);
        assignment.setAssignedAt(LocalDateTime.now());
        assignment.setExpectedReturnDate(request.getExpectedReturnDate());
        assignment.setConditionOnAssign(conditionOnAssign);
        assignment.setStatus(AssignmentStatus.active);
        asset.setStatus(AssetStatus.assigned);
        assetRepository.save(asset);
        request.setStatus(AssetRequestStatus.issued);
        requestRepository.save(request);
        log.info("Cấp tài sản {} theo đơn {}", asset.getAssetCode(), requestId);
        return assignmentRepository.save(assignment);
    }

    @Transactional(readOnly = true)
    public List<AssetAssignment> myAssets(UUID userId) {
        return assignmentRepository.findByUser_UserIdAndStatusOrderByAssignedAtDesc(userId, AssignmentStatus.active);
    }

    // ponytail: gộp đồ cá nhân + đồ phòng ban trong 1 call — frontend chia 2 mục theo getScope()
    @Transactional(readOnly = true)
    public List<AssetAssignment> myAssets(TokenPayload me) {
        List<AssetAssignment> mine = assignmentRepository.findByUser_UserIdAndStatusOrderByAssignedAtDesc(
                me.getUserId(), AssignmentStatus.active);
        UUID deptId = userRepository.findById(me.getUserId())
                .map(u -> u.getDepartment() != null ? u.getDepartment().getDepartmentId() : null)
                .orElse(null);
        if (deptId == null) return mine;
        mine.addAll(assignmentRepository.findByDepartment_DepartmentIdAndStatusOrderByAssignedAtDesc(
                deptId, AssignmentStatus.active));
        return mine;
    }

    @Transactional(readOnly = true)
    public List<AssetAssignment> pendingReturns(TokenPayload me) {
        requireManage(me);
        return assignmentRepository.findByStatusOrderByAssignedAtDesc(AssignmentStatus.pending_return);
    }

    @Transactional
    public AssetAssignment requestReturn(UUID assignmentId, UUID userId) {
        AssetAssignment assignment = assignmentRepository.findById(assignmentId)
                .orElseThrow(() -> new AssetException(AssetErrorCode.ASSIGNMENT_NOT_FOUND, "Không tìm thấy lượt bàn giao"));
        // ponytail: đồ phòng ban — bất kỳ thành viên nào trong phòng cũng được bấm trả, IT xác minh tại chỗ
        if (assignment.getDepartmentId() == null && !userId.equals(assignment.getUserId())) {
            throw new AssetException(AssetErrorCode.NOT_RECORD_OWNER, "Bạn chỉ có thể trả tài sản mình đang giữ");
        }
        if (assignment.getStatus() != AssignmentStatus.active) {
            throw new AssetException(AssetErrorCode.INVALID_STATUS_TRANSITION, "Lượt bàn giao không ở trạng thái đang mượn");
        }
        assignment.setStatus(AssignmentStatus.pending_return);
        return assignmentRepository.save(assignment);
    }

    @Transactional
    public AssetAssignment confirmReturn(UUID assignmentId, String conditionOnReturn, TokenPayload me) {
        requireManage(me);
        AssetAssignment assignment = assignmentRepository.findById(assignmentId)
                .orElseThrow(() -> new AssetException(AssetErrorCode.ASSIGNMENT_NOT_FOUND, "Không tìm thấy lượt bàn giao"));
        if (assignment.getStatus() != AssignmentStatus.pending_return) {
            throw new AssetException(AssetErrorCode.INVALID_STATUS_TRANSITION, "Chưa có yêu cầu trả cho lượt này");
        }
        assignment.setStatus(AssignmentStatus.returned);
        assignment.setReturnedAt(LocalDateTime.now());
        assignment.setConditionOnReturn(conditionOnReturn);
        Asset asset = assignment.getAsset();
        asset.setStatus(AssetStatus.available);
        asset.setCurrentHolder(null);
        if (conditionOnReturn != null) asset.setConditionNote(conditionOnReturn);
        assetRepository.save(asset);
        if (assignment.getRequest() != null) {
            assignment.getRequest().setStatus(AssetRequestStatus.returned);
            requestRepository.save(assignment.getRequest());
        }
        return assignmentRepository.save(assignment);
    }

    @Transactional
    public AssetAssignment markLost(UUID assignmentId, TokenPayload me) {
        requireManage(me);
        AssetAssignment assignment = assignmentRepository.findById(assignmentId)
                .orElseThrow(() -> new AssetException(AssetErrorCode.ASSIGNMENT_NOT_FOUND, "Không tìm thấy lượt bàn giao"));
        assignment.setStatus(AssignmentStatus.lost);
        assignment.getAsset().setStatus(AssetStatus.lost);
        assetRepository.save(assignment.getAsset());
        return assignmentRepository.save(assignment);
    }

    // ─── NHẮC VIỆC 7 NGÀY (cho MANAGE) ───

    @Transactional
    public List<AssetRequest> urgentRequests(int days, TokenPayload me) {
        requireManage(me);
        LocalDate now = LocalDate.now();
        return requestRepository.findByStatusInAndNeededByDateBetween(
                List.of(AssetRequestStatus.pending, AssetRequestStatus.approved), now, now.plusDays(days));
    }

    @Transactional
    public List<AssetAssignment> dueReturns(int days, TokenPayload me) {
        requireManage(me);
        LocalDate now = LocalDate.now();
        List<AssetAssignment> due = assignmentRepository.findByStatusAndExpectedReturnDateBetween(
                AssignmentStatus.active, now, now.plusDays(days));
        // ponytail: bound 2000-01-01 thay vì LocalDate.MIN (năm -999999999 vượt range DATE của Postgres → 500)
        LocalDate floor = LocalDate.of(2000, 1, 1);
        List<AssetAssignment> overdue = assignmentRepository.findByStatusAndExpectedReturnDateBetween(
                AssignmentStatus.active, floor, now.minusDays(1));
        for (AssetAssignment a : overdue) {
            a.setStatus(AssignmentStatus.overdue);
            assignmentRepository.save(a);
        }
        due.addAll(assignmentRepository.findByStatusAndExpectedReturnDateBetween(
                AssignmentStatus.overdue, floor, now.plusDays(days)));
        return due;
    }

    // ─── BẢO TRÌ / KIỂM KÊ / ẢNH ───

    @Transactional
    public AssetMaintenance reportMaintenance(AssetMaintenance maintenance, TokenPayload me) {
        requireManage(me);
        Asset asset = assetRepository.findById(maintenance.getAssetId())
                .orElseThrow(() -> new AssetException(AssetErrorCode.ASSET_NOT_FOUND, "Không tìm thấy tài sản"));
        maintenance.setMaintenanceId(null);
        maintenance.setAsset(asset);
        maintenance.setReportedBy(userRepository.getReferenceById(me.getUserId()));
        maintenance.setStatus(MaintenanceStatus.reported);
        maintenance.setSentAt(LocalDateTime.now());
        asset.setStatus(AssetStatus.under_maintenance);
        assetRepository.save(asset);
        return maintenanceRepository.save(maintenance);
    }

    @Transactional(readOnly = true)
    public List<AssetMaintenance> maintenances(UUID assetId, TokenPayload me) {
        requireView(me);
        return maintenanceRepository.findByAsset_AssetIdOrderBySentAtDesc(assetId);
    }

    @Transactional
    public AssetInventoryLog inventoryCheck(AssetInventoryLog log, TokenPayload me) {
        requireManage(me);
        Asset asset = assetRepository.findById(log.getAssetId())
                .orElseThrow(() -> new AssetException(AssetErrorCode.ASSET_NOT_FOUND, "Không tìm thấy tài sản"));
        log.setLogId(null);
        log.setAsset(asset);
        log.setCheckedBy(userRepository.getReferenceById(me.getUserId()));
        log.setCheckedAt(LocalDateTime.now());
        return inventoryRepository.save(log);
    }

    @Transactional
    public AssetImage addImage(AssetImage image, TokenPayload me) {
        requireManage(me);
        Asset asset = assetRepository.findById(image.getAssetId())
                .orElseThrow(() -> new AssetException(AssetErrorCode.ASSET_NOT_FOUND, "Không tìm thấy tài sản"));
        image.setImageId(null);
        image.setAsset(asset);
        if (image.getAssignment() != null && image.getAssignment().getAssignmentId() != null) {
            image.setAssignment(assignmentRepository.getReferenceById(image.getAssignment().getAssignmentId()));
        }
        if (image.getMaintenance() != null && image.getMaintenance().getMaintenanceId() != null) {
            image.setMaintenance(maintenanceRepository.getReferenceById(image.getMaintenance().getMaintenanceId()));
        }
        if (image.getInventoryLog() != null && image.getInventoryLog().getLogId() != null) {
            image.setInventoryLog(inventoryRepository.getReferenceById(image.getInventoryLog().getLogId()));
        }
        image.setTakenBy(userRepository.getReferenceById(me.getUserId()));
        return imageRepository.save(image);
    }

    // ─── TIMELINE VÒNG ĐỜI (gộp bằng Java — đủ cho V1, làm DB view khi 1 món > vài nghìn chặng) ───

    @Transactional(readOnly = true)
    public List<Map<String, Object>> timeline(UUID assetId, TokenPayload me) {
        Asset asset = getAsset(assetId, me);
        boolean manager = canManage(me);
        boolean everHeld = assignmentRepository.findByAsset_AssetIdOrderByAssignedAtDesc(assetId).stream()
                .anyMatch(a -> me.getUserId().equals(a.getUserId()));
        if (!manager && !everHeld) {
            throw new AssetException(AssetErrorCode.INSUFFICIENT_PERMISSION, "Bạn không có quyền xem vòng đời tài sản này");
        }
        List<Map<String, Object>> events = new ArrayList<>();
        events.add(event("created", asset.getCreatedAt(), null, "Nhập kho", asset.getConditionNote()));
        for (AssetAssignment a : assignmentRepository.findByAsset_AssetIdOrderByAssignedAtDesc(assetId)) {
            events.add(event("assign", a.getAssignedAt(), nameOf(a.getUser()), "Cấp phát", a.getConditionOnAssign()));
            if (a.getReturnedAt() != null) {
                events.add(event("return", a.getReturnedAt(), nameOf(a.getUser()), "Thu hồi (" + a.getStatus() + ")",
                        a.getConditionOnReturn()));
            }
        }
        for (AssetMaintenance m : maintenanceRepository.findByAsset_AssetIdOrderBySentAtDesc(assetId)) {
            events.add(event("maintenance", m.getSentAt() != null ? m.getSentAt() : m.getCreatedAt(), null,
                    m.getType() + " (" + m.getStatus() + ")", m.getDescription()));
        }
        for (AssetInventoryLog l : inventoryRepository.findByAsset_AssetIdOrderByCheckedAtDesc(assetId)) {
            events.add(event("inventory", l.getCheckedAt(), null,
                    l.isFound() ? "Kiểm kê: còn" : "Kiểm kê: mất", l.getConditionNote()));
        }
        events.sort(Comparator.comparing((Map<String, Object> e) -> (LocalDateTime) e.get("at")).reversed());
        return events;
    }

    private Map<String, Object> event(String kind, LocalDateTime at, String actor, String title, String note) {
        Map<String, Object> e = new HashMap<>();
        e.put("kind", kind);
        e.put("at", at);
        e.put("actor", actor);
        e.put("title", title);
        e.put("note", note);
        return e;
    }

    private String nameOf(User u) {
        return u != null ? (u.getFirstName() + " " + u.getLastName()).trim() : null;
    }

    // ─── CHO RESIGNATION HOOK ───

    @Transactional(readOnly = true)
    public boolean hasActiveHoldings(UUID userId) {
        return assignmentRepository.existsByUser_UserIdAndStatusIn(userId,
                List.of(AssignmentStatus.active, AssignmentStatus.pending_return, AssignmentStatus.overdue));
    }
}
