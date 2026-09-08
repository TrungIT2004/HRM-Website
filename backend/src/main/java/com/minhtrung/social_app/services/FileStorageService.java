package com.minhtrung.social_app.services;

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

    // Các loại ảnh hỗ trợ nén
    private static final List<String> IMAGE_MIME_TYPES = Arrays.asList(
            "image/jpeg", "image/png", "image/gif", "image/bmp", "image/webp"
    );

    // Các loại video (không nén, giữ nguyên)
    private static final List<String> VIDEO_MIME_TYPES = Arrays.asList(
            "video/mp4", "video/mpeg", "video/quicktime", "video/x-msvideo",
            "video/x-matroska", "video/webm", "video/ogg"
    );

    // Kích thước tối đa khi resize ảnh
    private static final int MAX_AVATAR_SIZE = 500;
    private static final int MAX_POST_IMAGE_SIZE = 1200;
    private static final int MAX_COMMENT_IMAGE_SIZE = 800;

    @PostConstruct
    public void init() {
        this.fileStorageLocation = Paths.get(uploadDir).toAbsolutePath().normalize();
        try {
            Files.createDirectories(this.fileStorageLocation);
        } catch (Exception ex) {
            throw new RuntimeException("Could not create upload directory", ex);
        }
    }

    public Path getFileStorageLocation() {
        return this.fileStorageLocation;
    }

    /**
     * Lưu file (tự động phân loại ảnh/video)
     */
    public String storeFile(MultipartFile file, String subFolder) throws IOException {
        return storeFile(file, subFolder, false);
    }

    /**
     * Lưu file với tuỳ chọn bỏ qua nén (giữ nguyên)
     */
    public String storeFile(MultipartFile file, String subFolder, boolean skipCompression) throws IOException {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("File is empty or null");
        }

        // Tạo thư mục con
        Path targetFolder = this.fileStorageLocation.resolve(subFolder).normalize();
        Files.createDirectories(targetFolder);

        String originalFilename = file.getOriginalFilename();
        String contentType = file.getContentType();
        String extension = getFileExtension(originalFilename);
        boolean isImage = isImageFile(contentType, extension);
        boolean isVideo = isVideoFile(contentType, extension);

        String fileName;
        Path targetLocation;

        if (isImage && !skipCompression) {
            // Nén ảnh → WebP
            fileName = UUID.randomUUID().toString() + ".webp";
            targetLocation = targetFolder.resolve(fileName);
            int maxSize = getMaxSizeForSubFolder(subFolder);
            compressImage(file, targetLocation, maxSize);
            log.debug("Compressed image saved: {}", fileName);
        } else if (isVideo) {
            // Video: giữ nguyên định dạng
            String ext = (extension != null && !extension.isEmpty()) ? "." + extension : "";
            fileName = UUID.randomUUID().toString() + ext;
            targetLocation = targetFolder.resolve(fileName);
            Files.copy(file.getInputStream(), targetLocation, StandardCopyOption.REPLACE_EXISTING);
            log.debug("Video saved: {}", fileName);
        } else {
            // Các file khác (PDF, v.v.) giữ nguyên
            String ext = (extension != null && !extension.isEmpty()) ? "." + extension : "";
            fileName = UUID.randomUUID().toString() + ext;
            targetLocation = targetFolder.resolve(fileName);
            Files.copy(file.getInputStream(), targetLocation, StandardCopyOption.REPLACE_EXISTING);
            log.debug("Non-image/video file saved: {}", fileName);
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

    private int getMaxSizeForSubFolder(String subFolder) {
        switch (subFolder.toLowerCase()) {
            case "avatars":
                return MAX_AVATAR_SIZE;
            case "posts":
                return MAX_POST_IMAGE_SIZE;
            case "comments":
                return MAX_COMMENT_IMAGE_SIZE;
            default:
                return MAX_POST_IMAGE_SIZE;
        }
    }

    private boolean isImageFile(String contentType, String extension) {
        if (contentType != null && IMAGE_MIME_TYPES.contains(contentType)) {
            return true;
        }
        if (extension != null) {
            String ext = extension.toLowerCase();
            return ext.matches("(jpg|jpeg|png|gif|bmp|webp)");
        }
        return false;
    }

    private boolean isVideoFile(String contentType, String extension) {
        if (contentType != null && VIDEO_MIME_TYPES.contains(contentType)) {
            return true;
        }
        if (extension != null) {
            String ext = extension.toLowerCase();
            return ext.matches("(mp4|mpeg|mov|avi|mkv|webm|ogg)");
        }
        return false;
    }

    private String getFileExtension(String filename) {
        if (filename == null || filename.lastIndexOf(".") == -1) {
            return "";
        }
        return filename.substring(filename.lastIndexOf(".") + 1);
    }

    public Path getFilePath(String filePath) {
        return this.fileStorageLocation.resolve(filePath).normalize();
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

    public void deleteFiles(List<String> filePaths) {
        for (String path : filePaths) {
            deleteFile(path);
        }
    }

    public List<String> storeFiles(List<MultipartFile> files, String subFolder) throws IOException {
        List<String> storedPaths = new java.util.ArrayList<>();
        for (MultipartFile file : files) {
            if (!file.isEmpty()) {
                String path = storeFile(file, subFolder);
                storedPaths.add(path);
            }
        }
        return storedPaths;
    }
}