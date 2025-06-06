package com.inspira.userservice.dto;

import java.time.Instant;

public class UserProfileResponse {
    private Long id;
    private String auth0Id;
    private String displayName;
    private String bio;
    private String avatarUrl;
    private String location;
    private Instant createdAt;

    public static UserProfileResponse fromEntity(com.inspira.userservice.model.UserProfile entity) {
        UserProfileResponse dto = new UserProfileResponse();
        dto.setId(entity.getId());
        dto.setAuth0Id(entity.getAuth0Id());
        dto.setDisplayName(entity.getDisplayName());
        dto.setBio(entity.getBio());
        dto.setAvatarUrl(entity.getAvatarUrl());
        dto.setLocation(entity.getLocation());
        dto.setCreatedAt(entity.getCreatedAt());
        return dto;
    }

    public Long getId() {
        return id;
    }
    private void setId(Long id) {
        this.id = id;
    }

    public String getAuth0Id() {
        return auth0Id;
    }
    private void setAuth0Id(String auth0Id) {
        this.auth0Id = auth0Id;
    }

    public String getDisplayName() {
        return displayName;
    }
    private void setDisplayName(String displayName) {
        this.displayName = displayName;
    }

    public String getBio() {
        return bio;
    }
    private void setBio(String bio) {
        this.bio = bio;
    }

    public String getAvatarUrl() {
        return avatarUrl;
    }
    private void setAvatarUrl(String avatarUrl) {
        this.avatarUrl = avatarUrl;
    }

    public String getLocation() {
        return location;
    }
    private void setLocation(String location) {
        this.location = location;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
    private void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }
}
