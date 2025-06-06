package com.inspira.contentservice.repository;

import com.inspira.contentservice.model.ContentItem;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ContentItemRepository extends JpaRepository<ContentItem, Long> {
    List<ContentItem> findByUserId(Long userId);
    List<ContentItem> findByTagsContaining(String tag);
} 