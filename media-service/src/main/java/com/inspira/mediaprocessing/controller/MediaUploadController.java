package com.inspira.mediaprocessing.controller;

import com.inspira.mediaprocessing.dto.MediaUploadResponse;
import com.inspira.mediaprocessing.service.S3Client;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/media")
public class MediaUploadController {
    private final S3Client s3Client;

    public MediaUploadController(S3Client s3Client) {
        this.s3Client = s3Client;
    }

    @PostMapping("/upload")
    public ResponseEntity<MediaUploadResponse> upload(@RequestParam("file") MultipartFile file) throws IOException {
        String key = UUID.randomUUID() + "-" + file.getOriginalFilename();
        s3Client.upload(key, file.getBytes());
        MediaUploadResponse resp = new MediaUploadResponse(key);
        return ResponseEntity.ok(resp);
    }
}
