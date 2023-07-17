```dashboard:open-dashboard
name: The Twelve Factors
```
The **fifth factor** calls for the **strict separation between the build, release, and run stages**. 
As you already saw, the **out-of-the-box supply chains of VMware Tanzu Application Platform** and Cartographer are designed to **fulfill this best-practice**.

##### Service Registration and Discovery

A note regarding the **seventh factor** that **services need to be exposed for external or inter-service access with well-defined ports**. 

**Spring Cloud's Registry interface** solves this problem and provides client-side libraries for **service registry implementations such as Consul, Zookeeper, Eureka plus Kubernetes**.

In Kubernetes, each service can interface with another service by using its service name, which is **resolved by Kubernetes DNS support and the benefit of the Spring Cloud's Registry interface is limited**. 

**Due to even more capabilities like proper load balancing, we decided to use the Ingress Controller Contour which is part of TAP as a solution for the factor**.

![Updated architecture with Service Registry](../images/microservice-architecture-service-discovery.png)

##### Logs

Factor eleven defines that **Logs should be treated as event streams**.
The key point with logs in a cloud-native application is that it writes all of its log entries to stdout and stderr and the aggregation, processing, and storage of logs is a nonfunctional requirement that is satisfied by your platform or cloud provider.

For developers, TAP-GUI also provides the capabilities to view the logs of your application.
**TODO: FIX url**
```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/supply-chain/host/{{ session_namespace }}/product-service
```

**TODO: Factor 10+12**

The **factors eight and nine will be covered in the next section**.