package com.minhtrung.hrm.documents.entities;

import java.time.LocalDateTime;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.annotations.UuidGenerator;

import com.minhtrung.hrm.documents.enums.DocumentCategory;
import com.minhtrung.hrm.documents.enums.DocumentFileType;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
@Builder
@Entity
@Table(name = "documents")
public class Document {
    @Id
    @UuidGenerator(style = UuidGenerator.Style.TIME)
    private UUID documentId;

    @Enumerated(EnumType.STRING)
    @Column(name = "category", nullable = false, length = 20)
    private DocumentCategory category;

    @Column(name = "document_name", nullable = false, length = 255)
    private String documentName;

    @Column(name = "document_title", nullable = false, length = 255)
    private String documentTitle;

    @Column(name = "file_url", nullable = false, length = 500)
    private String fileUrl;

    // ponytail: đường dẫn vật lý tương đối trong uploadDir (templates/<uuid>.ext), dùng khi xóa/thay file
    @Column(name = "file_path", nullable = false, length = 500)
    private String filePath;

    @Enumerated(EnumType.STRING)
    @Column(name = "file_type", nullable = false, length = 10)
    private DocumentFileType fileType;

    @Column(name = "file_size", nullable = false)
    private Long fileSize;

    @Column(name = "summary", columnDefinition = "TEXT")
    private String summary;

    // ponytail: UUID trần thay vì @ManyToOne User — list public không cần fetch join, khỏi N+1
    @Column(name = "uploader_id")
    private UUID uploaderId;

    // Snapshot tên người đăng lúc upload (AiController cũng so ownership bằng fullName chuỗi)
    @Column(name = "uploader_name", length = 255)
    private String uploaderName;

    @Builder.Default
    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
