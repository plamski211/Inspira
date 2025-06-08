package com.inspira.userservice.controller;

import com.inspira.userservice.service.UserProfileService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    
    private final UserProfileService userProfileService;

    public AuthController(UserProfileService userProfileService) {
        this.userProfileService = userProfileService;
    }

    @GetMapping("/callback")
    public ResponseEntity<?> handleAuth0Callback(@AuthenticationPrincipal Jwt jwt) {
        // This will create or update the user profile based on Auth0 data
        var profile = userProfileService.findOrCreateFromJwt(jwt);
        return ResponseEntity.ok(profile);
    }

    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUser(@AuthenticationPrincipal Jwt jwt) {
        var profile = userProfileService.findOrCreateFromJwt(jwt);
        return ResponseEntity.ok(profile);
    }
}
