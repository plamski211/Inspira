package com.inspira.auth_service.service;

import com.inspira.auth_service.dto.LoginRequest;
import com.inspira.auth_service.dto.JwtResponse;
import com.inspira.auth_service.dto.RegisterRequest;
import com.inspira.auth_service.exception.AuthException;
import com.inspira.auth_service.exception.TokenRefreshException;
import com.inspira.auth_service.model.RefreshToken;
import com.inspira.auth_service.model.User;
import com.inspira.auth_service.repository.UserRepository;
import com.inspira.auth_service.config.JwtTokenProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Arrays;
import java.util.List;

@Service
public class AuthService {
    private static final Logger logger = LoggerFactory.getLogger(AuthService.class);

    private final UserRepository userRepository;
    private final RefreshTokenService refreshTokenService;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;

    public AuthService(UserRepository userRepository,
                       RefreshTokenService refreshTokenService,
                       PasswordEncoder passwordEncoder,
                       JwtTokenProvider jwtTokenProvider) {
        this.userRepository = userRepository;
        this.refreshTokenService = refreshTokenService;
        this.passwordEncoder = passwordEncoder;
        this.jwtTokenProvider = jwtTokenProvider;
    }

    @Transactional
    public JwtResponse login(LoginRequest request) {
        User user = userRepository.findByUsername(request.getUsername())
                .orElseThrow(() -> new AuthException("User not found with username: " + request.getUsername()));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            logger.warn("Failed login attempt for user: {}", request.getUsername());
            throw new BadCredentialsException("Invalid credentials");
        }

        if (!user.isEnabled()) {
            logger.warn("Disabled user attempted to login: {}", request.getUsername());
            throw new AuthException("User account is disabled");
        }

        // Parse roles from CSV string
        List<String> roles = Arrays.asList(user.getRoles().split(","));

        // Generate JWT token with roles
        String accessToken = jwtTokenProvider.generateToken(user.getUsername(), roles);

        // Create refresh token
        RefreshToken refreshToken = refreshTokenService.createRefreshToken(user.getUsername());

        logger.info("User logged in successfully: {}", request.getUsername());

        JwtResponse response = new JwtResponse();
        response.setAccessToken(accessToken);
        response.setRefreshToken(refreshToken.getToken());
        return response;
    }

    @Transactional
    public JwtResponse register(RegisterRequest request) {
        if (userRepository.findByUsername(request.getUsername()).isPresent()) {
            logger.warn("Registration attempt with existing username: {}", request.getUsername());
            throw new AuthException("Username already exists");
        }

        User user = new User();
        user.setUsername(request.getUsername());
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setRoles("ROLE_USER");
        userRepository.save(user);

        logger.info("User registered successfully: {}", request.getUsername());

        LoginRequest loginRequest = new LoginRequest();
        loginRequest.setUsername(request.getUsername());
        loginRequest.setPassword(request.getPassword());
        return login(loginRequest);
    }

    @Transactional
    public void logout(String refreshToken) {
        refreshTokenService.deleteByToken(refreshToken);
        logger.info("User logged out successfully");
    }

    @Transactional
    public JwtResponse refresh(String refreshToken) {
        return refreshTokenService.findByToken(refreshToken)
                .map(refreshTokenService::verifyExpiration)
                .map(RefreshToken::getUser)
                .map(user -> {
                    List<String> roles = Arrays.asList(user.getRoles().split(","));
                    String accessToken = jwtTokenProvider.generateToken(user.getUsername(), roles);

                    logger.info("Token refreshed for user: {}", user.getUsername());

                    JwtResponse response = new JwtResponse();
                    response.setAccessToken(accessToken);
                    response.setRefreshToken(refreshToken);
                    return response;
                })
                .orElseThrow(() -> new TokenRefreshException(refreshToken, "Invalid refresh token"));
    }
}
