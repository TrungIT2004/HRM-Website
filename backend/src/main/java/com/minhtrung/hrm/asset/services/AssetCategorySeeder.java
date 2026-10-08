package com.minhtrung.hrm.asset.services;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import com.minhtrung.hrm.asset.entities.AssetCategory;
import com.minhtrung.hrm.asset.repositories.AssetCategoryRepository;

import lombok.RequiredArgsConstructor;

/**
 * Gieo 9 loại tài sản mặc định. Chạy mỗi lần boot, chỉ INSERT thiếu (idempotent).
 */
@Component
@RequiredArgsConstructor
public class AssetCategorySeeder implements ApplicationRunner {

    private static final String[][] DEFAULTS = {
            { "Laptop", "LT", "Máy tính xách tay" },
            { "Desktop / PC", "PC", "Máy tính để bàn" },
            { "Điện thoại / Tablet", "PH", "Điện thoại, máy tính bảng" },
            { "Màn hình", "MN", "Màn hình rời" },
            { "Bàn phím / Chuột / Tai nghe", "PK", "Thiết bị ngoại vi" },
            { "Camera / An ninh", "CM", "Camera giám sát, webcam" },
            { "Máy in / Scanner", "PR", "Máy in, máy scan" },
            { "Thiết bị mạng", "NW", "Router, switch, access point" },
            { "Phụ kiện / Tiêu hao", "AC", "Dock, sạc, cáp — không track từng cái" },
    };

    private final AssetCategoryRepository categoryRepository;

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        for (String[] d : DEFAULTS) {
            if (categoryRepository.findByName(d[0]).isPresent()) continue;
            AssetCategory c = new AssetCategory();
            c.setName(d[0]);
            c.setCodePrefix(d[1]);
            c.setDescription(d[2]);
            categoryRepository.save(c);
        }
    }
}
