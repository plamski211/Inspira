package com.inspira.userservice.model;

import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.*;
import java.time.LocalDateTime;

/**
 * User entity with GDPR-compliant fields for consent management and data deletion
 */
@Entity
@Table(name = "users")
@Data
@NoArgsConstructor
public class User {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private String id;
    
    @Column(nullable = false, unique = true)
    private String email;
    
    @Column(name = "first_name")
    private String firstName;
    
    @Column(name = "last_name")
    private String lastName;
    
    @Column(name = "profile_picture")
    private String profilePicture;
    
    @Column(name = "phone_number")
    private String phoneNumber;
    
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();
    
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    // GDPR-related fields
    
    @Column(name = "marketing_consent")
    private Boolean marketingConsent = false;
    
    @Column(name = "data_sharing_consent")
    private Boolean dataSharingConsent = false;
    
    @Column(name = "cookie_consent")
    private Boolean cookieConsent = false;
    
    @Column(name = "consent_updated_at")
    private LocalDateTime consentUpdatedAt;
    
    @Column(name = "deleted")
    private Boolean deleted = false;
    
    @Column(name = "deletion_date")
    private LocalDateTime deletionDate;
    
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
} 