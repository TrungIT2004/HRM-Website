package com.minhtrung.hrm.asset.entities;

import java.time.LocalDateTime;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.annotations.UuidGenerator;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@NoArgsConstructor
@Getter
@Setter
@Entity
@Table(name = "asset_categories")
public class AssetCategory {
    @Id
    @UuidGenerator(style = UuidGenerator.Style.TIME)
    private UUID categoryId;

    @NotBlank(message = "Tên loại tài sản không được để trống")
    @Column(nullable = false, unique = true)
    private String name;

    @NotBlank(message = "Tiền tố mã không được để trống")
    @Column(name = "code_prefix", nullable = false, unique = true, length = 10)
    private String codePrefix;

    @Column
    private String description;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
