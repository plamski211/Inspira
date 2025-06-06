package com.inspira.contentservice.mapper;

import com.inspira.contentservice.dto.ContentItemDto;
import com.inspira.contentservice.model.ContentItem;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface ContentMapper {
    ContentItemDto toDto(ContentItem entity);
    ContentItem toEntity(ContentItemDto dto);
} 