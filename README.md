# Inspira Platform

Inspira is a microservices-based platform for content creation and sharing.

## Architecture

The platform consists of the following components:

### Backend Services

1. **API Gateway** - Routes requests to appropriate services
   - Port: 8000
   - Routes all `/api/*` requests to the appropriate microservice

2. **User Service** - Handles user authentication and profiles
   - Port: 8080
   - Endpoints: `/api/users/*`
   - Database: PostgreSQL (users)
   - Authentication: Auth0

3. **Content Service** - Manages content metadata and file uploads
   - Port: 8081
   - Endpoints: `/api/content/*`
   - Database: PostgreSQL (content)
   - Storage: MinIO (content-files bucket)

4. **Media Service** - Processes and optimizes uploaded content
   - Port: 8082
   - Endpoints: `/api/media/*`
   - Database: PostgreSQL (media)
   - Storage: MinIO (media-files bucket)

### Frontend

- React application
- Development port: 5173
- Production port: 4173

### Infrastructure

- **PostgreSQL** - Multiple databases for each service
- **MinIO** - Object storage for files
- **PgAdmin** - Database administration

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Node.js 16+
- Java 17+

### Running the Platform

1. Start the backend services:

```bash
docker-compose up -d
```

2. Start the frontend in development mode:

```bash
cd frontend
npm install
npm run dev
```

3. Access the application at http://localhost:5173

## Testing

You can test the services using the provided script:

```bash
./test-services.sh
```

## Service Communication

- **User Service** → Auth0: Authentication
- **Content Service** → Media Service: Content processing
- **Media Service** → Content Service: Processing callbacks
- **Frontend** → API Gateway → All Services

## File Upload Flow

1. User uploads file via Frontend
2. API Gateway routes request to Content Service
3. Content Service stores file in MinIO and metadata in PostgreSQL
4. Content Service requests processing from Media Service
5. Media Service processes file and stores optimized version
6. Media Service notifies Content Service when processing is complete
7. User can access both original and processed versions
