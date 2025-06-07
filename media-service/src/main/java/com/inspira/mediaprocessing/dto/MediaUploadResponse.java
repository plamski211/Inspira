package com.inspira.mediaprocessing.dto;

public class MediaUploadResponse {
    private String key;

    public MediaUploadResponse() {}

    public MediaUploadResponse(String key) {
        this.key = key;
    }

    public String getKey() {
        return key;
    }

    public void setKey(String key) {
        this.key = key;
    }
}
