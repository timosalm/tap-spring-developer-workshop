The API-first approach prioritizes the design and development of the application programming interface (API) before any other aspects of the application. 
This approach enables for example the consumers of an API to work more independently from its provider, and providers are able to facilitate discussions with stakeholders well before they might have coded themselves past the point of no return.

###### Discover API documentation and more in Tanzu Developer Portal

Tanzu Developer Portal helps you to find documentation for APIs available in your organization and try them out before integrating them in your applications.

A core feature of Tanzu Developer Portal and the Cloud Native Computing Foundation’s project [Backstage](https://backstage.io), on which it's based on, is the **Software Catalog**. A centralized system that keeps track of ownership and metadata for all the applications in your organization's ecosystem. The catalog is built around the concept of metadata YAML files stored together with the code, which are then harvested and visualized.
```dashboard:open-url
url: {{ ENV_GITEA_BASE_URL }}/product-service/catalog/component.yaml
```
```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/catalog
```

If you **switch the kind from "Component" to "System"** and select `sc-architecture-system` you can see lists of all the services, backing services, and also a graph visualizing their relationships defined by metadata YAML files.
```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/catalog/default/system/sc-architecture-system
```
In addition to a link to jump to the related source code, there is also one to access the **technical documentation** which can be written in Markdown format in a source-code repository and displayed alongside the relevant catalog entries.
```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/docs/default/System/sc-architecture-system
```

APIs provided by the components can be discovered via the **API documentation plug-in**. 
```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/catalog/default/api/gateway-{{ ENV_TAP_INGRESS }}/definition
```
With a feature called **API Auto Registration**, TAP can automatically register your APIs in Tanzu Developer Portal.

From the different components in the Software Catalog, you can also jump to the **Runtime Resources** view and have a closer look at the resources running on Kubernetes for your applications. If you select a Pod you're able to see the logs, and if it's running one of our services, also information provided by **App Live View**.
```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/catalog/default/component/product-service/workloads
```

###### API Gateway

With so many APIs in a microservices application, developers need an API Gateway that they can control!

[Spring Cloud Gateway](https://spring.io/projects/spring-cloud-gateway) is a **library that can be used to create an API gateway** to expose endpoints for application services written in any programming language.
It aims to provide a simple and effective way to route to APIs and provides features related to security and resiliency to them.

The best way to create a gateway for your microservices application with Spring Cloud Gateway from scratch is to go to [start.spring.io](https://start.spring.io), add the `spring-cloud-starter-gateway` dependency, and additional dependencies based on your needs for security, distributed tracing, externalized configuration etc.

The main building blocks of Spring Cloud Gateway are: 
- **Routes**: Defined by an ID, a destination URI, a collection of predicates, and a collection of filters.
- **Predicates**: Used for matching on anything from the HTTP request, such as headers or parameters.
- **Filters**: Used for modifications of requests and responses before or after sending the downstream request
Spring Cloud Gateway already provides Predicates and Filters for most of the common use cases, but it's also [possible to build your own](https://docs.spring.io/spring-cloud-gateway/docs/current/reference/html/#developer-guide).

Routes can be configured in a number of ways, like via the Java API provided by the Gateway, or configuration properties stored in a Git repository.

**VMware Spring Cloud Gateway for Kubernetes** is an **API gateway created for developers** based on the open-source Spring Cloud Gateway project, along with integrating other Spring ecosystem projects such as Spring Security, Spring Session, and more. It automates the deployment of an API gateway service via the [Kubernetes Operator](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/) pattern, and includes several other [commercial features](https://docs.vmware.com/en/VMware-Spring-Cloud-Gateway-for-Kubernetes/2.0/scg-k8s/GUID-index.html#key-features) like simple Single Sign-On (SSO) configuration, and OpenAPI version 3 documentation auto-generation.

![VMware Spring Cloud Gateway for Kubernetes](../images/scg-for-k8s.png)

First, we have to configure a gateway instance via the `SpringCloudGateway` Kubernetes custom resource.
```editor:append-lines-to-file
file: ~/config/gateway/gateway.yaml
text: |
  apiVersion: "tanzu.vmware.com/v1"
  kind: SpringCloudGateway
  metadata:
    name: api-gateway-1
  spec:
    api:
      serverUrl: https://gateway-{{ session_namespace }}.{{ ENV_TAP_INGRESS }}
    observability:
      tracing:
        zipkin:
          enabled: true
          url: http://zipkin:9411/api/v2/spans
```

Now it's time to define our route configuration with a `SpringCloudGatewayRouteConfig` custom resource.
```editor:append-lines-to-file
file: ~/config/gateway/gateway-route-config.yaml
text: |
  apiVersion: "tanzu.vmware.com/v1"
  kind: SpringCloudGatewayRouteConfig
  metadata:
    name: supply-chain-app-route-config
  spec:
    routes:
    - uri: http://product-service.{{ session_namespace }}
      predicates:
      - Path=/services/product-service/**
      filters:
      - StripPrefix=2
    - uri: http://order-service.{{ session_namespace }}
      predicates:
      - Path=/services/order-service/**
      filters:
      - StripPrefix=2
```

The last step is to link our route configuration to the gateway instance with a `SpringCloudGatewayMapping` custom resource, which allows using a route configuration with multiple gateway instances, and apply everything to the cluster.
```editor:append-lines-to-file
file: ~/config/gateway/gateway-route-mapping.yaml
text: |
  apiVersion: "tanzu.vmware.com/v1"
  kind: SpringCloudGatewayMapping
  metadata:
    name: supply-chain-app-routes
  spec:
    gatewayRef:
      name: api-gateway-1
    routeConfigRef:
      name: supply-chain-app-route-config
```
```terminal:execute
command: kubectl apply -f ~/config/gateway/
clear: true
```

Having the gateway as the single entry point to our application, we shouldn't expose the order and product service directly anymore. This can be done by setting the `networking.knative.dev/visibility: cluster-local` label on your Workloads. 

*Hint: Even if this also works with the default installation of TAP, for production a second ingress controller has to be configured with service type ClusterIP and configured in Knative, so that the services are really not reachable from the outside.*

We can now validate whether our configuration works by sending a request through it to the order service. 
```terminal:execute
command: |
  curl -X POST -H "Content-Type: application/json" -d '{"productId":"1", "shippingAddress": "Stuttgart"}' https://gateway-{{ session_namespace }}.{{ ENV_TAP_INGRESS }}/services/order-service/api/v1/orders
clear: true
```
We can also use ZipKin UI to see the new request flow.
```dashboard:open-url
url: https://zipkin-{{ session_namespace }}.{{ ENV_TAP_INGRESS }}
```

![Updated architecture with API Gateway](../images/microservice-architecture-gateway.png)