package com.minhtrung.hrm.services;

import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import net.coobird.thumbnailator.Thumbnails;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

@Service
@Slf4j
public class FileStorageService {

    @Value("${file.upload-dir}")
    private String uploadDir;

    private Path fileStorageLocation;

    private static final List<String> IMAGE_MIME_TYPES = Arrays.asList(
            "image/jpeg", "image/png", "image/gif", "image/bmp", "image/webp"
    );

    private static final int MAX_AVATAR_SIZE = 500;

    @PostConstruct
    public void init() {
        this.fileStorageLocation = Paths.get(uploadDir).toAbsolutePath().normalize();
        try {
            Files.createDirectories(this.fileStorageLocation);
        } catch (Exception ex) {
            throw new RuntimeException("Could not create upload directory", ex);
        }
    }

    /**
     * Lưu avatar nhân viên (nén webp 500x500 và trả về URL)
     */
    public String storeAvatar(MultipartFile file, UUID userId) {
        try {
            String fileName = storeFile(file, "avatars");
            return "/uploads/avatars/" + fileName;
        } catch (IOException e) {
            log.error("Failed to store avatar for user {}", userId, e);
            throw new RuntimeException("Không thể lưu file ảnh: " + e.getMessage(), e);
        }
    }

    public String storeFile(MultipartFile file, String subFolder) throws IOException {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("File is empty or null");
        }

        Path targetFolder = this.fileStorageLocation.resolve(subFolder).normalize();
        Files.createDirectories(targetFolder);

        String originalFilename = file.getOriginalFilename();
        String contentType = file.getContentType();
        String extension = getFileExtension(originalFilename);

        String fileName;
        Path targetLocation;

        if (isImageFile(contentType, extension)) {
            fileName = UUID.randomUUID().toString() + ".webp";
            targetLocation = targetFolder.resolve(fileName);
            compressImage(file, targetLocation, MAX_AVATAR_SIZE);
            log.debug("Compressed image saved: {}", fileName);
        } else {
            String ext = (extension != null && !extension.isEmpty()) ? "." + extension : "";
            fileName = UUID.randomUUID().toString() + ext;
            targetLocation = targetFolder.resolve(fileName);
            Files.copy(file.getInputStream(), targetLocation, StandardCopyOption.REPLACE_EXISTING);
            log.debug("File saved: {}", fileName);
        }

        return fileName;
    }

    private void compressImage(MultipartFile file, Path targetLocation, int maxSize) throws IOException {
        Thumbnails.of(file.getInputStream())
                .size(maxSize, maxSize)
                .outputQuality(0.8f)
                .outputFormat("webp")
                .toFile(targetLocation.toFile());
    }

    private boolean isImageFile(String contentType, String extension) {
        if (contentType != null && IMAGE_MIME_TYPES.contains(contentType)) {
            return true;
        }
        if (extension != null) {
            return extension.toLowerCase().matches("(jpg|jpeg|png|gif|bmp|webp)");
        }
        return false;
    }

    private String getFileExtension(String filename) {
        if (filename == null || filename.lastIndexOf(".") == -1) {
            return "";
        }
        return filename.substring(filename.lastIndexOf(".") + 1);
    }

    public boolean deleteFile(String filePath) {
        try {
            Path file = this.fileStorageLocation.resolve(filePath).normalize();
            return Files.deleteIfExists(file);
        } catch (IOException e) {
            log.warn("Could not delete file: {}", filePath, e);
            return false;
        }
    }
}