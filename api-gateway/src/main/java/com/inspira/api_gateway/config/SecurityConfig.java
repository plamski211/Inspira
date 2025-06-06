package com.inspira.api_gateway.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.web.server.SecurityWebFilterChain;
import org.springframework.security.web.server.ServerAuthenticationEntryPoint;
import org.springframework.security.web.server.authentication.HttpStatusServerEntryPoint;

@Configuration
public class SecurityConfig {
    private static final Logger logger = LoggerFactory.getLogger(SecurityConfig.class);

    @Bean
    public SecurityWebFilterChain springSecurityFilterChain(ServerHttpSecurity http) {
        ServerAuthenticationEntryPoint entryPoint = new HttpStatusServerEntryPoint(HttpStatus.UNAUTHORIZED);

        logger.info("Configuring simplified security without JWT validation");

        return http
                .csrf(ServerHttpSecurity.CsrfSpec::disable)
                .authorizeExchange(exchanges -> exchanges
                        // Allow all requests for now to get things working
                        .anyExchange().permitAll()
                )
                .exceptionHandling(ex -> ex.authenticationEntryPoint(entryPoint))
                .build();
    }
}
