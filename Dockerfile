FROM openjdk:17-alpine
COPY . .

RUN chmod +x gradlew
RUN ./gradlew clean bootJar
RUN mv ./build/libs/*SNAPSHOT.jar ./app.jar

ARG MODE
ENV	ENV_MODE=${MODE}

EXPOSE 6204
ENTRYPOINT ["java" , "-jar", "-Dspring.profiles.active=${ENV_MODE}", "app.jar"]
