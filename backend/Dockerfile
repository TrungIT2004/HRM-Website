# Sử dụng image JDK 21 nhẹ
FROM eclipse-temurin:21-jre-alpine

# Tạo thư mục làm việc
WORKDIR /app

# Sao chép file JAR đã build (giả sử bạn đã build trước)
COPY target/*.jar app.jar

# Mở cổng 8080
EXPOSE 8080

# Chạy ứng dụng với JVM tối ưu cho container
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]