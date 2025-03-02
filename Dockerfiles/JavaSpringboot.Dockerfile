# ============================
# 1️⃣ Build Stage: Compile Java Code
# ============================
FROM maven:3.9.6-eclipse-temurin-17 AS build

# Set the working directory
WORKDIR /app

# Copy pom.xml and download dependencies (for better caching)
COPY pom.xml .
RUN mvn dependency:go-offline

# Copy the entire project
COPY . .

# Build the application (JAR file)
RUN mvn clean package -DskipTests

# ============================
# 2️⃣ Run Stage: Use Lightweight Java Runtime
# ============================
FROM openjdk:17-jdk-slim

# Set the working directory
WORKDIR /app

# Copy only the JAR file from the build stage
COPY --from=build /app/target/charmr-0.0.1-SNAPSHOT.jar app.jar

# Expose application port
EXPOSE 9090

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
