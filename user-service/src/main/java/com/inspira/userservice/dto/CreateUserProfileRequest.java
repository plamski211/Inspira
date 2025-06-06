package com.inspira.userservice.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class CreateUserProfileRequest {

    @NotBlank(message = "Auth0 ID is required")
    private String auth0Id;

    @NotBlank(message = "Display name is required")
    @Size(max = 50, message = "Display name must be at most 50 characters")
    private String displayName;

    @Size(max = 200, message = "Bio must be at most 200 characters")
    private String bio;

    @Size(max = 255, message = "Avatar URL must be at most 255 characters")
    private String avatarUrl;

    @Size(max = 100, message = "Location must be at most 100 characters")
    private String location;

    public String getAuth0Id() {
        return auth0Id;
    }
    public void setAuth0Id(String auth0Id) {
        this.auth0Id = auth0Id;
    }

    public String getDisplayName() {
        return displayName;
    }
    public void setDisplayName(String displayName) {
        this.displayName = displayName;
    }

    public String getBio() {
        return bio;
    }
    public void setBio(String bio) {
        this.bio = bio;
    }

    public String getAvatarUrl() {
        return avatarUrl;
    }
    public void setAvatarUrl(String avatarUrl) {
        this.avatarUrl = avatarUrl;
    }

    public String getLocation() {
        return location;
    }
    public void setLocation(String location) {
        this.location = location;
    }
}
