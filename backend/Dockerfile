FROM eclipse-temurin:21-jdk AS build

WORKDIR /workspace

COPY gradlew gradlew
COPY gradle gradle
COPY build.gradle.kts settings.gradle.kts ./
COPY src src

RUN chmod +x ./gradlew
RUN ./gradlew bootJar --no-daemon
RUN find build/libs -name "*.jar" ! -name "*plain.jar" -exec cp {} /app.jar \;

FROM eclipse-temurin:21-jre

WORKDIR /app

COPY --from=build /app.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
