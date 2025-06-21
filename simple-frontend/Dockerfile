FROM nginx:alpine

COPY html/ /usr/share/nginx/html/

RUN echo 'server { \
    listen 80; \
    server_name _; \
    root /usr/share/nginx/html; \
    index index.html; \
\
    # MIME types \
    include /etc/nginx/mime.types; \
\
    # Serve static files \
    location / { \
        try_files $uri $uri/ /index.html; \
        add_header "Access-Control-Allow-Origin" "*"; \
    } \
\
    # API proxy \
    location /api/ { \
        proxy_pass http://api-gateway:8080/; \
        proxy_http_version 1.1; \
        proxy_set_header Upgrade $http_upgrade; \
        proxy_set_header Connection "upgrade"; \
        proxy_set_header Host $host; \
        proxy_cache_bypass $http_upgrade; \
        proxy_set_header X-Real-IP $remote_addr; \
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; \
        proxy_set_header X-Forwarded-Proto $scheme; \
    } \
\
    # Health check endpoint \
    location /health { \
        try_files $uri $uri/ /health/index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
