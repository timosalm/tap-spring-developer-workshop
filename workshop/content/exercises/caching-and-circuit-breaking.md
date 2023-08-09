The **fourth and sixth factor** implies that any **data** that needs to be persisted must be **stored in a stateful backing service**, such as a database because the processes are stateless and share-nothing.
A backing service is any service that your application needs for its functionality. Examples of the different types of backing services are data stores, messaging systems, and also services that provide business functionality.

Those backing services are handled as attached resources in a 12-factor app which can be swapped without changing the application code in case of failures.

##### Provisioning and consumption of backing services

TAP makes it easy as possible to discover, curate, consume, and manage backing services, such as databases, queues, and caches, across single or multi-cluster environments. 

This experience is made possible by using the **Services Toolkit** component. 

To demonstrate how a Spring Boot app can use backing services on TAP lets use the order-service.

![Order Microservice](../images/microservice-architecture-cache.png)

To modify the order service to use services on TAP lets first import it into our IDE's workshpace.

Open the Explorer view in the IDE.

```editor:execute-command
command: workbench.view.explorer
```
