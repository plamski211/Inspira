package com.inspira.userservice.controller;

import com.inspira.userservice.dto.UserDataExportDto;
import com.inspira.userservice.service.GdprService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Controller for GDPR-related endpoints
 * Implements right to be forgotten and data portability requirements
 */
@RestController
@RequestMapping("/api/gdpr")
@RequiredArgsConstructor
public class GdprController {

    private final GdprService gdprService;
    
    /**
     * Endpoint for "Right to be Forgotten" GDPR requirement
     * Deletes or anonymizes all user data across all services
     * 
     * @param userId The ID of the user to be forgotten
     * @return ResponseEntity with success or failure status
     */
    @PostMapping("/forget/{userId}")
    public ResponseEntity<Map<String, String>> deleteUserData(@PathVariable String userId) {
        boolean success = gdprService.deleteUserData(userId);
        
        if (success) {
            return ResponseEntity.ok(Map.of(
                "message", "User data has been deleted or anonymized",
                "userId", userId,
                "status", "completed"
            ));
        } else {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                "message", "Failed to process right to be forgotten request",
                "userId", userId,
                "status", "failed"
            ));
        }
    }
    
    /**
     * Endpoint for "Data Portability" GDPR requirement
     * Collects all user data from all services and provides it in a portable format
     * 
     * @param userId The ID of the user requesting their data
     * @return ResponseEntity with user data in JSON format
     */
    @GetMapping(value = "/export/{userId}", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<UserDataExportDto> exportUserData(@PathVariable String userId) {
        UserDataExportDto exportData = gdprService.exportUserData(userId);
        return ResponseEntity.ok(exportData);
    }
    
    /**
     * Endpoint for updating user consent preferences
     * 
     * @param userId The ID of the user
     * @param consentPreferences Map of consent preferences
     * @return ResponseEntity with success or failure status
     */
    @PutMapping("/consent/{userId}")
    public ResponseEntity<Map<String, String>> updateConsentPreferences(
            @PathVariable String userId,
            @RequestBody Map<String, Boolean> consentPreferences) {
        
        boolean success = gdprService.updateConsentPreferences(userId, consentPreferences);
        
        if (success) {
            return ResponseEntity.ok(Map.of(
                "message", "Consent preferences updated successfully",
                "userId", userId,
                "status", "completed"
            ));
        } else {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                "message", "Failed to update consent preferences",
                "userId", userId,
                "status", "failed"
            ));
        }
    }
} 