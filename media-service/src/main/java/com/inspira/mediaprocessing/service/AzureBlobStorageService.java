package com.inspira.mediaprocessing.service;

import com.azure.storage.blob.BlobClient;
import com.azure.storage.blob.BlobContainerClient;
import com.azure.storage.blob.BlobServiceClient;
import com.azure.storage.blob.BlobServiceClientBuilder;
import com.azure.storage.blob.models.BlobHttpHeaders;
import com.azure.storage.blob.models.BlobStorageException;
import com.azure.storage.blob.sas.BlobSasPermission;
import com.azure.storage.blob.sas.BlobServiceSasSignatureValues;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import javax.annotation.PostConstruct;
import java.io.IOException;
import java.io.InputStream;
import java.time.OffsetDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Service for handling media files using Azure Blob Storage
 * Implements geo-replication and GDPR compliance features
 */
@Service
@Slf4j
public class AzureBlobStorageService {

    @Value("${azure.storage.connection-string}")
    private String connectionString;
    
    @Value("${azure.storage.container-name}")
    private String containerName;
    
    @Value("${azure.storage.cdn-endpoint:#{null}}")
    private String cdnEndpoint;
    
    private BlobServiceClient blobServiceClient;
    private BlobContainerClient containerClient;
    
    @PostConstruct
    public void initialize() {
        log.info("Initializing Azure Blob Storage with container: {}", containerName);
        
        try {
            blobServiceClient = new BlobServiceClientBuilder()
                    .connectionString(connectionString)
                    .buildClient();
            
            // Get or create container
            containerClient = blobServiceClient.getBlobContainerClient(containerName);
            if (!containerClient.exists()) {
                log.info("Creating container: {}", containerName);
                containerClient.create();
            }
        } catch (Exception e) {
            log.error("Failed to initialize Azure Blob Storage", e);
            throw new RuntimeException("Failed to initialize Azure Blob Storage", e);
        }
    }
    
    /**
     * Upload media file to Azure Blob Storage with geo-replication
     * 
     * @param file The file to upload
     * @param userId The ID of the user who owns the file
     * @return Map containing file information
     */
    public Map<String, String> uploadMedia(MultipartFile file, String userId) {
        String originalFilename = file.getOriginalFilename();
        String fileExtension = originalFilename != null ? 
                originalFilename.substring(originalFilename.lastIndexOf(".")) : "";
        String blobName = userId + "/" + UUID.randomUUID() + fileExtension;
        
        BlobClient blobClient = containerClient.getBlobClient(blobName);
        
        try (InputStream dataStream = file.getInputStream()) {
            // Set content type
            BlobHttpHeaders headers = new BlobHttpHeaders()
                    .setContentType(file.getContentType());
            
            // Set metadata for GDPR compliance
            Map<String, String> metadata = new HashMap<>();
            metadata.put("userId", userId);
            metadata.put("uploadTime", OffsetDateTime.now().toString());
            metadata.put("originalFilename", originalFilename);
            
            // Upload with metadata and headers
            blobClient.upload(dataStream, file.getSize(), true);
            blobClient.setHttpHeaders(headers);
            blobClient.setMetadata(metadata);
            
            // Generate URLs
            String directUrl = blobClient.getBlobUrl();
            String cdnUrl = cdnEndpoint != null ? 
                    cdnEndpoint + "/" + containerName + "/" + blobName : null;
            
            // Generate SAS token for temporary access
            BlobSasPermission sasPermission = new BlobSasPermission()
                    .setReadPermission(true);
            
            BlobServiceSasSignatureValues sasValues = new BlobServiceSasSignatureValues(
                    OffsetDateTime.now().plusHours(24), sasPermission);
            
            String sasToken = blobClient.generateSas(sasValues);
            String secureUrl = directUrl + "?" + sasToken;
            
            // Return file information
            Map<String, String> fileInfo = new HashMap<>();
            fileInfo.put("blobName", blobName);
            fileInfo.put("directUrl", directUrl);
            fileInfo.put("secureUrl", secureUrl);
            if (cdnUrl != null) {
                fileInfo.put("cdnUrl", cdnUrl);
            }
            fileInfo.put("contentType", file.getContentType());
            fileInfo.put("size", String.valueOf(file.getSize()));
            
            log.info("Successfully uploaded file to Azure Blob Storage: {}", blobName);
            return fileInfo;
        } catch (IOException e) {
            log.error("Failed to read file for upload", e);
            throw new RuntimeException("Failed to read file for upload", e);
        } catch (BlobStorageException e) {
            log.error("Azure Blob Storage error", e);
            throw new RuntimeException("Azure Blob Storage error", e);
        }
    }
    
    /**
     * Delete all media files for a user (GDPR right to be forgotten)
     * 
     * @param userId The ID of the user whose files should be deleted
     * @return Number of files deleted
     */
    public int deleteUserMedia(String userId) {
        log.info("Deleting all media files for user: {}", userId);
        
        int deletedCount = 0;
        
        try {
            // List all blobs in the user's directory
            containerClient.listBlobs().forEach(blobItem -> {
                if (blobItem.getName().startsWith(userId + "/")) {
                    BlobClient blobClient = containerClient.getBlobClient(blobItem.getName());
                    blobClient.delete();
                    deletedCount++;
                }
            });
            
            log.info("Deleted {} media files for user: {}", deletedCount, userId);
            return deletedCount;
        } catch (BlobStorageException e) {
            log.error("Failed to delete user media files", e);
            throw new RuntimeException("Failed to delete user media files", e);
        }
    }
    
    /**
     * Export all media metadata for a user (GDPR data portability)
     * 
     * @param userId The ID of the user whose data should be exported
     * @return Map containing media metadata
     */
    public Map<String, Object> exportUserMediaData(String userId) {
        log.info("Exporting media data for user: {}", userId);
        
        Map<String, Object> mediaData = new HashMap<>();
        mediaData.put("userId", userId);
        
        try {
            // List all blobs in the user's directory
            containerClient.listBlobs().forEach(blobItem -> {
                if (blobItem.getName().startsWith(userId + "/")) {
                    BlobClient blobClient = containerClient.getBlobClient(blobItem.getName());
                    
                    Map<String, String> fileInfo = new HashMap<>();
                    fileInfo.put("blobName", blobItem.getName());
                    fileInfo.put("url", blobClient.getBlobUrl());
                    fileInfo.put("contentType", blobItem.getProperties().getContentType());
                    fileInfo.put("size", String.valueOf(blobItem.getProperties().getContentLength()));
                    fileInfo.put("createdAt", blobItem.getProperties().getCreationTime().toString());
                    
                    // Add metadata
                    Map<String, String> metadata = blobClient.getProperties().getMetadata();
                    if (metadata != null) {
                        fileInfo.putAll(metadata);
                    }
                    
                    mediaData.put(blobItem.getName(), fileInfo);
                }
            });
            
            log.info("Successfully exported media data for user: {}", userId);
            return mediaData;
        } catch (BlobStorageException e) {
            log.error("Failed to export user media data", e);
            throw new RuntimeException("Failed to export user media data", e);
        }
    }
} 