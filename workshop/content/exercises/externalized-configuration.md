In cloud-native applications, configuration shouldn't be bundled with code!
In the cloud, you have multiple applications, environments, and service instances — so configuration has to be flexible.

[Spring Cloud Config](https://docs.spring.io/spring-cloud-config/docs/current/reference/html/) is designed to ease this burden by providing server-side and client-side support for externalized configuration in a distributed system. 
With the **Spring Cloud Config Server**, you have a central place to manage external properties for applications across all environments by integrating multiple version control systems to keep your config safe.

Part of TAP is the commercial **Application Configuration Service for VMware Tanzu** which is based on the OSS Spring Cloud Config Server and  provides a Kubernetes-native experience to enable the runtime configuration.

**TODO: Configure Configuration Sources e.g. via Crossplane, Add related stuff to product-service incl. RefreshScope: https://github.com/timosalm/spring-cloud-demo-tap/tree/main/product-service**

![Updated architecture with Configuration Service](../images/microservice-architecture-config.png)
