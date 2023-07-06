```dashboard:open-dashboard
name: The Twelve Factors
```

The **sixth factor** implies that any **data** that needs to be persisted must be **stored in a stateful backing service**, such as a database.
Those backing services are treated as attached resources in a 12-factor app which can be swapped without changing the application code in case of failures. 

Let‘s see how we can make our application even more **resilient to backing services failures**.

##### Caching

Traditional databases, for example, are often too brittle or unreliable for use with microservices. That’s why every modern distributed architecture needs a cache!
The [Spring Framework provides support for transparently adding caching](https://docs.spring.io/spring-framework/reference/integration/cache.html#page-title) to an application. 
The cache abstraction **does not provide an actual store**. Examples of Cache providers that are supported out of the box are **EhCache, Hazelcast, Couchbase, Redis and Caffeine**. Part of the VMware Tanzu portfolio is also an in-memory data grid called **VMware Tanzu Gemfire** that is powered by Apache Geode and can be used with minimal configuration.

To **improve the reliability and performance of our calls from the order service to its relational database via JDBC and the product service via REST**, let’s add a distributed caching solution, in this case **Redis**. 
With Spring Boot’s autoconfiguration and Caching abstraction and in this case Spring Data Redis it’s very easy to add Caching to the **order-service**.

**TODO: Create Redis instance via Crossplane, Add related stuff to order-service: https://github.com/timosalm/spring-cloud-demo-tap/tree/main/order-service**

![Updated architecture with Caching](../images/microservice-architecture-cache.png)

##### Circuit Breaker

In distributed systems like microservices, requests might timeout or fail completely.
If for example the cache of the product list for our order service has expired and a request to the product service to fetch the product list fails, with a so-called Circuit Breaker, we are able to define a fallback that will be called for all further calls to the product service until a variable amount of time, to allow the product service to recover and prevent a network or service failure from cascading to other services.

[Spring Cloud Circuit Breaker](https://spring.io/projects/spring-cloud-circuitbreaker) supports the three popular open-source options Resilience4J, Sentinel, and Hystrix. We'll now integrate Resilience4J in the order service.

**TODO: Add related stuff to order-service: https://github.com/timosalm/spring-cloud-demo-tap/tree/main/order-service**

![Updated architecture with Circuit Breaker](../images/microservice-architecture-cb.png)

