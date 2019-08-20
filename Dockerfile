FROM maven:3.3 AS builder
WORKDIR /project

ADD ./pom.xml /project/pom.xml

RUN mvn dependency:go-offline -B

ADD ./src /project/src

RUN mvn package



FROM tomcat:9-alpine

HEALTHCHECK --interval=5s CMD curl -f http://localhost:8080 || exit 1

RUN apk --no-cache add curl
RUN rm -rf /usr/local/tomcat/webapps/*
COPY --from=builder /project/target/SampleServlet.war /usr/local/tomcat/webapps/ROOT.war
CMD ["catalina.sh", "run"]
