# --- Builder stage ---
FROM gradle:8.0.2-jdk17 AS builder
WORKDIR /home/gradle/src

# Set environment variables to skip tests
ENV GRADLE_OPTS="-Dorg.gradle.daemon=false"
ENV SKIP_TESTS=true

COPY --chown=gradle:gradle . .
RUN gradle clean bootJar --no-daemon

# --- Runtime stage ---
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

COPY --from=builder /home/gradle/src/build/libs/user-service-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
