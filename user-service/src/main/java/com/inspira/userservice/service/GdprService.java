package com.inspira.userservice.service;

import com.inspira.userservice.dto.UserDataExportDto;
import com.inspira.userservice.model.User;
import com.inspira.userservice.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Service responsible for GDPR-related operations
 * Implements right to be forgotten and data portability requirements
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class GdprService {

    private final UserRepository userRepository;
    private final RestTemplate restTemplate;
    
    @Value("${services.content-service.url}")
    private String contentServiceUrl;
    
    @Value("${services.media-service.url}")
    private String mediaServiceUrl;
    
    /**
     * Implements the "Right to be Forgotten" GDPR requirement
     * Deletes or anonymizes all user data across all services
     * 
     * @param userId The ID of the user to be forgotten
     * @return True if the operation was successful
     */
    @Transactional
    public boolean deleteUserData(String userId) {
        log.info("Processing right to be forgotten request for user: {}", userId);
        
        try {
            // 1. Delete user data from user service
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));
            
            // 2. Anonymize user before deletion to maintain referential integrity if needed
            user.setEmail("anonymized_" + UUID.randomUUID() + "@deleted.user");
            user.setFirstName("Anonymized");
            user.setLastName("User");
            user.setProfilePicture(null);
            user.setPhoneNumber(null);
            user.setDeleted(true);
            user.setDeletionDate(LocalDateTime.now());
            userRepository.save(user);
            
            // 3. Request content service to anonymize user content
            HttpHeaders headers = new HttpHeaders();
            headers.set("Authorization", "Bearer internal-service-token");
            HttpEntity<String> entity = new HttpEntity<>(headers);
            
            restTemplate.exchange(
                    contentServiceUrl + "/api/gdpr/anonymize/" + userId,
                    HttpMethod.POST,
                    entity,
                    Void.class
            );
            
            // 4. Request media service to delete user media
            restTemplate.exchange(
                    mediaServiceUrl + "/api/gdpr/delete-media/" + userId,
                    HttpMethod.POST,
                    entity,
                    Void.class
            );
            
            log.info("Successfully processed right to be forgotten for user: {}", userId);
            return true;
        } catch (Exception e) {
            log.error("Failed to process right to be forgotten for user: {}", userId, e);
            throw new RuntimeException("Failed to delete user data", e);
        }
    }
    
    /**
     * Implements the "Data Portability" GDPR requirement
     * Collects all user data from all services and provides it in a portable format
     * 
     * @param userId The ID of the user requesting their data
     * @return DTO containing all user data
     */
    @Transactional(readOnly = true)
    public UserDataExportDto exportUserData(String userId) {
        log.info("Processing data portability request for user: {}", userId);
        
        try {
            // 1. Fetch user data from user service
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));
            
            // 2. Create export DTO
            UserDataExportDto exportDto = new UserDataExportDto();
            exportDto.setUserId(userId);
            exportDto.setEmail(user.getEmail());
            exportDto.setFirstName(user.getFirstName());
            exportDto.setLastName(user.getLastName());
            exportDto.setCreatedAt(user.getCreatedAt());
            
            // 3. Fetch content data from content service
            HttpHeaders headers = new HttpHeaders();
            headers.set("Authorization", "Bearer internal-service-token");
            HttpEntity<String> entity = new HttpEntity<>(headers);
            
            Map<String, Object> contentData = restTemplate.exchange(
                    contentServiceUrl + "/api/gdpr/export/" + userId,
                    HttpMethod.GET,
                    entity,
                    Map.class
            ).getBody();
            
            // 4. Fetch media data from media service
            Map<String, Object> mediaData = restTemplate.exchange(
                    mediaServiceUrl + "/api/gdpr/export-media/" + userId,
                    HttpMethod.GET,
                    entity,
                    Map.class
            ).getBody();
            
            // 5. Combine all data
            Map<String, Object> allUserData = new HashMap<>();
            allUserData.put("profile", user);
            allUserData.put("content", contentData);
            allUserData.put("media", mediaData);
            
            exportDto.setData(allUserData);
            
            log.info("Successfully processed data portability request for user: {}", userId);
            return exportDto;
        } catch (Exception e) {
            log.error("Failed to process data portability request for user: {}", userId, e);
            throw new RuntimeException("Failed to export user data", e);
        }
    }
    
    /**
     * Updates user consent preferences
     * 
     * @param userId The ID of the user
     * @param consentPreferences Map of consent preferences
     * @return True if the operation was successful
     */
    @Transactional
    public boolean updateConsentPreferences(String userId, Map<String, Boolean> consentPreferences) {
        log.info("Updating consent preferences for user: {}", userId);
        
        try {
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));
            
            // Update user consent preferences
            user.setMarketingConsent(consentPreferences.getOrDefault("marketing", false));
            user.setDataSharingConsent(consentPreferences.getOrDefault("dataSharing", false));
            user.setCookieConsent(consentPreferences.getOrDefault("cookies", false));
            user.setConsentUpdatedAt(LocalDateTime.now());
            
            userRepository.save(user);
            
            log.info("Successfully updated consent preferences for user: {}", userId);
            return true;
        } catch (Exception e) {
            log.error("Failed to update consent preferences for user: {}", userId, e);
            throw new RuntimeException("Failed to update consent preferences", e);
        }
    }
} 