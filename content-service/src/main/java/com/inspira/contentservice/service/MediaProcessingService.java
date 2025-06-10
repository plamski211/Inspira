package com.inspira.contentservice.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class MediaProcessingService {

    @Value("${media.service.url}")
    private String mediaServiceUrl;

    private final WebClient.Builder webClientBuilder;

    /**
     * Request media processing for an uploaded file
     * @param contentId ID of the content in the Content Service
     * @param objectName Object name in MinIO
     * @param contentType Content type of the file
     * @return Processing job ID
     */
    public String requestProcessing(Long contentId, String objectName, String contentType) {
        log.info("Requesting media processing for content ID: {}, object: {}", contentId, objectName);
        
        Map<String, String> request = new HashMap<>();
        request.put("contentId", contentId.toString());
        request.put("objectName", objectName);
        request.put("contentType", contentType);

        try {
            WebClient webClient = webClientBuilder.baseUrl(mediaServiceUrl).build();
            return webClient.post()
                .uri("/api/media/process")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(request)
                .retrieve()
                .bodyToMono(String.class)
                .block();
        } catch (Exception e) {
            log.error("Error requesting media processing: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to request media processing: " + e.getMessage(), e);
        }
    }

    /**
     * Check status of media processing
     * @param jobId Processing job ID
     * @return Status of the processing job
     */
    public String checkProcessingStatus(String jobId) {
        log.info("Checking processing status for job: {}", jobId);
        
        try {
            WebClient webClient = webClientBuilder.baseUrl(mediaServiceUrl).build();
            return webClient.get()
                .uri("/api/media/status/{jobId}", jobId)
                .retrieve()
                .bodyToMono(String.class)
                .block();
        } catch (Exception e) {
            log.error("Error checking processing status: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to check processing status: " + e.getMessage(), e);
        }
    }
} 