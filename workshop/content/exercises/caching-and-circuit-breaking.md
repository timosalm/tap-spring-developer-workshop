```dashboard:open-dashboard
name: The Twelve Factors
```

The **fourth and sixth factor** implies that any **data** that needs to be persisted must be **stored in a stateful backing service**, such as a database, because the processes are stateless and share-nothing. 
Those backing services are treated as attached resources in a 12-factor app which can be swapped without changing the application code in case of failures. 

Let‘s see how we can make our application even more **resilient to backing services failures**.

##### Caching

Traditional databases, for example, are often too brittle or unreliable for use with microservices. That’s why every modern distributed architecture needs a cache!
The [Spring Framework provides support for transparently adding caching](https://docs.spring.io/spring-framework/reference/integration/cache.html#page-title) to an application. 
The cache abstraction **does not provide an actual store**. Examples of Cache providers that are supported out of the box are **EhCache, Hazelcast, Couchbase, Redis and Caffeine**. Part of the VMware Tanzu portfolio is also an in-memory data grid called **VMware Tanzu Gemfire** that is powered by Apache Geode and can be used with minimal configuration.

To **improve the reliability and performance of our calls from the order service to its relational database via JDBC and the product service via REST**, let’s add a distributed caching solution, in this case **Redis**. 
With Spring Boot’s autoconfiguration and Caching abstraction and in this case Spring Data Redis it’s very easy to add Caching to the **order-service**.

Let's first claim the pre-installed Bitnami Redis service to obtain an instance for the service ...
```terminal:execute
command: tanzu service class-claim create redis-1 --class redis-unmanaged --parameter storageGB=0.5
clear: true
```
... and add a service binding to our Workload.
```editor:insert-value-into-yaml
file: ~/order-service/config/workload.yaml
path: spec.serviceClaims
value:
  - name: cache
    ref:
      apiVersion: services.apps.tanzu.vmware.com/v1alpha1
      kind: ClassClaim
      name: redis-1
```

Next, the required libraries have to be added to our `pom.xml`.
```editor:insert-lines-before-line
file: ~/order-service/pom.xml
line: 68
text: |2
          <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-cache</artifactId>
          </dependency>
          <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-redis</artifactId>
          </dependency>
```

Caching and related annotations have to be declaratively enabled via the `@EnableCaching` annotation on a @Configuration class or alternatively via XML configuration.
```editor:insert-lines-before-line
file: ~/order-service/src/main/java/com/example/orderservice/OrderServiceApplication.java
line: 10
text: |
    import org.springframework.cache.annotation.EnableCaching;
```
```editor:insert-lines-before-line
file: ~/order-service/src/main/java/com/example/orderservice/OrderServiceApplication.java
line: 12
text: |
    @EnableCaching
```

To enable caching for the REST call to the product service can be done by just adding the `@Cacheable` annotation with name of the associated cache to the method.
```editor:insert-lines-before-line
file: ~/order-service/src/main/java/com/example/orderservice/order/ProductService.java
line: 13
text: |
    import org.springframework.cache.annotation.Cacheable;
```
```editor:insert-lines-before-line
file: ~/order-service/src/main/java/com/example/orderservice/order/ProductService.java
line: 30
text: |2
      @Cacheable("Products")
```

For caching of the calls to its relational database, we first have to add override all the used methods of the JpaRepository to be able to add related annotations. 
```editor:insert-lines-before-line
file: ~/order-service/src/main/java/com/example/orderservice/order/OrderRepository.java
line: 8
text: |2
      @Cacheable("Orders")
      @Override
      List<Order> findAll();

      @Cacheable("Order")
      @Override
      Optional<Order> findById(Long id);

      @Override
      <S extends Order> S save(S order);
```
```editor:insert-lines-before-line
file: ~/order-service/src/main/java/com/example/orderservice/order/OrderRepository.java
line: 5
text: |
     import org.springframework.cache.annotation.Cacheable;
```

The cache abstraction not only allows populating caches, but also allows removing the cached data with the @CacheEvict which makes for example sense for the save method which adds a new order to the database.

```editor:insert-lines-before-line
file: ~/order-service/src/main/java/com/example/orderservice/order/OrderRepository.java
line: 6
text: |
     import org.springframework.cache.annotation.CacheEvict;
```
```editor:insert-lines-before-line
file: ~/order-service/src/main/java/com/example/orderservice/order/OrderRepository.java
line: 18
text: |2
      @CacheEvict(cacheNames = {"Order", "Orders"}, allEntries = true)
```

To apply the changes, we have to update the Workload in the environment and commit the updated source code.
```terminal:execute
command: |
  cd order-service && git add . && git commit -m "Add caching" && git push
  cd ..
clear: true
```
```terminal:execute
command: tanzu apps workload apply -f order-service/config/workload.yaml -y
clear: true
```

As soon as our outdated application and service binding is applied ...
```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/supply-chain/host/{{ session_namespace }}/order-service
```

... let's check whether the caching works via the application logs and sending two requests to the API.
```execute-2
kubectl logs -l serving.knative.dev/service=order-service
```
```terminal:execute
command: curl https://order-service-{{ session_namespace }}.{{ ENV_TAP_INGRESS }}/api/v1/orders
clear: true
```
```terminal:execute
command: curl https://order-service-{{ session_namespace }}.{{ ENV_TAP_INGRESS }}/api/v1/orders
clear: true
```

![Updated architecture with Caching](../images/microservice-architecture-cache.png)

##### Circuit Breaker

In distributed systems like microservices, requests might timeout or fail completely.
If for example the cache of the product list for our order service has expired and a request to the product service to fetch the product list fails, with a so-called Circuit Breaker, we are able to define a fallback that will be called for all further calls to the product service until a variable amount of time, to allow the product service to recover and prevent a network or service failure from cascading to other services.

[Spring Cloud Circuit Breaker](https://spring.io/projects/spring-cloud-circuitbreaker) supports the two open-source options Resilience4J, and Spring Retry. We'll now integrate Resilience4J in the order service.

First, we have to add the required library to our `pom.xml`.
```editor:insert-lines-before-line
file: ~/order-service/pom.xml
line: 76
text: |2
          <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-circuitbreaker-resilience4j</artifactId>
          </dependency>
```

To create a circuit breaker in your code you can use the CircuitBreakerFactory.
```editor:select-matching-text
file: ~/order-service/src/main/java/com/example/orderservice/order/ProductService.java
text: "ProductService(RestTemplate restTemplate) {"
```
```editor:replace-text-selection
file: ~/order-service/src/main/java/com/example/orderservice/order/ProductService.java
text: |2
  private final CircuitBreakerFactory circuitBreakerFactory;
      ProductService(RestTemplate restTemplate, CircuitBreakerFactory circuitBreakerFactory) {
          this.circuitBreakerFactory = circuitBreakerFactory;
```


`CircuitBreakerFactory.create` will create a `CircuitBreaker` instance that provides a run method that accepts a `Supplier` and a `Function` as an argument. 
```editor:select-matching-text
file: ~/order-service/src/main/java/com/example/orderservice/order/ProductService.java
text: "return Arrays.asList(Objects.requireNonNull(restTemplate.getForObject(productsApiUrl, Product[].class)));"
```
```editor:replace-text-selection
file: ~/order-service/src/main/java/com/example/orderservice/order/ProductService.java
text: |2
  return circuitBreakerFactory.create("products").run(() ->
              Arrays.asList(Objects.requireNonNull(
                restTemplate.exchange(productsApiUrl, HttpMethod.GET, new HttpEntity<>(null, headers), Product[].class).getBody()
          )),
          throwable -> {
              log.error("Call to product service failed, using empty product list as fallback", throwable);
              return Collections.emptyList();
          });
```
The `Supplier` is the code that you are going to wrap in a circuit breaker. The `Function` is the fallback that will be executed if the circuit breaker is tripped. In our case, the fallback just returns an empty product list. The function will be passed the Throwable that caused the fallback to be triggered. You can optionally exclude the fallback if you do not want to provide one.

After pushing our changes to Git, the updated source code will be automatically deployed to production. 
```terminal:execute
command: |
  cd order-service && git add . && git commit -m "Add circuit-breaker" && git push
  cd ..
clear: true
```
```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/supply-chain/host/{{ session_namespace }}/order-service
```

As soon as the updated application is running, we can test the functionality by first sending a request to it with a running product service, terminating the product service and sending another request to the order service. 
```terminal:execute
command: |
  curl -X POST -H "Content-Type: application/json" -d '{"productId":"1", "shippingAddress": "Stuttgart"}' https://order-service-{{ session_namespace }}.{{ ENV_TAP_INGRESS }}/api/v1/orders
clear: true
```

```terminal:execute
command: kubectl delete app product-service
clear: true
```

If everything works as expected the order service should fall back to an empty product list instead.
```terminal:execute
command: |
  curl -X POST -H "Content-Type: application/json" -d '{"productId":"1", "shippingAddress": "Stuttgart"}' https://order-service-{{ session_namespace }}.{{ ENV_TAP_INGRESS }}/api/v1/orders
clear: true
```

![Updated architecture with Circuit Breaker](../images/microservice-architecture-cb.png)