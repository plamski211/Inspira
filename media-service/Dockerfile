# --- Builder stage ---
FROM gradle:8.0.2-jdk17 AS builder
WORKDIR /home/gradle/src

COPY --chown=gradle:gradle . .
RUN gradle clean build -x test --no-daemon

# --- Runtime stage ---
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

COPY --from=builder /home/gradle/src/build/libs/*.jar app.jar
EXPOSE 8083
ENTRYPOINT ["java", "-jar", "app.jar"]
