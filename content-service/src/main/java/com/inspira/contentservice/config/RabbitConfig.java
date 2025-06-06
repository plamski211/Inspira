package com.inspira.contentservice.config;

import org.springframework.amqp.core.Queue;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitConfig {
    public static final String CONTENT_CREATED_QUEUE = "content.created";

    @Bean
    public Queue contentCreatedQueue() {
        return new Queue(CONTENT_CREATED_QUEUE);
    }
} 