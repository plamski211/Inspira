package com.inspira.mediaprocessing.service;

import com.amazonaws.auth.AWSStaticCredentialsProvider;
import com.amazonaws.auth.BasicAWSCredentials;
import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.AmazonS3ClientBuilder;
import com.amazonaws.services.s3.model.S3Object;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.ByteArrayInputStream;
import java.io.IOException;

@Component
public class S3Client {
    private final AmazonS3 client;
    private final String bucketName;

    public S3Client(@Value("${aws.accessKey}") String key,
                   @Value("${aws.secretKey}") String secret,
                   @Value("${aws.s3.bucket}") String bucket) {
        this.bucketName = bucket;
        BasicAWSCredentials creds = new BasicAWSCredentials(key, secret);
        this.client = AmazonS3ClientBuilder.standard()
                .withCredentials(new AWSStaticCredentialsProvider(creds))
                .build();
    }

    public byte[] download(String key) throws IOException {
        try (S3Object s3Object = client.getObject(bucketName, key)) {
            return s3Object.getObjectContent().readAllBytes();
        }
    }

    public void upload(String key, byte[] content) {
        client.putObject(bucketName, key, new ByteArrayInputStream(content), null);
    }
} 