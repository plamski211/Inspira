#!/bin/bash

# Test script to simulate the authentication flow and user profile creation

echo "=== Testing Auth Flow ==="

# 1. Create a test user profile
echo "Creating test user profile..."
CREATE_RESPONSE=$(curl -s -X POST http://localhost:8080/api/users/profiles/test/create)
echo "Response: $CREATE_RESPONSE"

# Extract auth0_id from the response
AUTH0_ID=$(echo $CREATE_RESPONSE | grep -o '"auth0Id":"[^"]*"' | cut -d'"' -f4)
echo "Auth0 ID: $AUTH0_ID"

# URL encode the auth0_id
ENCODED_AUTH0_ID=$(echo $AUTH0_ID | sed 's/|/%7C/g')
echo "Encoded Auth0 ID: $ENCODED_AUTH0_ID"

# 2. Get the user profile by ID
echo -e "\nFetching user profile by ID..."
PROFILE_RESPONSE=$(curl -s -X GET "http://localhost:8080/api/users/profiles/$ENCODED_AUTH0_ID")
echo "Response: $PROFILE_RESPONSE"

# 3. Check if the profile exists in the database
echo -e "\nChecking database for user profile..."
DB_RESPONSE=$(docker exec inspira_github-postgres-users-1 psql -U user_user -d users -c "SELECT * FROM user_profiles WHERE auth0_id='$AUTH0_ID';")
echo "$DB_RESPONSE"

echo -e "\n=== Test Complete ===" 