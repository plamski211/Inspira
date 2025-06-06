package com.inspira.api_gateway.controller;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class DebugController {

    @GetMapping("/debug/user")
    public String getUser(@AuthenticationPrincipal String user) {
        return "Authenticated user: " + user;
    }
}
