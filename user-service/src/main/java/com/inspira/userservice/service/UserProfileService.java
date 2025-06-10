package com.inspira.userservice.service;

import com.inspira.userservice.dto.CreateUserProfileRequest;
import com.inspira.userservice.dto.UpdateUserProfileRequest;
import com.inspira.userservice.exception.ResourceNotFoundException;
import com.inspira.userservice.model.UserProfile;
import com.inspira.userservice.repository.UserProfileRepository;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class UserProfileService {

    private final UserProfileRepository repository;

    public UserProfileService(UserProfileRepository repository) {
        this.repository = repository;
    }

    @Transactional
    public UserProfile create(CreateUserProfileRequest dto) {
        // Check if profile exists
        return repository.findByAuth0Id(dto.getAuth0Id()).map(existingProfile -> {
            // Update existing profile
            existingProfile.setDisplayName(dto.getDisplayName());
            existingProfile.setBio(dto.getBio());
            existingProfile.setAvatarUrl(dto.getAvatarUrl());
            existingProfile.setLocation(dto.getLocation());
            return repository.save(existingProfile);
        }).orElseGet(() -> {
            // Create new profile
            UserProfile profile = new UserProfile(
                    dto.getAuth0Id(),
                    dto.getDisplayName(),
                    dto.getBio(),
                    dto.getAvatarUrl(),
                    dto.getLocation()
            );
            return repository.save(profile);
        });
    }

    @Transactional(readOnly = true)
    public UserProfile getByAuth0Id(String auth0Id) {
        return repository.findByAuth0Id(auth0Id)
                .orElseThrow(() -> new ResourceNotFoundException("UserProfile", "auth0Id", auth0Id));
    }

    @Transactional(readOnly = true)
    public List<UserProfile> getAll() {
        return repository.findAll();
    }

    @Transactional
    public UserProfile update(String auth0Id, UpdateUserProfileRequest dto) {
        UserProfile existing = repository.findByAuth0Id(auth0Id)
                .orElseThrow(() -> new ResourceNotFoundException("UserProfile", "auth0Id", auth0Id));
        existing.setDisplayName(dto.getDisplayName());
        existing.setBio(dto.getBio());
        existing.setAvatarUrl(dto.getAvatarUrl());
        existing.setLocation(dto.getLocation());
        return repository.save(existing);
    }

    @Transactional
    public void deleteByAuth0Id(String auth0Id) {
        UserProfile existing = repository.findByAuth0Id(auth0Id)
                .orElseThrow(() -> new ResourceNotFoundException("UserProfile", "auth0Id", auth0Id));
        repository.delete(existing);
    }

    /**
     * Retrieve the profile for the user represented by the given JWT. If no profile
     * exists, a new one is created using basic information from the token.
     */
    @Transactional
    public UserProfile findOrCreateFromJwt(Jwt jwt) {
        if (jwt == null) {
            throw new ResourceNotFoundException("JWT", "token", "null");
        }
        String auth0Id = jwt.getSubject();
        return repository.findByAuth0Id(auth0Id).orElseGet(() -> {
            String displayName = jwt.getClaimAsString("nickname");
            if (displayName == null || displayName.isBlank()) {
                displayName = jwt.getClaimAsString("name");
            }
            String avatarUrl = jwt.getClaimAsString("picture");
            UserProfile profile = new UserProfile(auth0Id, displayName, null, avatarUrl, null);
            return repository.save(profile);
        });
    }
}
