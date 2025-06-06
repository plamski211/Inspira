package com.inspira.mediaprocessing.repository;

import com.inspira.mediaprocessing.model.TaskRecord;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TaskRecordRepository extends JpaRepository<TaskRecord, Long> {
} 