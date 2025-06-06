package com.inspira.mediaprocessing.service;

import com.inspira.mediaprocessing.model.TaskRecord;
import com.inspira.mediaprocessing.repository.TaskRecordRepository;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;

@Service
public class MediaProcessingService {
    private static final Logger logger = LoggerFactory.getLogger(MediaProcessingService.class);
    private final TaskRecordRepository repo;
    private final S3Client s3;

    public MediaProcessingService(TaskRecordRepository repo, S3Client s3) {
        this.repo = repo;
        this.s3 = s3;
    }

    @RabbitListener(queues = "media.process")
    public void handleMessage(String message) {
        logger.info("Received message for processing: {}", message);
        
        TaskRecord task = new TaskRecord();
        task.setContentId(parseContentId(message));
        task.setS3Key(parseS3Key(message));
        task.setStatus("processing");
        repo.save(task);

        try {
            byte[] data = s3.download(task.getS3Key());
            byte[] processed = processMedia(data);
            String outKey = "processed/" + task.getS3Key();
            s3.upload(outKey, processed);
            task.setStatus("completed");
            logger.info("Successfully processed media for contentId: {}", task.getContentId());
        } catch (IOException e) {
            logger.error("Failed to process media for contentId: " + task.getContentId(), e);
            task.setStatus("failed");
        } catch (Exception e) {
            logger.error("Unexpected error processing media for contentId: " + task.getContentId(), e);
            task.setStatus("failed");
        }
        
        repo.save(task);
    }

    private String parseContentId(String msg) {
        // TODO: Implement proper parsing logic
        return msg.split(",")[0];
    }

    private String parseS3Key(String msg) {
        // TODO: Implement proper parsing logic
        return msg.split(",")[1];
    }

    private byte[] processMedia(byte[] data) {
        // TODO: Implement media processing logic (FFmpeg/ImageMagick)
        return data;
    }
} 