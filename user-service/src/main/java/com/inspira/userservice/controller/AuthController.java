package com.inspira.userservice.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/health")
public class AuthController {
    @GetMapping
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("User Service is up and running");
    }
}
