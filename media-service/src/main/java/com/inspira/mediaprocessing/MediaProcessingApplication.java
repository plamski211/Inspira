package com.inspira.mediaprocessing;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

@SpringBootApplication
@EntityScan("com.inspira.mediaprocessing.model")
@EnableJpaRepositories("com.inspira.mediaprocessing.repository")
public class MediaProcessingApplication {
    public static void main(String[] args) {
        SpringApplication.run(MediaProcessingApplication.class, args);
    }
} 