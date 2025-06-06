package com.inspira.userservice.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.time.Instant;

@Entity
@Table(name = "user_profiles")
public class UserProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "auth0_id", nullable = false, unique = true)
    private String auth0Id;

    @NotBlank
    @Size(max = 50)
    @Column(name = "display_name", nullable = false)
    private String displayName;

    @Size(max = 200)
    @Column(nullable = true)
    private String bio;

    @Size(max = 255)
    @Column(name = "avatar_url", nullable = true)
    private String avatarUrl;

    @Size(max = 100)
    @Column(nullable = true)
    private String location;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    public UserProfile() {}

    public UserProfile(String auth0Id, String displayName, String bio, String avatarUrl, String location) {
        this.auth0Id = auth0Id;
        this.displayName = displayName;
        this.bio = bio;
        this.avatarUrl = avatarUrl;
        this.location = location;
        this.createdAt = Instant.now();
    }

    public Long getId() {
        return id;
    }

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

    public Instant getCreatedAt() {
        return createdAt;
    }

        @Override
    public String toString() {
        return "UserProfile{" +
               "id=" + id +
               ", auth0Id='" + auth0Id + '\'' +
               ", displayName='" + displayName + '\'' +
               ", bio='" + bio + '\'' +
               ", avatarUrl='" + avatarUrl + '\'' +
               ", location='" + location + '\'' +
               ", createdAt=" + createdAt +
               '}';
    }
}
