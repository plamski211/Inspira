package com.inspira.auth_service.repository;

import com.inspira.auth_service.model.RefreshToken;
import com.inspira.auth_service.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface RefreshTokenRepository extends JpaRepository<RefreshToken, Long> {
    Optional<RefreshToken> findByToken(String token);
    int deleteByUser(User user);
}