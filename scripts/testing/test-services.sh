#!/bin/bash

echo "Testing User Service health via API Gateway..."
curl -v http://localhost:8000/api/health

echo -e "\n\nTesting Content Service health via API Gateway..."
curl -v http://localhost:8000/api/content-health

echo -e "\n\nTesting Media Service health via API Gateway..."
curl -v http://localhost:8000/api/media-health

echo -e "\n\nTesting User Service directly..."
curl -v http://localhost:8080/health

echo -e "\n\nTesting Content Service directly..."
curl -v http://localhost:8081/health

echo -e "\n\nTesting Media Service directly..."
curl -v http://localhost:8082/health

echo -e "\n\nTesting User Profile Creation..."
curl -v -X POST -H "Content-Type: application/json" -d '{"auth0Id":"test-auth0-id","displayName":"Test User","avatarUrl":"https://example.com/avatar.png"}' http://localhost:8000/api/users/profiles/debug/direct-create

echo -e "\n\nTesting Content Upload (this will fail without proper auth)..."
curl -v -X POST -F "file=@README.md" -F "title=Test Content" -F "description=Test Description" http://localhost:8000/api/content/upload 