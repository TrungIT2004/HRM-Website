package com.minhtrung.hrm.resignation.repositories;

import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.minhtrung.hrm.resignation.entities.ResignationRequest;
import com.minhtrung.hrm.resignation.enums.ResignationStatus;

public interface ResignationRequestRepository extends JpaRepository<ResignationRequest, UUID>, JpaSpecificationExecutor<ResignationRequest> {

    // 1. Danh sách đơn của cá nhân nhân viên
    @Query(value = "SELECT r FROM ResignationRequest r " +
                   "JOIN FETCH r.user u " +
                   "LEFT JOIN FETCH u.department " +
                   "LEFT JOIN FETCH u.job " +
                   "LEFT JOIN FETCH u.contracts " +
                   "LEFT JOIN FETCH r.manager " +
                   "LEFT JOIN FETCH r.executive " +
                   "WHERE u.userId = :userId " +
                   "ORDER BY r.createdAt DESC",
           countQuery = "SELECT COUNT(r) FROM ResignationRequest r WHERE r.user.userId = :userId")
    Page<ResignationRequest> findByUserIdWithDetails(@Param("userId") UUID userId, Pageable pageable);

    // 2. Danh sách đơn chờ duyệt bàn giao (Dành cho Trưởng phòng ban)
    @Query(value = "SELECT r FROM ResignationRequest r " +
                   "JOIN FETCH r.user u " +
                   "LEFT JOIN FETCH u.department d " +
                   "LEFT JOIN FETCH u.job " +
                   "LEFT JOIN FETCH u.contracts " +
                   "LEFT JOIN FETCH r.manager " +
                   "LEFT JOIN FETCH r.executive " +
                   "WHERE r.status = :status AND d.name = :departmentName AND u.userId != :currentUserId " +
                   "ORDER BY r.createdAt DESC",
           countQuery = "SELECT COUNT(r) FROM ResignationRequest r WHERE r.status = :status AND r.user.department.name = :departmentName AND r.user.userId != :currentUserId")
    Page<ResignationRequest> findDepartmentApprovals(
            @Param("status") ResignationStatus status,
            @Param("departmentName") String departmentName,
            @Param("currentUserId") UUID currentUserId,
            Pageable pageable);

    // 3. Danh sách đơn chờ duyệt cấp cao (Dành cho HR hoặc Ban Giám Đốc)
    @Query(value = "SELECT r FROM ResignationRequest r " +
                   "JOIN FETCH r.user u " +
                   "LEFT JOIN FETCH u.department d " +
                   "LEFT JOIN FETCH u.job j " +
                   "LEFT JOIN FETCH u.contracts " +
                   "LEFT JOIN FETCH r.manager " +
                   "LEFT JOIN FETCH r.executive " +
                   "WHERE u.userId != :currentUserId AND (" +
                   "  r.status = 'MANAGER_APPROVED' OR " +
                   "  (r.status = 'PENDING' AND (j.title LIKE 'Department Head%' OR d.name = 'Executive Leadership'))" +
                   ") ORDER BY r.createdAt DESC",
           countQuery = "SELECT COUNT(r) FROM ResignationRequest r WHERE r.user.userId != :currentUserId AND (" +
                        "  r.status = 'MANAGER_APPROVED' OR " +
                        "  (r.status = 'PENDING' AND (r.user.job.title LIKE 'Department Head%' OR r.user.department.name = 'Executive Leadership'))" +
                        ")")
    Page<ResignationRequest> findExecutiveApprovals(@Param("currentUserId") UUID currentUserId, Pageable pageable);

    // 4. Danh sách toàn bộ đơn công ty (Dành cho HR / BGĐ)
    @Query(value = "SELECT r FROM ResignationRequest r " +
                   "JOIN FETCH r.user u " +
                   "LEFT JOIN FETCH u.department " +
                   "LEFT JOIN FETCH u.job " +
                   "LEFT JOIN FETCH u.contracts " +
                   "LEFT JOIN FETCH r.manager " +
                   "LEFT JOIN FETCH r.executive " +
                   "WHERE (:status IS NULL OR r.status = :status) " +
                   "ORDER BY r.createdAt DESC",
           countQuery = "SELECT COUNT(r) FROM ResignationRequest r WHERE (:status IS NULL OR r.status = :status)")
    Page<ResignationRequest> findAllCompanyRequests(@Param("status") ResignationStatus status, Pageable pageable);

    // 5. Kiểm tra xem nhân viên có đang có đơn chờ duyệt hoặc đã duyệt chưa (chặn nộp trùng lặp)
    boolean existsByUser_UserIdAndStatusIn(UUID userId, Collection<ResignationStatus> statuses);

    // 6. Lấy đơn đang hiệu lực của 1 user
    Optional<ResignationRequest> findFirstByUser_UserIdAndStatusInOrderByCreatedAtDesc(UUID userId, Collection<ResignationStatus> statuses);

    // 7. Lấy danh sách các đơn đã APPROVED có ngày làm việc cuối cùng <= ngày chỉ định (cho scheduler)
    List<ResignationRequest> findByStatusAndLastWorkingDateLessThanEqual(ResignationStatus status, LocalDate date);

    // 8. Kiểm tra đơn thôi việc đã APPROVED hoặc COMPLETED kết thúc trong khoảng ngày (dùng cho tính lương tháng cuối)
    Optional<ResignationRequest> findFirstByUser_UserIdAndStatusInAndLastWorkingDateBetween(
            UUID userId, Collection<ResignationStatus> statuses, LocalDate startDate, LocalDate endDate);
}
