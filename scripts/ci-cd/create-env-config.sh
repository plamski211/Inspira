#!/bin/bash
# create-env-config.sh - Generate environment configuration for the frontend

# Navigate to frontend directory
cd frontend

# Create env.local.js in the public directory (will be copied to dist during build)
mkdir -p public

# Create env-config.js file with dynamic environment variables
cat > public/env-config.js << EOF
// This file is generated at build time and injected into the static HTML
window.ENV = {
  API_URL: '/api',
  AUTH0_DOMAIN: 'dev-i9j8l4xe.us.auth0.com',
  AUTH0_CLIENT_ID: 'JBfJJE07F7yrWTPq7nZ04WO4XdqzPvOa',
  AUTH0_AUDIENCE: 'https://api.inspira.com',
  AUTH0_REDIRECT_URI: window.location.origin,
  BUILD_TIME: '$(date)',
  ENV: 'production'
};
console.log('Environment config loaded:', window.ENV);
EOF

echo "Environment configuration created: public/env-config.js"

# Return to project root
cd .. 