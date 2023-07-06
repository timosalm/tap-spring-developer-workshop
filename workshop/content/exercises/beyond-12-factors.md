Technology has advanced since the original creation of the 12-factor App, and in some situations, it is necessary to elaborate on the initial guidelines as well as add new guidelines designed to meet modern standards for application development. 

![Beyond the Twelfe-Factor App](../images/beyond-12-factor-app.png)

In his book Beyond the Twelfe-Factor App, Kevin Hoffman presented a new set of guidelines that builds on the original 12 factor.

On of those is **Telemetry**.

##### Distributed Tracing
With Distributed Tracing you can track user requests end-to-end across microservices architectures. 
Spring Boot Actuator provides dependency management and auto-configuration for Micrometer Tracing, a facade for popular tracer libraries.

In our example, we are sending the metrics and traces to Aria Operations for Applications (formerly known as Wavefront), our full-stack observability solution from infrastructure to applications.

By default, the Wavefront Spring Boot Starter creates a Freemium account without a registration for you. But you have to configure the credentials of the freemium account for one instance for the others to see the distributed tracing instead of just the metrics.

![Updated architecture with Observability](../images/microservice-architecture-tracing.png)

##### API Gateway

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


