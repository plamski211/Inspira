package com.inspira.userservice.controller;

import com.inspira.userservice.dto.CreateUserProfileRequest;
import com.inspira.userservice.dto.UpdateUserProfileRequest;
import com.inspira.userservice.dto.UserProfileResponse;
import com.inspira.userservice.model.UserProfile;
import com.inspira.userservice.service.UserProfileService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.List;
import java.util.stream.Collectors;

@Tag(name = "User Profiles", description = "APIs to manage user profiles")
@RestController
@RequestMapping("/api/users/profiles")
public class UserProfileController {

    private final UserProfileService service;

    public UserProfileController(UserProfileService service) {
        this.service = service;
    }

    @Operation(summary = "Create User Profile")
    @PostMapping
    public ResponseEntity<UserProfileResponse> createUserProfile(
            @Valid @RequestBody CreateUserProfileRequest request
    ) {
        UserProfile saved = service.create(request);
        UserProfileResponse response = UserProfileResponse.fromEntity(saved);
        URI location = URI.create(String.format("/api/users/profiles/%s", saved.getAuth0Id()));
        return ResponseEntity.created(location).body(response);
    }

    @Operation(summary = "Get User Profile by Auth0 ID")
    @GetMapping("/{auth0Id}")
    public ResponseEntity<UserProfileResponse> getUserProfile(
            @PathVariable String auth0Id
    ) {
        UserProfile profile = service.getByAuth0Id(auth0Id);
        return ResponseEntity.ok(UserProfileResponse.fromEntity(profile));
    }

    @Operation(summary = "Update User Profile")
    @PutMapping("/{auth0Id}")
    public ResponseEntity<UserProfileResponse> updateUserProfile(
            @PathVariable String auth0Id,
            @Valid @RequestBody UpdateUserProfileRequest request
    ) {
        UserProfile updated = service.update(auth0Id, request);
        return ResponseEntity.ok(UserProfileResponse.fromEntity(updated));
    }

    @Operation(summary = "Delete User Profile")
    @DeleteMapping("/{auth0Id}")
    public ResponseEntity<Void> deleteUserProfile(
            @PathVariable String auth0Id
    ) {
        service.deleteByAuth0Id(auth0Id);
        return ResponseEntity.noContent().build();
    }

    @Operation(summary = "List All User Profiles (Admin Only)")
    @GetMapping
    public ResponseEntity<List<UserProfileResponse>> listAllProfiles() {
        List<UserProfileResponse> list = service.getAll()
                .stream()
                .map(UserProfileResponse::fromEntity)
                .collect(Collectors.toList());
        return ResponseEntity.ok(list);
    }
}
