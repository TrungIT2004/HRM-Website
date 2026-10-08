package com.minhtrung.hrm.documents.repositories;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.minhtrung.hrm.documents.entities.Document;
import com.minhtrung.hrm.documents.enums.DocumentCategory;

public interface DocumentRepository extends JpaRepository<Document, UUID> {
    List<Document> findByIsActiveTrueOrderByCreatedAtDesc();

    List<Document> findByIsActiveTrueAndCategoryOrderByCreatedAtDesc(DocumentCategory category);

    Optional<Document> findByDocumentIdAndIsActiveTrue(UUID documentId);
}
