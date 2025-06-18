package com.inspira.mediaprocessing.service;

import com.inspira.mediaprocessing.model.TaskRecord;
import com.inspira.mediaprocessing.repository.TaskRecordRepository;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.reactive.function.client.WebClient;

import java.io.IOException;

@Service
public class MediaProcessingService {
    private static final Logger logger = LoggerFactory.getLogger(MediaProcessingService.class);
    private final TaskRecordRepository repo;
    private final S3Client s3;
    private final ObjectMapper objectMapper = new ObjectMapper();
    @Value("${content.service.webhook:http://content-service:8081/content/webhook/processing-complete}")
    private String contentServiceWebhook;
    private final WebClient.Builder webClientBuilder = WebClient.builder();

    public MediaProcessingService(TaskRecordRepository repo, S3Client s3) {
        this.repo = repo;
        this.s3 = s3;
    }

    @RabbitListener(queues = "media.process")
    public void handleMessage(String message) {
        logger.info("Received message for processing: {}", message);
        String contentId = null;
        String s3Key = null;
        try {
            JsonNode node = objectMapper.readTree(message);
            contentId = node.get("contentId").asText();
            s3Key = node.get("objectName").asText();
        } catch (Exception e) {
            logger.error("Failed to parse message as JSON: {}", e.getMessage());
            return;
        }
        TaskRecord task = new TaskRecord();
        task.setContentId(contentId);
        task.setS3Key(s3Key);
        task.setStatus("processing");
        repo.save(task);
        try {
            byte[] data = s3.download(task.getS3Key());
            byte[] processed = processMedia(data);
            String outKey = "processed/" + task.getS3Key();
            s3.upload(outKey, processed);
            task.setStatus("completed");
            logger.info("Successfully processed media for contentId: {}", task.getContentId());
            // Send webhook to content service
            sendProcessingCompleteWebhook(task.getContentId(), outKey);
        } catch (IOException e) {
            logger.error("Failed to process media for contentId: " + task.getContentId(), e);
            task.setStatus("failed");
        } catch (Exception e) {
            logger.error("Unexpected error processing media for contentId: " + task.getContentId(), e);
            task.setStatus("failed");
        }
        repo.save(task);
    }

    private void sendProcessingCompleteWebhook(String contentId, String processedObjectName) {
        try {
            WebClient webClient = webClientBuilder.build();
            webClient.post()
                .uri(contentServiceWebhook)
                .bodyValue("contentId=" + contentId + "&processedObjectName=" + processedObjectName)
                .header("Content-Type", "application/x-www-form-urlencoded")
                .retrieve()
                .toBodilessEntity()
                .block();
            logger.info("Webhook sent to content service for contentId: {}", contentId);
        } catch (Exception e) {
            logger.error("Failed to send webhook to content service: {}", e.getMessage());
        }
    }

    private byte[] processMedia(byte[] data) {
        // TODO: Implement media processing logic (FFmpeg/ImageMagick)
        return data;
    }
} 