package com.inspira.contentservice.controller;

import com.inspira.contentservice.model.Content;
import com.inspira.contentservice.service.ContentService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/content")
@RequiredArgsConstructor
public class ContentController {

    private final ContentService contentService;

    /**
     * Upload content
     */
    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Content> uploadContent(
            @RequestParam("file") MultipartFile file,
            @RequestParam("title") String title,
            @RequestParam(value = "description", required = false) String description,
            @AuthenticationPrincipal Jwt principal) {
        
        String userId = principal.getSubject();
        log.info("Received upload request from user: {}", userId);
        
        Content uploadedContent = contentService.uploadContent(file, title, description, userId);
        return ResponseEntity.status(HttpStatus.CREATED).body(uploadedContent);
    }

    /**
     * Get all content for the authenticated user
     */
    @GetMapping("/my-content")
    public ResponseEntity<List<Content>> getMyContent(@AuthenticationPrincipal Jwt principal) {
        String userId = principal.getSubject();
        log.info("Fetching content for user: {}", userId);
        
        List<Content> content = contentService.getContentByUser(userId);
        return ResponseEntity.ok(content);
    }

    /**
     * Get all content (admin only)
     */
    @GetMapping
    public ResponseEntity<List<Content>> getAllContent() {
        log.info("Fetching all content");
        
        List<Content> content = contentService.getAllContent();
        return ResponseEntity.ok(content);
    }

    /**
     * Get content by ID
     */
    @GetMapping("/{id}")
    public ResponseEntity<Content> getContentById(@PathVariable Long id) {
        log.info("Fetching content with ID: {}", id);
        
        return contentService.getContentById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * Get URL to access content
     */
    @GetMapping("/{id}/url")
    public ResponseEntity<Map<String, String>> getContentUrl(
            @PathVariable Long id,
            @RequestParam(value = "useProcessed", defaultValue = "true") boolean useProcessed) {
        
        log.info("Generating URL for content ID: {}, useProcessed: {}", id, useProcessed);
        
        String url = contentService.getContentUrl(id, useProcessed);
        Map<String, String> response = new HashMap<>();
        response.put("url", url);
        
        return ResponseEntity.ok(response);
    }

    /**
     * Update content metadata
     */
    @PutMapping("/{id}")
    public ResponseEntity<Content> updateContent(
            @PathVariable Long id,
            @RequestParam("title") String title,
            @RequestParam(value = "description", required = false) String description,
            @AuthenticationPrincipal Jwt principal) {
        
        log.info("Updating content with ID: {}", id);
        
        Content updatedContent = contentService.updateContent(id, title, description);
        return ResponseEntity.ok(updatedContent);
    }

    /**
     * Delete content
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteContent(@PathVariable Long id) {
        log.info("Deleting content with ID: {}", id);
        
        contentService.deleteContent(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * Webhook for media processing service to update content
     * This is called by the media service when processing is complete
     */
    @PostMapping("/webhook/processing-complete")
    public ResponseEntity<Void> processingComplete(
            @RequestParam("contentId") Long contentId,
            @RequestParam("processedObjectName") String processedObjectName) {
        
        log.info("Processing complete webhook received for content ID: {}", contentId);
        
        contentService.updateProcessedContent(contentId, processedObjectName);
        return ResponseEntity.ok().build();
    }
} 