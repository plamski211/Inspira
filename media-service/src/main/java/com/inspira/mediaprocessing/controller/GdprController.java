package com.inspira.mediaprocessing.controller;

import com.inspira.mediaprocessing.service.AzureBlobStorageService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * Controller for GDPR-related operations in the media service
 */
@RestController
@RequestMapping("/api/gdpr")
@RequiredArgsConstructor
@Slf4j
public class GdprController {

    private final AzureBlobStorageService azureBlobStorageService;
    
    /**
     * Delete all media files for a user (GDPR right to be forgotten)
     * 
     * @param userId The ID of the user whose files should be deleted
     * @return Response with deletion status
     */
    @PostMapping("/delete-media/{userId}")
    public ResponseEntity<Map<String, Object>> deleteUserMedia(@PathVariable String userId) {
        log.info("Received request to delete media for user: {}", userId);
        
        try {
            int deletedCount = azureBlobStorageService.deleteUserMedia(userId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("userId", userId);
            response.put("deletedCount", deletedCount);
            response.put("status", "success");
            response.put("message", "Successfully deleted all media files for user");
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Failed to delete media for user: {}", userId, e);
            
            Map<String, Object> response = new HashMap<>();
            response.put("userId", userId);
            response.put("status", "error");
            response.put("message", "Failed to delete media files: " + e.getMessage());
            
            return ResponseEntity.internalServerError().body(response);
        }
    }
    
    /**
     * Export all media metadata for a user (GDPR data portability)
     * 
     * @param userId The ID of the user whose data should be exported
     * @return Response with user's media metadata
     */
    @GetMapping("/export-media/{userId}")
    public ResponseEntity<Map<String, Object>> exportUserMediaData(@PathVariable String userId) {
        log.info("Received request to export media data for user: {}", userId);
        
        try {
            Map<String, Object> mediaData = azureBlobStorageService.exportUserMediaData(userId);
            return ResponseEntity.ok(mediaData);
        } catch (Exception e) {
            log.error("Failed to export media data for user: {}", userId, e);
            
            Map<String, Object> response = new HashMap<>();
            response.put("userId", userId);
            response.put("status", "error");
            response.put("message", "Failed to export media data: " + e.getMessage());
            
            return ResponseEntity.internalServerError().body(response);
        }
    }
} 