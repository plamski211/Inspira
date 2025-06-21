# Distributed Systems & Data Requirements

This document outlines the distributed systems architecture, data consistency mechanisms, security requirements, and legal/ethical considerations for the Inspira platform.

## Distributed Systems Architecture (LO7)

### Overview

The Inspira platform is designed as a distributed system with multiple microservices, distributed databases, and cloud storage solutions to ensure scalability, resilience, and performance.

### Implementation Evidence

| Component | Distribution Mechanism | Consistency Model | Security Requirements | Legal/Ethical Considerations |
|-----------|------------------------|-------------------|------------------------|------------------------------|
| **User Service** | PostgreSQL with replication | Strong consistency | - Encrypted PII data<br>- Role-based access control<br>- Token-based authentication | - GDPR compliance<br>- Right to be forgotten<br>- Data minimization |
| **Content Service** | PostgreSQL with replication + MinIO distributed object storage | Eventual consistency for metadata, Strong for transactions | - Object-level permissions<br>- Encrypted content<br>- Access logging | - Copyright protection<br>- Content moderation<br>- Data ownership |
| **Media Service** | Azure Blob Storage with geo-replication | Eventual consistency | - Signed URLs<br>- Encrypted media<br>- Content scanning | - Content filtering<br>- Age restrictions<br>- Usage tracking |
| **API Gateway** | Stateless with distributed cache | N/A (Stateless) | - Rate limiting<br>- Request validation<br>- JWT verification | - API usage monitoring<br>- Fair usage policy |

### Azure Blob Storage for Media

Azure Blob Storage is used for media files to provide:

1. **Geo-replication**: Data is automatically replicated across multiple regions
2. **Scalability**: Petabyte-scale storage capacity
3. **Durability**: 99.999999999% (11 nines) data durability
4. **Performance**: CDN integration for global content delivery

**Implementation Evidence**:
```java
// MediaProcessingService.java
@Service
public class MediaProcessingService {
    @Value("${azure.storage.connection-string}")
    private String connectionString;
    
    @Value("${azure.storage.container-name}")
    private String containerName;
    
    private BlobServiceClient blobServiceClient;
    
    @PostConstruct
    public void initialize() {
        blobServiceClient = new BlobServiceClientBuilder()
            .connectionString(connectionString)
            .buildClient();
    }
    
    public String uploadMedia(MultipartFile file, String fileName) {
        BlobContainerClient containerClient = blobServiceClient.getBlobContainerClient(containerName);
        BlobClient blobClient = containerClient.getBlobClient(fileName);
        
        try (InputStream data = file.getInputStream()) {
            blobClient.upload(data, file.getSize());
            return blobClient.getBlobUrl();
        } catch (IOException e) {
            throw new RuntimeException("Failed to upload media file", e);
        }
    }
}
```

## Data Consistency Mechanisms

### 1. Strong Consistency (User Data)

User data requires strong consistency to prevent authentication issues and ensure security:

- **Implementation**: PostgreSQL with synchronous replication
- **Evidence**: Configuration in `k8s/base/databases.yaml`
- **Verification**: ACID transactions for user operations

### 2. Eventual Consistency (Media Data)

Media data uses eventual consistency to optimize for availability and partition tolerance:

- **Implementation**: Azure Blob Storage with geo-replication
- **Evidence**: Media service configuration
- **Verification**: Content delivery continues during regional outages

### 3. Hybrid Consistency (Content Data)

Content metadata uses a hybrid approach:

- **Strong consistency** for critical operations (payments, ownership changes)
- **Eventual consistency** for non-critical operations (view counts, comments)
- **Implementation**: Transaction boundaries in content service

## Security Requirements

### Authentication & Authorization

| Component | Security Mechanism | Implementation Evidence |
|-----------|-------------------|------------------------|
| User Service | JWT-based authentication | `JwtAuthenticationFilter.java` |
| API Gateway | Token validation, CORS | `CorsGlobalConfig.java` |
| Content Service | Role-based access control | `SecurityConfig.java` |
| Media Service | Signed URLs with expiration | `S3Client.java` |

### Data Protection

| Data Type | Protection Mechanism | Implementation Evidence |
|-----------|---------------------|------------------------|
| User PII | Encryption at rest | Database configuration |
| Payment Info | Tokenization | External payment processor |
| Media Files | TLS in transit, encryption at rest | Azure Blob configuration |
| Access Logs | Immutable storage | Log configuration |

## Legal & Ethical Considerations

### GDPR Compliance

The platform implements the following GDPR requirements:

1. **Right to be Forgotten**:
   ```java
   // UserService.java (pseudocode)
   @Transactional
   public void deleteUserData(String userId) {
       // Delete user profile
       userRepository.deleteById(userId);
       
       // Delete user content references
       contentRepository.anonymizeUserContent(userId);
       
       // Delete user media
       mediaService.deleteUserMedia(userId);
       
       // Delete user activity logs
       activityLogRepository.deleteByUserId(userId);
   }
   ```

2. **Data Portability**:
   ```java
   // UserService.java (pseudocode)
   public UserDataExport exportUserData(String userId) {
       User user = userRepository.findById(userId);
       List<Content> userContent = contentRepository.findByUserId(userId);
       List<MediaItem> userMedia = mediaRepository.findByUserId(userId);
       
       return new UserDataExport(user, userContent, userMedia);
   }
   ```

3. **Data Minimization**: Only collecting necessary data with clear purpose

4. **Consent Management**: Explicit opt-in for data processing

### Ethical Considerations

1. **Content Moderation**:
   - Automated scanning for inappropriate content
   - User reporting mechanisms
   - Review process for flagged content

2. **Algorithmic Fairness**:
   - Regular audits of recommendation algorithms
   - Transparency in content promotion
   - Diverse representation in featured content

3. **Accessibility**:
   - WCAG compliance
   - Screen reader support
   - Keyboard navigation

## LO7 - Distributed Deployed Databases

### Implementation Evidence

1. **Database Sharding**:
   ```yaml
   # k8s/base/databases.yaml (excerpt)
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: postgres-users
   spec:
     replicas: 3
     template:
       spec:
         containers:
         - name: postgres
           env:
           - name: POSTGRES_DB
             value: users_db
   ---
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: postgres-content
   spec:
     replicas: 3
     template:
       spec:
         containers:
         - name: postgres
           env:
           - name: POSTGRES_DB
             value: content_db
   ```

2. **Distributed Object Storage**:
   ```yaml
   # k8s/base/databases.yaml (excerpt)
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: minio
   spec:
     replicas: 4
     template:
       spec:
         containers:
         - name: minio
           args:
           - server
           - /data{1...4}
           - --console-address
           - ":9001"
   ```

3. **Service Discovery**:
   ```yaml
   # k8s/base/service-monitors.yaml (excerpt)
   apiVersion: monitoring.coreos.com/v1
   kind: ServiceMonitor
   metadata:
     name: user-service-monitor
   spec:
     selector:
       matchLabels:
         app: user-service
     endpoints:
     - port: http
       interval: 15s
   ```

### Data Consistency Verification

To verify data consistency across distributed databases:

1. **Synchronous Replication Check**:
   ```bash
   # Check PostgreSQL replication status
   kubectl exec -it postgres-users-0 -- psql -U postgres -c "SELECT * FROM pg_stat_replication;"
   ```

2. **Object Storage Consistency Check**:
   ```bash
   # Check MinIO distributed storage status
   kubectl exec -it minio-0 -- mc admin info local
   ```

3. **Blob Storage Replication Status**:
   ```bash
   # Check Azure Blob Storage replication status (via Azure CLI)
   az storage account show \
     --name inspiramediastorage \
     --query networkRuleSet.defaultAction
   ```

## Conclusion

The Inspira platform implements a robust distributed systems architecture that addresses:

1. **Data Distribution**: Across multiple databases and storage systems
2. **Data Consistency**: Using appropriate consistency models for different data types
3. **Security Requirements**: Comprehensive protection at all levels
4. **Legal Compliance**: GDPR and other regulatory requirements
5. **Ethical Considerations**: Fair and responsible data practices

This architecture ensures the platform can scale horizontally while maintaining data integrity, security, and compliance with legal and ethical standards. 