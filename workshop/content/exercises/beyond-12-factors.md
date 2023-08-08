Technology has advanced since the original creation of the 12-factor app, and in some situations, it is necessary to elaborate on the initial guidelines as well as add new guidelines designed to meet modern standards for application development. 

![Beyond the Twelfe-Factor App](../images/beyond-12-factor-app.png)

In his book Beyond the **Twelfe-Factor App**, Kevin Hoffman presented a new set of guidelines that build on the original 12 factors. The book can be downloaded [here](https://tanzu.vmware.com/content/ebooks/beyond-the-12-factor-app).

One of those is **Telemetry**.

##### Distributed Tracing
With Distributed Tracing, you can track user requests end-to-end across microservices architectures. 
**Spring Boot Actuator provides dependency management and auto-configuration for [Micrometer Tracing](https://micrometer.io/docs/tracing)**, a facade for popular tracer libraries.

Spring Boot ships auto-configuration for the following tracers:
- OpenTelemetry with Zipkin, Wavefront, or OTLP
- OpenZipkin Brave with Zipkin or Wavefront

Wavefront is now known as **Aria Operations for Applications**, our full-stack observability solution from infrastructure to applications.

For this workshop, you will use Zipkin as our trace backend to collect and visualize the traces, already running in the cluster.

In addition to the `org.springframework.boot:spring-boot-starter-actuator` dependency, we have to add a library that bridges the Micrometer Observation API to either OpenTelemetry or Brave and one that reports traces to the selected solution.

For our example, let's use **OpenTelemetry with Zikin**.

```editor:insert-lines-before-line
file: ~/product-service/pom.xml
line: 37
text: |2
          <dependency>
            <groupId>io.micrometer</groupId>
            <artifactId>micrometer-tracing-bridge-otel</artifactId>
          </dependency>
          <dependency>
            <groupId>io.opentelemetry</groupId>
            <artifactId>opentelemetry-exporter-zipkin</artifactId>
          </dependency>
```

To automatically propagate traces over the network, use the auto-configured `RestTemplateBuilder` or `WebClient.Builder` to construct the client.

By default, Spring Boot samples only 10% of requests to prevent overwhelming the tracing backend. Let's set it to 100% for our demo so that every request is sent to the tracing backend.
```editor:append-lines-to-file
file: ~/product-service/src/main/resources/application.yaml
text: |
  management:
    tracing.sampling.probability: 1.0
```

To configure reporting to Zipkin we can use the `management.zipkin.tracing.*` configuration properties.
In our case, we would like to **set the required configuration automatically via a ServiceBinding**. Unfortunately, the [spring-cloud-bindings](https://github.com/spring-cloud/spring-cloud-bindings) library, which will be automatically added by the Spring Boot Buildpack, doesn't support it yet. 
But it's possible to add additional bindings by registering additional implementations of the `BindingsPropertiesProcessor`.
```editor:append-lines-to-file
file: ~/product-service/src/main/java/com/example/productservice/ZipkinBindingsPropertiesProcessor.java
text: |
  package com.example.productservice;

  import org.springframework.cloud.bindings.Bindings;
  import org.springframework.cloud.bindings.boot.BindingsPropertiesProcessor;
  import org.springframework.core.env.Environment;

  import java.util.Map;
  public class ZipkinBindingsPropertiesProcessor implements BindingsPropertiesProcessor {
    public static final String TYPE = "zipkin";

    @Override
    public void process(Environment environment, Bindings bindings, Map<String, Object> properties) {
        bindings.filterBindings(TYPE).forEach(binding -> {
            properties.putIfAbsent("management.zipkin.tracing.endpoint", binding.getSecret().get("url") + "/api/v2/spans");
        });
    }
  } 
```
```editor:insert-lines-before-line
file: ~/product-service/pom.xml
line: 33
text: |2
          <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-bindings</artifactId>
            <version>1.13.0</version>
            <scope>provided</scope>
          </dependency>
```
You must also add an entry in `META_INF/spring.factories` so that the custom processor can be discovered.
```editor:append-lines-to-file
file: ~/product-service/src/main/resources/META-INF/spring.factories
text: |
  org.springframework.cloud.bindings.boot.BindingsPropertiesProcessor=\
  com.example.productservice.ZipkinBindingsPropertiesProcessor
```

Last but not least, the service binding has to be configured in the Workload and the changes pushed to Git and applied to the environment.
```editor:insert-value-into-yaml
file: ~/product-service/config/workload.yaml
path: spec.serviceClaims
value:
  - name: tracing
    ref:
      apiVersion: services.apps.tanzu.vmware.com/v1alpha1
      kind: ResourceClaim
      name: zipkin-1
``` 

Let's commit the updated source code and wait until the deployment is updated.
```terminal:execute
command: |
  cd product-service && git add . && git commit -m "Add external configuration support" && git push
  cd ..
clear: true
```
```terminal:execute
command: tanzu apps workload apply -f product-service/config/workload.yaml -y
clear: true
```

As soon as our outdated application and service binding is applied ...
```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/supply-chain/host/{{ session_namespace }}/product-service
```
... we can send a request to the order service, and have a look at the ZipKin UI to view the traces.
```terminal:execute
command: |
  curl -X POST -H "Content-Type: application/json" -d '{"productId":"1", "shippingAddress": "Stuttgart"}' https://order-service-{{ session_namespace }}.{{ ENV_TAP_INGRESS }}/api/v1/orders
clear: true
```

```dashboard:open-url
url: http://zipkin-{{ session_namespace }}.{{ ingress_domain }}
```

![Updated architecture with Observability](../images/microservice-architecture-tracing.png)

##### Factor: API first

**TODO: Adapt for commercial one**
**TODO: Use Crossplane**

The API-first approach prioritizes the design and development of the application programming interface (API) before any other aspects of the application. 
This approach enables for example the consumers of an API to work more independently from its provider, and providers are able to facilitate discussions with stakeholders well before they might have coded themselves past the point of no return.

With so many APIs in a microservices application, developers need an API Gateway that they can control!

[Spring Cloud Gateway](https://spring.io/projects/spring-cloud-gateway) is a library that can be used to create an API gateway to expose endpoints for application services written in any programming language.
It aims to provide a simple and effective way to route to APIs and provides features related to security and resiliency to them.

The best way to create a gateway for your microservices application with Spring Cloud Gateway from scratch is to go to [start.spring.io](https://start.spring.io), add the `spring-cloud-starter-gateway` dependency, and additional dependencies based on your needs for security, distributed tracing, externalized configuration etc.

The main building blocks of Spring Cloud Gateway are: 
- **Routes**: Defined by an ID, a destination URI, a collection of predicates, and a collection of filters.
- **Predicates**: Used for matching on anything from the HTTP request, such as headers or parameters.
- **Filters**: Used for modifications of requests and responses before or after sending the downstream request
Spring Cloud Gateway already provides Predicates and Filters for most of the common use cases, but it's also [possible to build your own](https://docs.spring.io/spring-cloud-gateway/docs/current/reference/html/#developer-guide).

Routes can be configured in a number of ways, like via the Java API provided by the Gateway. 
In this workshop, you will configure some basic routes via configuration properties stored in our Git repository.

Let's first configure the gateway for the Config Server. 
```editor:append-lines-to-file
file: ~/gateway/src/main/resources/application.yaml
text: |
  spring:
    application.name: gateway
    config.import: "optional:configserver:http://config-server.{{ session_namespace }}"
```

Based on the application name, we can now add a properties file with the Route configuration to the cloned Git repository with the externalized configuration.
```editor:append-lines-to-file
file: ~/samples/externalized-configuration/gateway.yaml
text: |2
  management.zipkin.tracing.endpoint: http://zipkin:9411/api/v2/spans
  spring.cloud.gateway:
    routes:
    - id: product-service
      uri: http://product-service.{{ session_namespace }}
      predicates:
      - Path=/services/product-service/**
      filters:
      - StripPrefix=2
    - id: order-service
      uri: http://order-service.{{ session_namespace }}
      predicates:
      - Path=/services/order-service/**
      filters:
      - StripPrefix=2
```
To apply the changes, let's commit the updated externalized configuration.
```terminal:execute
command: |
  cd samples/externalized-configuration && git add . && git commit -m "Add external configuration for gateway" && git push
  cd ~
clear: true
```

The automated deployment of the gateway is already configured, so we only have to wait for it until we're able to send a request through it to the order service. 
```terminal:execute
command: |
  curl -X POST -H "Content-Type: application/json" -d '{"productId":"1", "shippingAddress": "Stuttgart"}' https://gateway-{{ session_namespace }}.{{ ENV_TAP_INGRESS }}/services/order-service/api/v1/orders
clear: true
```
We can also use ZipKin UI to see the new request flow.
```dashboard:open-url
url: http://zipkin-{{ session_namespace }}.{{ ingress_domain }}
```

![Updated architecture with API Gateway](../images/microservice-architecture-gateway.png)

**TODO** TAP GUI Docs and API plugin

##### Authentication and Authorization

Security is a vital part of any application and cloud environment!
OAuth 2 is an authorization framework granting clients access to protected resources via an authorization server.
To make the application secure, you can simply add Spring Security as a dependency. By adding the Spring Security OAuth 2 Client, it will secure your app with OAuth 2 by default.
Spring Authorization Server delivers OAuth 2 Authorization Server support to the Spring community.

![Updated architecture with Authorization Server](../images/microservice-architecture-auth.png)

##### Factor: API first

**TODO** TAP GUI Docs and API plugin

###### API Gateway

By designing your API first, you are able to facilitate discussion with your stakeholders (your internal team, customers, or possibly other teams within your organization who want to consume your API) well before you might have coded yourself past the point of no return. 

With so many APIs in a microservices application, developers need an API Gateway that they can control!

[Spring Cloud Gateway](https://spring.io/projects/spring-cloud-gateway) aims to provide a simple and effective way to route to APIs and provides  features related to security and resiliency to them.

Based on the open source Spring Cloud Gateway project, our commercial offering **VMware Spring Cloud Gateway for Kubernetes** provides additional functionalities like a Kubernetes "native" experience, simple single sign-On (SSO) configuration, and OpenAPI auto-generation for documentation. 

Let‘s have a look how you can deploy and configure a gateway for your microservices application with TAP and the included VMware Spring Cloud Gateway for Kubernetes.

**TODO: Provisioning via Crossplane + provide Config, (Optional) Change Endpoints to internal**

![Updated architecture with API Gateway](../images/microservice-architecture-gateway.png)

##### Authentication and Authorization

Security is a vital part of any application and cloud environment!
OAuth 2 is an authorization framework granting clients access to protected resources via an authorization server.
To make the application secure, you can simply add Spring Security as a dependency. By adding the Spring Security OAuth 2 Client, it will secure your app with OAuth 2 by default.
Spring Authorization Server delivers OAuth 2 Authorization Server support to the Spring community.

![Updated architecture with Authorization Server](../images/microservice-architecture-auth.png)

##### Spring Cloud Stream & Function + TAP FaaS experience


