package com.inspira.userservice.service;

import com.inspira.userservice.dto.CreateUserProfileRequest;
import com.inspira.userservice.dto.UpdateUserProfileRequest;
import com.inspira.userservice.exception.ResourceNotFoundException;
import com.inspira.userservice.model.UserProfile;
import com.inspira.userservice.repository.UserProfileRepository;
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
        if (repository.findByAuth0Id(dto.getAuth0Id()).isPresent()) {
            throw new ResourceNotFoundException("UserProfile", "auth0Id", dto.getAuth0Id());
        }
        UserProfile profile = new UserProfile(
                dto.getAuth0Id(),
                dto.getDisplayName(),
                dto.getBio(),
                dto.getAvatarUrl(),
                dto.getLocation()
        );
        return repository.save(profile);
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
}
