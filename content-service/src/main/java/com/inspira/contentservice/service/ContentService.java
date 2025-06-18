package com.inspira.contentservice.service;

import com.inspira.contentservice.model.Content;
import com.inspira.contentservice.repository.ContentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class ContentService {
    private final ContentRepository contentRepository;
    private final FileStorageService fileStorageService;
    private final MediaProcessingService mediaProcessingService;

    @Transactional
    public Content uploadContent(MultipartFile file, String title, String description, String userId) {
        // Upload file to MinIO
        String objectName = fileStorageService.uploadFile(file, file.getContentType());
        Content content = Content.builder()
                .title(title)
                .description(description)
                .objectName(objectName)
                .originalFileName(file.getOriginalFilename())
                .contentType(file.getContentType())
                .fileSize(file.getSize())
                .uploadedBy(userId)
                .isProcessed(false)
                .createdAt(Instant.now())
                .build();
        Content saved = contentRepository.save(content);
        // Optionally trigger media processing
        try {
            mediaProcessingService.requestProcessing(saved.getId(), objectName, file.getContentType());
        } catch (Exception e) {
            log.warn("Failed to trigger media processing: {}", e.getMessage());
        }
        return saved;
    }

    @Transactional(readOnly = true)
    public List<Content> getContentByUser(String userId) {
        return contentRepository.findByUploadedBy(userId);
    }

    @Transactional(readOnly = true)
    public List<Content> getAllContent() {
        return contentRepository.findAll();
    }

    @Transactional(readOnly = true)
    public Optional<Content> getContentById(Long id) {
        return contentRepository.findById(id);
    }

    @Transactional(readOnly = true)
    public String getContentUrl(Long id, boolean useProcessed) {
        Content content = contentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Content not found"));
        String objectName = (useProcessed && content.getIsProcessed() != null && content.getIsProcessed() && content.getProcessedObjectName() != null)
                ? content.getProcessedObjectName() : content.getObjectName();
        return fileStorageService.getFileUrl(objectName, 3600); // 1 hour expiry
    }

    @Transactional
    public Content updateContent(Long id, String title, String description) {
        Content content = contentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Content not found"));
        content.setTitle(title);
        content.setDescription(description);
        content.setUpdatedAt(Instant.now());
        return contentRepository.save(content);
    }

    @Transactional
    public void deleteContent(Long id) {
        Content content = contentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Content not found"));
        // Optionally delete file from MinIO
        try {
            fileStorageService.deleteFile(content.getObjectName());
            if (content.getProcessedObjectName() != null) {
                fileStorageService.deleteFile(content.getProcessedObjectName());
            }
        } catch (Exception e) {
            log.warn("Failed to delete file(s) from storage: {}", e.getMessage());
        }
        contentRepository.deleteById(id);
    }

    @Transactional
    public void updateProcessedContent(Long contentId, String processedObjectName) {
        Content content = contentRepository.findById(contentId)
                .orElseThrow(() -> new RuntimeException("Content not found"));
        content.setProcessedObjectName(processedObjectName);
        content.setIsProcessed(true);
        content.setUpdatedAt(Instant.now());
        contentRepository.save(content);
    }
} 