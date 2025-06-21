package com.inspira.userservice.dto;

import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * DTO for exporting user data in compliance with GDPR data portability requirements
 */
@Data
@NoArgsConstructor
public class UserDataExportDto {
    
    private String userId;
    private String email;
    private String firstName;
    private String lastName;
    private LocalDateTime createdAt;
    private LocalDateTime exportedAt = LocalDateTime.now();
    private Map<String, Object> data;
} 