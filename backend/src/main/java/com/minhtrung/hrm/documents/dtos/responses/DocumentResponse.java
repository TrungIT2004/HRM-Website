package com.minhtrung.hrm.documents.dtos.responses;

import java.time.LocalDateTime;
import java.util.UUID;

import com.minhtrung.hrm.documents.entities.Document;
import com.minhtrung.hrm.documents.enums.DocumentCategory;
import com.minhtrung.hrm.documents.enums.DocumentFileType;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DocumentResponse {
    private UUID documentId;
    private DocumentCategory category;
    private String categoryLabel;
    private String documentName;
    private String documentTitle;
    private String fileUrl;
    private DocumentFileType fileType;
    private Long fileSize;
    private String summary;
    private UUID uploaderId;
    private String uploaderName;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static DocumentResponse from(Document d) {
        return DocumentResponse.builder()
                .documentId(d.getDocumentId())
                .category(d.getCategory())
                .categoryLabel(d.getCategory() != null ? d.getCategory().getLabel() : null)
                .documentName(d.getDocumentName())
                .documentTitle(d.getDocumentTitle())
                .fileUrl(d.getFileUrl())
                .fileType(d.getFileType())
                .fileSize(d.getFileSize())
                .summary(d.getSummary())
                .uploaderId(d.getUploaderId())
                .uploaderName(d.getUploaderName())
                .createdAt(d.getCreatedAt())
                .updatedAt(d.getUpdatedAt())
                .build();
    }
}
