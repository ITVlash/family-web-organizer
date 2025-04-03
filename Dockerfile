FROM amazoncorretto
WORKDIR /app
COPY target/family-organizer-app.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]