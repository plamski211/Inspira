package com.inspira.userservice.controller;

import com.inspira.userservice.dto.CreateUserProfileRequest;
import com.inspira.userservice.dto.UpdateUserProfileRequest;
import com.inspira.userservice.dto.UserProfileResponse;
import com.inspira.userservice.model.UserProfile;
import com.inspira.userservice.repository.UserProfileRepository;
import com.inspira.userservice.service.UserProfileService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Tag(name = "User Profiles", description = "APIs to manage user profiles")
@RestController
@RequestMapping("/users/profiles")
public class UserProfileController {

    private static final Logger logger = LoggerFactory.getLogger(UserProfileController.class);
    private final UserProfileService service;
    private final UserProfileRepository repository;

    public UserProfileController(UserProfileService service, UserProfileRepository repository) {
        this.service = service;
        this.repository = repository;
    }

    @Operation(summary = "Debug JWT")
    @GetMapping("/debug/jwt")
    public ResponseEntity<Map<String, Object>> debugJwt(@AuthenticationPrincipal Jwt jwt) {
        Map<String, Object> response = new HashMap<>();
        if (jwt != null) {
            response.put("subject", jwt.getSubject());
            response.put("issuer", jwt.getIssuer());
            response.put("audience", jwt.getAudience());
            response.put("expiresAt", jwt.getExpiresAt());
            response.put("issuedAt", jwt.getIssuedAt());
            response.put("claims", jwt.getClaims());
            logger.info("JWT debug endpoint called with valid JWT. Subject: {}", jwt.getSubject());
        } else {
            response.put("error", "No JWT found");
            logger.warn("JWT debug endpoint called without a valid JWT");
        }
        return ResponseEntity.ok(response);
    }

    @Operation(summary = "Test JWT Authentication")
    @GetMapping("/test/auth")
    public ResponseEntity<Map<String, Object>> testAuth(@AuthenticationPrincipal Jwt jwt, @RequestHeader Map<String, String> headers) {
        Map<String, Object> response = new HashMap<>();
        
        // Log all headers for debugging
        logger.info("Headers received:");
        headers.forEach((key, value) -> {
            if (key.equalsIgnoreCase("authorization")) {
                logger.info("  {}: {}", key, value.length() > 15 ? value.substring(0, 15) + "..." : value);
            } else {
                logger.info("  {}: {}", key, value);
            }
        });
        
        if (jwt != null) {
            response.put("authenticated", true);
            response.put("subject", jwt.getSubject());
            logger.info("Test auth endpoint: JWT is valid. Subject: {}", jwt.getSubject());
        } else {
            response.put("authenticated", false);
            logger.warn("Test auth endpoint: No valid JWT found");
        }
        
        return ResponseEntity.ok(response);
    }

    @Operation(summary = "Create User Profile")
    @PostMapping
    public ResponseEntity<UserProfileResponse> createUserProfile(
            @Valid @RequestBody CreateUserProfileRequest request
    ) {
        logger.info("Creating user profile with auth0Id: {}", request.getAuth0Id());
        try {
            UserProfile saved = service.create(request);
            logger.info("User profile created successfully: {}", saved);
            String encodedAuth0Id = URLEncoder.encode(saved.getAuth0Id(), StandardCharsets.UTF_8);
            return ResponseEntity.created(
                    ServletUriComponentsBuilder.fromCurrentRequest()
                            .path("/{auth0Id}")
                            .buildAndExpand(encodedAuth0Id)
                            .toUri()
            ).body(UserProfileResponse.fromEntity(saved));
        } catch (Exception e) {
            logger.error("Error creating user profile: {}", e.getMessage(), e);
            throw e;
        }
    }

    @Operation(summary = "Get User Profile by Auth0 ID")
    @GetMapping("/{auth0Id}")
    public ResponseEntity<UserProfileResponse> getUserProfile(
            @PathVariable String auth0Id
    ) {
        logger.info("Getting user profile for auth0Id: {}", auth0Id);
        try {
            // URL decode the auth0Id
            String decodedAuth0Id = java.net.URLDecoder.decode(auth0Id, StandardCharsets.UTF_8);
            logger.info("Decoded auth0Id: {}", decodedAuth0Id);
            
            
            UserProfile profile = service.getByAuth0Id(decodedAuth0Id);
            return ResponseEntity.ok(UserProfileResponse.fromEntity(profile));
        } catch (Exception e) {
            logger.error("Error getting user profile: {}", e.getMessage(), e);
            return ResponseEntity.status(500).build();
        }
    }

    @Operation(summary = "Get or create profile for the current user")
    @GetMapping("/me")
    public ResponseEntity<UserProfileResponse> getCurrentUserProfile(
            @AuthenticationPrincipal Jwt jwt,
            @RequestHeader Map<String, String> headers
    ) {
        logger.info("/users/profiles/me called with headers: {}", headers.keySet());
        
        // Log all headers for debugging
        headers.forEach((key, value) -> {
            if (key.equalsIgnoreCase("authorization")) {
                logger.info("  Authorization header present with length: {}", value.length());
                logger.info("  First 20 chars of Authorization: {}", value.substring(0, Math.min(20, value.length())));
            } else {
                logger.info("  {}: {}", key, value);
            }
        });
        
        // Check if JWT is present
        if (jwt == null) {
            logger.warn("No JWT found in request - authentication failed");
            return ResponseEntity.status(401).build();
        }
        
        try {
            // Log JWT details for debugging
            logger.info("JWT subject: {}", jwt.getSubject());
            logger.info("JWT issuer: {}", jwt.getIssuer());
            logger.info("JWT claims: {}", jwt.getClaims());
            
            // Try to find or create profile
            UserProfile profile = service.findOrCreateFromJwt(jwt);
            logger.info("Profile found or created: {}", profile);
            
            // Return the profile
            return ResponseEntity.ok(UserProfileResponse.fromEntity(profile));
        } catch (Exception e) {
            logger.error("Error in getCurrentUserProfile: {}", e.getMessage(), e);
            return ResponseEntity.status(500).build();
        }
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

    @Operation(summary = "Test endpoint to create a profile (for debugging)")
    @PostMapping("/test/create")
    public ResponseEntity<UserProfileResponse> testCreateProfile() {
        logger.info("Test endpoint called to create a profile");
        try {
            String auth0Id = "auth0|test" + System.currentTimeMillis();
            CreateUserProfileRequest request = new CreateUserProfileRequest();
            request.setAuth0Id(auth0Id);
            request.setDisplayName("Test User");
            request.setBio("This is a test user created for debugging");
            request.setAvatarUrl("https://example.com/avatar.png");
            request.setLocation("Test Location");
            
            UserProfile saved = service.create(request);
            logger.info("Test profile created: {}", saved);
            return ResponseEntity.ok(UserProfileResponse.fromEntity(saved));
        } catch (Exception e) {
            logger.error("Error in testCreateProfile: {}", e.getMessage(), e);
            return ResponseEntity.status(500).build();
        }
    }

    @Operation(summary = "Health check endpoint")
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> healthCheck() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "UP");
        response.put("timestamp", System.currentTimeMillis());
        response.put("service", "user-service");
        return ResponseEntity.ok(response);
    }

    @GetMapping("/test/ping")
    public ResponseEntity<String> ping() {
        logger.info("Ping endpoint called");
        return ResponseEntity.ok("pong");
    }

    @Operation(summary = "Test endpoint to create a profile with a specific Auth0 ID (for debugging)")
    @PostMapping("/test/create/{auth0Id}")
    public ResponseEntity<UserProfileResponse> testCreateProfileWithId(@PathVariable String auth0Id) {
        logger.info("Test endpoint called to create a profile for Auth0 ID: {}", auth0Id);
        try {
            // Create a mock JWT with the auth0Id
            Map<String, Object> claims = new HashMap<>();
            claims.put("sub", auth0Id);
            claims.put("nickname", "Test User for " + auth0Id);
            claims.put("picture", "https://example.com/avatar.png");
            
            // Create an in-memory JWT
            Jwt mockJwt = Jwt.withTokenValue("test-token")
                    .header("alg", "RS256")
                    .claims(c -> c.putAll(claims))
                    .build();
            
            // Use the findOrCreateFromJwt method which is what's used in the real flow
            UserProfile profile = service.findOrCreateFromJwt(mockJwt);
            logger.info("Test profile created or retrieved: {}", profile);
            
            return ResponseEntity.ok(UserProfileResponse.fromEntity(profile));
        } catch (Exception e) {
            logger.error("Error in testCreateProfileWithId: {}", e.getMessage(), e);
            throw e;
        }
    }

    @Operation(summary = "Database debug endpoint")
    @GetMapping("/debug/database")
    public ResponseEntity<Map<String, Object>> debugDatabase() {
        logger.info("Database debug endpoint called");
        Map<String, Object> response = new HashMap<>();
        
        try {
            // Count users in the database
            long userCount = repository.count();
            response.put("userCount", userCount);
            
            // Get database metadata
            String dbInfo = "Unknown";
            try {
                // Get connection information instead of the non-existent method
                dbInfo = "PostgreSQL database, connected to: " + 
                      repository.getClass().getSimpleName();
            } catch (Exception e) {
                dbInfo = "Error getting DB info: " + e.getMessage();
            }
            response.put("databaseInfo", dbInfo);
            
            // Try to create a test user directly
            UserProfile testUser = new UserProfile(
                "auth0|debugUser" + System.currentTimeMillis(),
                "Debug User",
                "Created from debug endpoint",
                "https://example.com/debug.png",
                "Debug Location"
            );
            UserProfile saved = repository.save(testUser);
            response.put("testUserCreated", saved != null);
            response.put("testUserId", saved.getId());
            response.put("testUserAuth0Id", saved.getAuth0Id());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("Error in database debug endpoint", e);
            response.put("error", e.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * TEMPORARY: Unauthenticated endpoint to create a user profile directly for debugging.
     * Accepts JSON body with auth0Id, displayName, avatarUrl, etc.
     * Remove this in production!
     */
    @PostMapping("/debug/direct-create")
    public ResponseEntity<UserProfileResponse> debugDirectCreate(@RequestBody Map<String, Object> body) {
        logger.warn("[DEBUG] Direct user profile creation endpoint called! Body: {}", body);
        try {
            CreateUserProfileRequest req = new CreateUserProfileRequest();
            req.setAuth0Id((String) body.getOrDefault("auth0Id", "debug|" + System.currentTimeMillis()));
            req.setDisplayName((String) body.getOrDefault("displayName", "Debug User"));
            req.setBio((String) body.getOrDefault("bio", "Created via debug endpoint"));
            req.setAvatarUrl((String) body.getOrDefault("avatarUrl", null));
            req.setLocation((String) body.getOrDefault("location", null));
            UserProfile saved = service.create(req);
            logger.info("[DEBUG] User profile created: {}", saved);
            return ResponseEntity.ok(UserProfileResponse.fromEntity(saved));
        } catch (Exception e) {
            logger.error("[DEBUG] Error in debugDirectCreate: {}", e.getMessage(), e);
            return ResponseEntity.status(500).build();
        }
    }
}
