package com.inspira.contentservice.service;

import io.minio.*;
import io.minio.http.Method;
import io.minio.messages.Item;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

@Slf4j
@Service
@RequiredArgsConstructor
public class FileStorageService {

    private final MinioClient minioClient;

    @Value("${minio.bucketName}")
    private String bucketName;

    /**
     * Upload a file to MinIO storage
     * @param file The file to upload
     * @param contentType The content type of the file
     * @return The object name (file identifier)
     */
    public String uploadFile(MultipartFile file, String contentType) {
        try {
            String objectName = generateObjectName(file.getOriginalFilename());
            log.info("Uploading file: {} as object: {}", file.getOriginalFilename(), objectName);
            
            // Upload the file to MinIO
            minioClient.putObject(
                PutObjectArgs.builder()
                    .bucket(bucketName)
                    .object(objectName)
                    .stream(file.getInputStream(), file.getSize(), -1)
                    .contentType(contentType)
                    .build()
            );
            
            log.info("File uploaded successfully: {}", objectName);
            return objectName;
        } catch (Exception e) {
            log.error("Failed to upload file: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to upload file: " + e.getMessage(), e);
        }
    }

    /**
     * Get a temporary URL to access the file
     * @param objectName The object name in MinIO
     * @param expiryDuration Expiry duration in seconds
     * @return The presigned URL
     */
    public String getFileUrl(String objectName, int expiryDuration) {
        try {
            log.info("Generating presigned URL for object: {}", objectName);
            return minioClient.getPresignedObjectUrl(
                GetPresignedObjectUrlArgs.builder()
                    .bucket(bucketName)
                    .object(objectName)
                    .method(Method.GET)
                    .expiry(expiryDuration, TimeUnit.SECONDS)
                    .build()
            );
        } catch (Exception e) {
            log.error("Failed to generate URL for file: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to generate URL for file: " + e.getMessage(), e);
        }
    }

    /**
     * Delete a file from MinIO
     * @param objectName The object name in MinIO
     */
    public void deleteFile(String objectName) {
        try {
            log.info("Deleting file: {}", objectName);
            minioClient.removeObject(
                RemoveObjectArgs.builder()
                    .bucket(bucketName)
                    .object(objectName)
                    .build()
            );
            log.info("File deleted successfully: {}", objectName);
        } catch (Exception e) {
            log.error("Failed to delete file: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to delete file: " + e.getMessage(), e);
        }
    }

    /**
     * List all files in the bucket
     * @return List of object names
     */
    public List<String> listFiles() {
        try {
            log.info("Listing all files in bucket: {}", bucketName);
            List<String> files = new ArrayList<>();
            Iterable<Result<Item>> results = minioClient.listObjects(
                ListObjectsArgs.builder().bucket(bucketName).build()
            );
            
            for (Result<Item> result : results) {
                Item item = result.get();
                files.add(item.objectName());
            }
            
            return files;
        } catch (Exception e) {
            log.error("Failed to list files: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to list files: " + e.getMessage(), e);
        }
    }

    /**
     * Generate a unique object name to prevent overwriting files
     * @param originalFilename The original filename
     * @return A unique object name
     */
    private String generateObjectName(String originalFilename) {
        String extension = "";
        if (originalFilename.contains(".")) {
            extension = originalFilename.substring(originalFilename.lastIndexOf("."));
        }
        return UUID.randomUUID().toString() + extension;
    }
} 