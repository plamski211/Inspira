package com.inspira.contentservice.service;

import com.inspira.contentservice.dto.ContentItemDto;
import com.inspira.contentservice.mapper.ContentMapper;
import com.inspira.contentservice.model.ContentItem;
import com.inspira.contentservice.repository.ContentItemRepository;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import static com.inspira.contentservice.config.RabbitConfig.CONTENT_CREATED_QUEUE;

@Service
public class ContentService {
    private final ContentItemRepository repo;
    private final ContentMapper mapper;
    private final RabbitTemplate rabbit;

    public ContentService(ContentItemRepository repo, ContentMapper mapper, RabbitTemplate rabbit) {
        this.repo = repo;
        this.mapper = mapper;
        this.rabbit = rabbit;
    }

    public ContentItemDto create(ContentItemDto dto) {
        ContentItem entity = mapper.toEntity(dto);
        entity.setStatus("pending");
        ContentItem saved = repo.save(entity);
        rabbit.convertAndSend(CONTENT_CREATED_QUEUE, saved.getId().toString());
        return mapper.toDto(saved);
    }

    public List<ContentItemDto> listAll() {
        return repo.findAll().stream()
            .map(mapper::toDto)
            .collect(Collectors.toList());
    }

    public List<ContentItemDto> listByUser(Long userId) {
        return repo.findByUserId(userId).stream()
            .map(mapper::toDto)
            .collect(Collectors.toList());
    }

    public List<ContentItemDto> listByTag(String tag) {
        return repo.findByTagsContaining(tag).stream()
            .map(mapper::toDto)
            .collect(Collectors.toList());
    }

    public Optional<ContentItemDto> getById(Long id) {
        return repo.findById(id).map(mapper::toDto);
    }

    public void delete(Long id) {
        repo.deleteById(id);
    }
} 