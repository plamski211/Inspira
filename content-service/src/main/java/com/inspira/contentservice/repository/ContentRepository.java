package com.inspira.contentservice.repository;

import com.inspira.contentservice.model.Content;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ContentRepository extends JpaRepository<Content, Long> {
    List<Content> findByUploadedBy(String uploadedBy);
    List<Content> findByIsProcessed(Boolean isProcessed);
} 