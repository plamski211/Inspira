package com.inspira.userservice.config;

import com.inspira.userservice.service.UserProfileService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

// No @Component, managed as a bean in SecurityConfig
public class EnsureUserProfileFilter extends OncePerRequestFilter {
    private static final Logger logger = LoggerFactory.getLogger(EnsureUserProfileFilter.class);

    private final UserProfileService userProfileService;

    public EnsureUserProfileFilter(UserProfileService userProfileService) {
        this.userProfileService = userProfileService;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.isAuthenticated() && authentication.getPrincipal() instanceof Jwt jwt) {
            try {
                logger.debug("EnsureUserProfileFilter: Checking user profile for JWT subject: {}", jwt.getSubject());
                userProfileService.findOrCreateFromJwt(jwt);
            } catch (Exception e) {
                logger.error("EnsureUserProfileFilter: Error ensuring user profile: {}", e.getMessage(), e);
            }
        }
        filterChain.doFilter(request, response);
    }
} 