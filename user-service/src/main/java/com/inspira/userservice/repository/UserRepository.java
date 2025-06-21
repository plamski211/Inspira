package com.inspira.userservice.repository;

import com.inspira.userservice.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * Repository for User entity with GDPR-related query methods
 */
@Repository
public interface UserRepository extends JpaRepository<User, String> {
    
    /**
     * Find users who have given marketing consent
     * @return List of users who have consented to marketing communications
     */
    java.util.List<User> findByMarketingConsentTrue();
    
    /**
     * Find users who have not been deleted (GDPR right to be forgotten)
     * @return List of active users
     */
    java.util.List<User> findByDeletedFalse();
} 