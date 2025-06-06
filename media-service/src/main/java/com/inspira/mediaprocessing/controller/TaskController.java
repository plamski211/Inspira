package com.inspira.mediaprocessing.controller;

import com.inspira.mediaprocessing.model.TaskRecord;
import com.inspira.mediaprocessing.repository.TaskRecordRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/media-tasks")
public class TaskController {
    private final TaskRecordRepository repo;

    public TaskController(TaskRecordRepository repo) {
        this.repo = repo;
    }

    @GetMapping
    public List<TaskRecord> all() {
        return repo.findAll();
    }

    @GetMapping("/{id}")
    public ResponseEntity<TaskRecord> get(@PathVariable Long id) {
        return repo.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
} 