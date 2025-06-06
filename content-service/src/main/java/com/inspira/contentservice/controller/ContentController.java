package com.inspira.contentservice.controller;

import com.inspira.contentservice.dto.ContentItemDto;
import com.inspira.contentservice.service.ContentService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/content")
public class ContentController {
    private final ContentService service;
    
    public ContentController(ContentService service) { 
        this.service = service; 
    }

    @PostMapping
    public ResponseEntity<ContentItemDto> create(@RequestBody ContentItemDto dto) {
        return ResponseEntity.ok(service.create(dto));
    }

    @GetMapping
    public ResponseEntity<List<ContentItemDto>> list(
            @RequestParam(required=false) Long userId,
            @RequestParam(required=false) String tag) {
        if(userId != null) return ResponseEntity.ok(service.listByUser(userId));
        if(tag != null) return ResponseEntity.ok(service.listByTag(tag));
        return ResponseEntity.ok(service.listAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<ContentItemDto> get(@PathVariable Long id) {
        return service.getById(id)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
} 