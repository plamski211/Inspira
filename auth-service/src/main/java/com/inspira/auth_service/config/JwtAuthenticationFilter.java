package com.inspira.auth_service.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.inspira.auth_service.exception.ErrorResponse;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.MalformedJwtException;
import io.jsonwebtoken.UnsupportedJwtException;
import io.jsonwebtoken.security.SignatureException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.LocalDateTime;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    private static final Logger logger = LoggerFactory.getLogger(JwtAuthenticationFilter.class);

    private final JwtTokenProvider jwtTokenProvider;
    private final UserDetailsService userDetailsService;
    private final ObjectMapper objectMapper;

    public JwtAuthenticationFilter(JwtTokenProvider jwtTokenProvider, UserDetailsService userDetailsService) {
        this.jwtTokenProvider = jwtTokenProvider;
        this.userDetailsService = userDetailsService;
        this.objectMapper = new ObjectMapper();
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        try {
            String jwt = parseJwt(request);
            if (jwt != null) {
                try {
                    if (jwtTokenProvider.validateToken(jwt)) {
                        String username = jwtTokenProvider.getUsernameFromToken(jwt);

                        UserDetails userDetails = userDetailsService.loadUserByUsername(username);

                        // Check if user is enabled
                        if (!userDetails.isEnabled()) {
                            sendErrorResponse(response, HttpStatus.FORBIDDEN, "User account is disabled");
                            return;
                        }

                        UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                                userDetails, null, userDetails.getAuthorities());
                        authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

                        SecurityContextHolder.getContext().setAuthentication(authentication);
                    }
                } catch (SignatureException e) {
                    logger.error("Invalid JWT signature: {}", e.getMessage());
                    sendErrorResponse(response, HttpStatus.UNAUTHORIZED, "Invalid JWT signature");
                    return;
                } catch (MalformedJwtException e) {
                    logger.error("Invalid JWT token: {}", e.getMessage());
                    sendErrorResponse(response, HttpStatus.UNAUTHORIZED, "Invalid JWT token");
                    return;
                } catch (ExpiredJwtException e) {
                    logger.error("JWT token is expired: {}", e.getMessage());
                    sendErrorResponse(response, HttpStatus.UNAUTHORIZED, "JWT token is expired");
                    return;
                } catch (UnsupportedJwtException e) {
                    logger.error("JWT token is unsupported: {}", e.getMessage());
                    sendErrorResponse(response, HttpStatus.UNAUTHORIZED, "JWT token is unsupported");
                    return;
                } catch (IllegalArgumentException e) {
                    logger.error("JWT claims string is empty: {}", e.getMessage());
                    sendErrorResponse(response, HttpStatus.UNAUTHORIZED, "JWT claims string is empty");
                    return;
                } catch (UsernameNotFoundException e) {
                    logger.error("User not found: {}", e.getMessage());
                    sendErrorResponse(response, HttpStatus.UNAUTHORIZED, "User not found");
                    return;
                }
            }
        } catch (Exception e) {
            logger.error("Cannot set user authentication: {}", e.getMessage());
        }

        filterChain.doFilter(request, response);
    }

    private String parseJwt(HttpServletRequest request) {
        String headerAuth = request.getHeader("Authorization");

        if (StringUtils.hasText(headerAuth) && headerAuth.startsWith("Bearer ")) {
            return headerAuth.substring(7);
        }

        return null;
    }

    private void sendErrorResponse(HttpServletResponse response, HttpStatus status, String message) throws IOException {
        ErrorResponse errorResponse = new ErrorResponse(
                LocalDateTime.now(),
                status.value(),
                message,
                "path"
        );

        response.setStatus(status.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);

        objectMapper.writeValue(response.getOutputStream(), errorResponse);
    }
}
