```terminal:interrupt
autostart: true
hidden: true
cascade: true
```
```dashboard:open-dashboard
name: The Twelve Factors
```

#### Factor 5: Build, release, run
The **fifth factor** calls for the **strict separation between the build, release, and run stages**. 
As we already learned, TAP uses [Cartographer](https://cartographer.sh) to construct a supply chain with build, release, and run stages.

#### Factor 7: Port binding

Factor 7 states **services need to be exposed for external or inter-service access with well-defined ports**.

[Spring Cloud's `ServiceRegistry` interface](https://docs.spring.io/spring-cloud-commons/docs/current/reference/html/#discovery-client) solves this problem and provides client-side libraries for **service registry implementations such as Consul, Zookeeper, Eureka, plus Kubernetes**.

In Kubernetes, each service can interface with another service by using its service name, which is **resolved by Kubernetes DNS support, and the benefit of the Spring Cloud's Registry interface is limited**. 

**Due to even more capabilities like proper load balancing, it could make sense to use an Ingress Controller like in our case Contour as a solution for the factor**.

![Updated architecture with Service Registry](../images/microservice-architecture-service-discovery.png)

As Spring Cloud's Registry interface still has its raison d'être for portability to other platforms like Cloud Foundry, **TAP 1.7 introduced the Service Registry for VMware Tanzu**, which provides the capability to **create Eureka servers** in your namespaces and bind your workloads to them.

An Eureka server can be easily created via the EurekaServer resource.
```editor:append-lines-to-file
file: ~/config/service-registry/service-registry.yaml
description: Create Eureka server
text: |
  apiVersion: "service-registry.spring.apps.tanzu.vmware.com/v1alpha1"
  kind: EurekaServer
  metadata:
    name: eurekaserver-1
  spec:
    replicas: 1
```
```terminal:execute
command: kubectl apply -f ~/config/service-registry/
clear: true
```

Let's for now only [configure the Spring Cloud service discovery](https://cloud.spring.io/spring-cloud-netflix/reference/html/#service-discovery-eureka-clients) for the order and the product service, as there is no direct connection to the shipping service.
First, we have to add the required dependency to our `pom.xml`s.
```editor:insert-lines-before-line
file: ~/order-service/pom.xml
line: 47
text: |2
          <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
          </dependency>
cascade: true
```
```editor:insert-lines-before-line
file: ~/product-service/pom.xml
line: 33
text: |2
          <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
          </dependency>
```

To instrument the `RestTemplate` instance we use to fetch the product list from the product service to use Eureka, we have to add the `@LoadBalanced` qualifier to the RestTemplate @Bean. 
{% raw %}
```editor:insert-lines-before-line
file: ~/product-service/pom.xml
line: 18
text: |2
      @LoadBalanced
cascade:true
```
{% endraw %}
```editor:insert-lines-before-line
file: ~/product-service/pom.xml
line: 13
text: |2
  import org.springframework.cloud.client.loadbalancer.LoadBalanced;
```

To deploy our code changes, we have to commit them.
```terminal:execute
command: |
  (cd order-service && git add . && git commit -m "Add service discovery" && git push)
  (cd product-service && git add . && git commit -m "Add service discovery" && git push)
clear: true
```

The service discovery is done based on the `spring.application.name` of a service. 
```editor:open-file
file: product-service/src/main/resources/application.yaml
```
So we have to change the current configuration of the `order.products-api-url` in the order service accordingly.
```editor:select-matching-text
file: ~/samples/externalized-configuration/order-service.yaml
text: "order.products-api-url"
before: 0
after: 0
```
```editor:replace-text-selection
file: ~/samples/externalized-configuration/order-service.yaml
text: "order.products-api-url: http://PRODUCTSERVICE/api/v1/products"
```
```terminal:execute
command: (cd samples/externalized-configuration && git add . && git commit -m "Add service discovery" && git push)
clear: true
```

Finally, we have to claim the credentials to access the running Eureka server by configuring the **service binding**. The ResourceClaim pointed to in the service claim above was already created for you when this workshop was initialized.
```editor:insert-value-into-yaml
file: ~/product-service/config/workload.yaml
path: spec.serviceClaims
value:
  - name: service-registry
    ref:
      apiVersion: services.apps.tanzu.vmware.com/v1alpha1
      kind: ResourceClaim
      name: eurekaserver-1
cascade: true
```
```editor:insert-value-into-yaml
file: ~/order-service/config/workload.yaml
path: spec.serviceClaims
value:
  - name: service-registry
    ref:
      apiVersion: services.apps.tanzu.vmware.com/v1alpha1
      kind: ResourceClaim
      name: eurekaserver-1
```
```terminal:execute
command: |
  kubectl apply -f ~/product-service/config/workload.yaml
  kubectl apply -f ~/order-service/config/workload.yaml
clear: true
```

```terminal:execute
session: 2
command: tanzu apps workload tail order-service --since 1h --component run
clear: true
```

{% raw %}
```
2023-11-20T16:02:18.705Z  INFO 1 --- [nfoReplicator-0] com.netflix.discovery.DiscoveryClient    : DiscoveryClient_ORDER-SERVICE/order-service-00005-deployment-6d4f7f898d-p98rr:order-service:8080 - registration status: 204
2023-11-20T16:02:48.394Z  INFO 1 --- [freshExecutor-0] com.netflix.discovery.DiscoveryClient    : Getting all instance registry info from the eureka server
```
{% endraw %}

```terminal:execute
command: |
  curl -s -X POST -H "Content-Type: application/json" -d '{"productId":"1", "shippingAddress": "Stuttgart"}' https://order-service-{{ session_namespace }}.{{ ENV_TAP_INGRESS }}/api/v1/orders | jq .
clear: true
```

{% raw %}
```
2023-11-20T16:07:17.563Z  INFO 1 --- [trap-executor-0] c.n.d.s.r.aws.ConfigClusterResolver      : Resolving eureka endpoints via configuration
```
{% endraw %}

####  Factor 10: Dev/prod parity

The tenth factor emphasizes the **importance of keeping all of our environments as similar as possible** to minimize potential discrepancies that could lead to unexpected behavior in production.
**Containers play a crucial role in achieving this** by encapsulating the application and its dependencies, including the operating system, ensuring that it runs consistently across different environments. 

As we have mentioned earlier in this workshop, TAP uses Cloud Native Buildpacks (CNBs) to detect what is needed to compile and run an application based on the application's source code.
The application is then compiled and packaged in a container image with best practices in mind by the appropriate buildpack.

The biggest benefits of CNBs are increased security, minimized risk, and increased developer productivity because they don't need to care much about the details of how to build a container.

**Spring Boot version 2.3.0 introduced Cloud Native Buildpack support** to simplify container image creation. You can create a container image using the open-source [Paketo buildpacks](https://paketo.io) with the following commands for Maven and Gradle.
```
./mvnw spring-boot:build-image -Dspring-boot.build-image.imageName=myorg/myapp
./gradlew bootBuildImage --imageName=myorg/myapp
```

With all the benefits of Cloud Native Buildpacks, one of the **biggest challenges with container images still is to keep the operating system, used libraries, etc., up-to-date** in order to minimize attack vectors by CVEs.

With **VMware Tanzu Build Service (TBS)**, which is part of TAP and based on an open-source project called [kpack](https://github.com/buildpacks-community/kpack), it's possible **automatically recreate and push an updated container image to the target registry if there is a new version of the buildpack or the base operating system available** (e.g. due to a CVE).

All of this is part of TAP's Supply Chain, making it possible to deploy security patches automatically.

In the details of the Image Provider step in **Tanzu Developer Portal**, you're able to see the **logs of the container build and the tag of the produced image**.

It also shows the reason for an image build. In this case, it's due to our configuration change.

You can open the supply chain for the product service using the link below and view all these details.

```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/supply-chain/host/{{ session_namespace }}/product-service
```

![](../images/image-provider-latest-builds.png)
![](../images/build-reasons.png)


####  Factor 11: Logs

Factor eleven states that **Logs should be treated as event streams**.
The key point with logs in a cloud-native application is that it writes all of its log entries to stdout and stderr, and the aggregation, processing, and storage of logs is a nonfunctional requirement that is satisfied by your platform or cloud provider.

For developers, Tanzu Developer Portal also provides the capability to view the logs of your application.

Execute the following command and click on the link in the terminal to open the logs view for the product service in a new tab. 
```terminal:execute
command: |
  echo LINK TO LOGS VIEW: https://tap-gui.{{ ENV_TAP_INGRESS }}/catalog/default/Component/product-service/workloads/pods/$(kubectl get pods -l serving.knative.dev/service=product-service -o jsonpath='{.items[0].metadata.uid}')/logs
description: Post link to logs view for the product service in terminal
clear: true
```

We also saw a way of tailing the logs of any workload using `tanzu app workloads tail` CLI command throughout this workshop already.

####  Factor 12: Admin processes

The final factor states that administrative tasks, such as database migrations and one-time scripts, should be executed in the same environment and manner as regular application code. 
This factor is a bit outdated. You should avoid administrative processes as much as possible for security reasons and try to find a design/architecture that suits your needs better.

**Factors eight and nine will be covered in the next section**.
