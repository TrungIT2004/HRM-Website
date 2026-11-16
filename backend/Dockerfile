# Stage 1: Build ứng dụng bằng Maven
FROM maven:3.9-eclipse-temurin-21-alpine AS builder
WORKDIR /app

# Cache dependency layer
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy mã nguồn và đóng gói JAR
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Runtime môi trường JRE gọn nhẹ
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Copy file JAR từ stage builder
COPY --from=builder /app/target/*.jar app.jar

# Tạo thư mục lưu trữ file upload và log
RUN mkdir -p /app/uploads /app/logs

EXPOSE 8080
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]