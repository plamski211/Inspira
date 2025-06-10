package com.inspira.userservice.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.web.authentication.preauth.AbstractPreAuthenticatedProcessingFilter;
import com.inspira.userservice.service.UserProfileService;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private static final Logger logger = LoggerFactory.getLogger(SecurityConfig.class);
    private final UserProfileService userProfileService;

    public SecurityConfig(UserProfileService userProfileService) {
        this.userProfileService = userProfileService;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        logger.debug("Configuring security filter chain");
        http
            .csrf(AbstractHttpConfigurer::disable)
            .addFilterAfter(ensureUserProfileFilter(), UsernamePasswordAuthenticationFilter.class)
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> {
                logger.debug("Configuring authorization rules");
                auth
                    .requestMatchers("/health").permitAll()
                    .requestMatchers("/users/profiles/health").permitAll()
                    .requestMatchers("/users/profiles/ping").permitAll()
                    .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()
                    .requestMatchers("/users/profiles/debug/jwt").permitAll()
                    .requestMatchers("/users/profiles/debug/database").permitAll()
                    .requestMatchers("/users/profiles/test/create").permitAll()
                    .requestMatchers("/users/profiles/test/create/{auth0Id}").permitAll()
                    .requestMatchers("/users/profiles/test/auth").permitAll()
                    .requestMatchers("/users/profiles/{auth0Id}").permitAll()
                    .requestMatchers("/users/profiles/debug/direct-create").permitAll()
                    .requestMatchers("/test/**").permitAll()
                    .anyRequest().authenticated();
            })
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt
                    .jwtAuthenticationConverter(jwtAuthenticationConverter())
                )
            );
        logger.debug("Security filter chain configuration completed");
        return http.build();
    }

    @Bean
    public JwtAuthenticationConverter jwtAuthenticationConverter() {
        logger.debug("Creating JWT authentication converter");
        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(jwt -> {
            logger.debug("Converting JWT to authorities. Subject: {}", jwt.getSubject());
            return null;
        });
        return converter;
    }

    @Bean
    public EnsureUserProfileFilter ensureUserProfileFilter() {
        return new EnsureUserProfileFilter(userProfileService);
    }
}
