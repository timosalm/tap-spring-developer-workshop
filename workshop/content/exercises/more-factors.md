```dashboard:open-dashboard
name: The Twelve Factors
```

#### Factor 5: Build, release, run
The **fifth factor** calls for the **strict separation between the build, release, and run stages**. 
For this workshop, an open-source solution called [Cartographer](https://cartographer.sh) is used for the automation of the path to production, that is designed to **fulfill this best practice**.

#### Factor 7: Port binding

A note regarding the seventh factor that **services need to be exposed for external or inter-service access with well-defined ports**.

[Spring Cloud's Registry interface](https://docs.spring.io/spring-cloud-commons/docs/current/reference/html/#discovery-client) solves this problem and provides client-side libraries for **service registry implementations such as Consul, Zookeeper, Eureka, plus Kubernetes**.

In Kubernetes, each service can interface with another service by using its service name, which is **resolved by Kubernetes DNS support, and the benefit of the Spring Cloud's Registry interface is limited**. 

**Due to even more capabilities like proper load balancing, we decided to use the Ingress Controller Contour as a solution for the factor**.

![Updated architecture with Service Registry](../images/microservice-architecture-service-discovery.png)

####  Factor 10: Dev/prod parity

The tenth factor emphasizes the **importance of keeping all of our environments as similar as possible** to minimize potential discrepancies that could lead to unexpected behavior in production.
**Containers play a crucial role in achieving this** by encapsulating the application and its dependencies, including the operating system, ensuring that it runs consistently across different environments. 

As already mentioned, the most obvious way to create a container image for your application is to write a **Dockerfile**, run `docker build`, and push it to the container registry of your choice via `docker push`.

![](../images/dockerfile.png)

As you can see, in general, it is relatively easy and requires little effort to containerize an application, but whether you should go into production with it is another question because it is hard to create an optimized and secure container image (or Dockerfile).

![Example for a simple vs an optimized container image](../images/simple-vs-optimized-dockerfile.png)

To improve container image creation, **Buildpacks** were conceived by Heroku in 2011. Since then, they have been adopted by Cloud Foundry and other PaaS.
The new generation of buildpacks, the [Cloud Native Buildpacks](https://buildpacks.io), is an incubating project in the CNCF which was initiated by Pivotal (now part of VMware) and Heroku in 2018.

Cloud Native Buildpacks (CNBs) detect what is needed to compile and run an application based on the application's source code.
The application is then compiled and packaged in a container image with best practices in mind by the appropriate buildpack.

The biggest benefits of CNBs are increased security, minimized risk, and increased developer productivity because they don't need to care much about the details of how to build a container.

**Spring Boot version 2.3.0 introduced Cloud Native Buildpack support** to simplify container image creation. You can create a container image using the open-source [Paketo buildpacks](https://paketo.io) with the following commands for Maven and Gradle.
```
./mvnw spring-boot:build-image -Dspring-boot.build-image.imageName=myorg/myapp
./gradlew bootBuildImage --imageName=myorg/myapp
```

With all the benefits of Cloud Native Buildpacks, one of the **biggest challenges with container images still is to keep the operating system, used libraries, etc., up-to-date** in order to minimize attack vectors by CVEs.

With **VMware Tanzu Build Service (TBS)**, which is part of TAP and based on the open source [kpack](https://github.com/buildpacks-community/kpack), it's possible **automatically recreate and push an updated container image to the target registry if there is a new version of the buildpack or the base operating system available** (e.g. due to a CVE).
With our Supply Chain, it's then possible to deploy security patches automatically.

In the details of the Image Provider step in **TAP-GUI**, you're able to see the **logs of the container build and the tag of the produced image**.
```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/supply-chain/host/{{ session_namespace }}/product-service
```
It also shows the reason for an image build. In this case, it's due to our configuration change. As mentioned, image builds can also be triggered if new operating system or buildpack versions are available.
This shows the benefit of Cartographer's asynchronous behavior.


####  Factor 11: Logs

Factor eleven defines that **Logs should be treated as event streams**.
The key point with logs in a cloud-native application is that it writes all of its log entries to stdout and stderr and the aggregation, processing, and storage of logs is a nonfunctional requirement that is satisfied by your platform or cloud provider.

For developers, TAP-GUI also provides the capability to view the logs of your application.
**TODO: FIX url**
```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/supply-chain/host/{{ session_namespace }}/product-service
```
####  Factor 12: Admin processes

The final factor states that administrative tasks, such as database migrations and one-time scripts, should be executed in the same environment and manner as regular application code. 
This factor is a bit outdated. You should avoid administrative processes as much as possible for security reasons and try to find a design/architecture that suits your needs better.

**Factors eight and nine will be covered in the next section**.