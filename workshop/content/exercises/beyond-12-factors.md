Technology has advanced since the original creation of the 12-factor App, and in some situations, it is necessary to elaborate on the initial guidelines as well as add new guidelines designed to meet modern standards for application development. 

![Beyond the Twelfe-Factor App](../images/beyond-12-factor-app.png)

In his book Beyond the Twelfe-Factor App, Kevin Hoffman presented a new set of guidelines that builds on the original 12 factor.

On of those is **Telemetry**.

##### Distributed Tracing
With Distributed Tracing you can track user requests end-to-end across microservices architectures. 
**Spring Boot Actuator provides dependency management and auto-configuration for [Micrometer Tracing](https://micrometer.io/docs/tracing)**, a facade for popular tracer libraries.

Spring Boot ships auto-configuration for the following tracers:
- OpenTelemetry with Zipkin, Wavefront, or OTLP
- OpenZipkin Brave with Zipkin or Wavefront

In addition to the `org.springframework.boot:spring-boot-starter-actuator` dependency, we have to add a library that bridges the Micrometer Observation API to either OpenTelemetry or Brave and one that reports traces to the selected solution.

For our example, let's use **OpenTelemetry with Wavefront**.
```editor:insert-lines-before-line
file: ~/product-service/pom.xml
line: 76
text: |2
          <dependency>
            <groupId>io.micrometer</groupId>
            <artifactId>micrometer-tracing-bridge-otel</artifactId>
          </dependency>
          <dependency>
            <groupId>io.micrometer</groupId>
            <artifactId>micrometer-tracing-reporter-wavefront</artifactId>
          </dependency>
```

To configure reporting to Wavefront we can use the `management.wavefront.*` configuration properties.
```editor:append-lines-to-file
file: ~/product-service/src/main/resources/application.yml
text: |
  management.wavefront.application.name: spring-cloud-demo-tap
```

Wavefront is now known as **Aria Operations for Applications**, our full-stack observability solution from infrastructure to applications.

By default, the Wavefront Spring Boot Starter creates a Freemium account without a registration for you. But you have to configure the credentials of the freemium account for one instance for the others to see the distributed tracing instead of just the metrics.

By default, Spring Boot samples only 10% of requests to prevent overwhelming the trace backend. Let's set it to 100% for our demo so that every request is sent to the trace backend.
```editor:append-lines-to-file
file: ~/product-service/src/main/resources/application.yml
text: |
  management.tracing.sampling.probability=1.0
```

![Updated architecture with Observability](../images/microservice-architecture-tracing.png)

##### Factor: API first

**TODO** TAP GUI Docs and API plugin

###### API Gateway

By designing your API first, you are able to facilitate discussion with your stakeholders (your internal team, customers, or possibly other teams within your organization who want to consume your API) well before you might have coded yourself past the point of no return. 

With so many APIs in a microservices application, developers need an API Gateway that they can control!

![Updated architecture with API Gateway](../images/microservice-architecture-gateway.png)

##### Authentication and Authorization

Security is a vital part of any application and cloud environment!
OAuth 2 is an authorization framework granting clients access to protected resources via an authorization server.
To make the application secure, you can simply add Spring Security as a dependency. By adding the Spring Security OAuth 2 Client, it will secure your app with OAuth 2 by default.
Spring Authorization Server delivers OAuth 2 Authorization Server support to the Spring community.

![Updated architecture with Authorization Server](../images/microservice-architecture-auth.png)

##### Spring Cloud Stream & Function + TAP FaaS experience


