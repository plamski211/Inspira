# Use an official OpenJDK base image
FROM eclipse-temurin:17-jdk-jammy

# Set the working directory in the container
WORKDIR /app

# Build argument for the JAR file, adjust if your build output folder differs
ARG JAR_FILE=build/libs/*.jar

# Copy the JAR file into the container
COPY ${JAR_FILE} app.jar

# Expose the port on which your app will run (adjust if necessary)
EXPOSE 8082

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
