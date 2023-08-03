To handle the more complex deployment and operations of modern applications, there is a need for a culture change towards **DevSecOps**, a buzzword for improved collaboration between developers, security, and operations teams.
This collaboration should be **supported by automated processes**, like a self-service for developers to get access to the tools they need.

The automated process of testing and deploying applications into production is called **Continuous Integration** and **Continuous Delivery** (CI/CD). 

The CI/CD tools universe is always in flux, but most solutions pose the same challenges. They use for example an **orchestration model** where the orchestrator executes, monitors, and manages each of the steps of the path to production **synchronously**, and **each of the applications has a different path to production**.

VMware Tanzu Application Platform uses the open-source [Cartographer](https://cartographer.sh) that allows developers to focus on delivering value to their users and provides operators the assurance that all code in production has passed through all the steps of a pre-approved path to production.

Cartographer allows operators via the **Supply Chain** abstraction to define all of the steps that an application must go through in a path to production, like container image creation or CVE scanning.

By design, **a supply chain can be used by many workloads of a specific type**, like any web application. 
![Reusable CI/CD](../images/reusable-cicd.png)

VMware Tanzu Application Platform provides **full integration of all of its components via out-of-the-box supply chains** that can be customized for your processes and tools.

While the supply chain is operator-facing, Cartographer also provides an **interface for developers** called **Workload**. Workloads allow developers to create application specifications such as the location of their repository, environment variables, and service claims.

Let's have a closer look at how a Workload allows developers to configure the continuous path to production.
```editor:open-file
file: ~/product-service/config/workload.yaml
```

In addition to the name of the Workload, there is also `app.kubernetes.io/part-of` label with the same value, which is used by for example the TAP GUI to match documentation with runtime resources.

The location of an application's source code can be configured via the `spec.source` field. Here, we are using a branch of a Git repository as a source to be able to implement a **continuous path to production** where every git commit to the codebase will trigger another execution of the supply chain, and developers only have to apply a Workload once if they start with a new application or microservice. 
For the to-be-deployed application, the Workload custom resource also provides configuration options for a **pre-built image in a registry** from e.g. an ISV via `spec.image`.

Other configuration options are available for resource constraints (`spec.limits`, `spec.requests`) and environment variables for the build resources in the supply chain (`spec.build.env`) and to be passed to the running application (`spec.env`).

Last but not least, via (`.spec.params`), it's possible to override default values of the additional parameters that are used in the Supply Chain but not part of the official Workload specification.

There are more configuration options available which you can have a look at in the detailed specification here:
```dashboard:open-url
url: https://cartographer.sh/docs/v0.7.0/reference/workload/
```

If developers have access to a namespace in the Kubernetes cluster the supply chain is available, they can use the **tanzu CLI** as a higher abstraction to apply a Workload. Using **GitOps** to apply the Workload has the benefit that **developers don't need access to the Kubernetes cluster**.
As we have Kuberetens access from the workshop environment, let's apply our configuration via the tanzu CLI.
```execute
tanzu apps workload create -f product-service/config/workload.yaml -y
```

We can monitor the supply chain for the `product-service` in the terminal by using the `tanzu apps workload tail` command.
```terminal:execute
session: 2
command: |
  tanzu apps workload tail product-service --since 1h
```

In addiiton to monitoring the supply chain in the terminal we can also monitor in the TAP GUI.
```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/supply-chain/host/{{ session_namespace }}/product-service
```
After the supply chain completes you will see the logs of the `product-service` application stream to the terminal and you will see the Delivery step marked as completed in the TAP GUI.

![Delivery TAP GUI](../images/delivery-tap-gui.png)

We can also check the status of the workload using the `tanzu apps workload get` command.

```terminal:execute
command: |
  tanzu apps workload get product-service
```

At this point the application is up and running so we can test it out by making a request to the `/api/v1/products` endpoint.

```terminal:execute
command: |
  curl -s http://product-service.{{ session_namespace }}.{{ ENV_TAP_INGRESS }}/api/v1/products | jq .
```

When you execute the `curl` command you should see the following response

```
[
  {
    "id": 1,
    "name": "VMware Tanzu Application Platform"
  }
]
```

If you are still tailing the logs from the `product-service` you will also notice there is an `INFO` level log that gets printed indicating that fetch products was called

```
product-service-00001-deployment-57bb88c6f7-xn42x[workload] 2023-08-03T15:56:28.015314355Z 2023-08-03T15:56:28.014Z  INFO 1 --- [nio-8080-exec-9] c.e.p.product.ProductApplicationService  : Fetch products called
```

Lets stop tailing the logs from the `product-service` and move on to the next step of the workshop.

```terminal:interrupt
session: 2
```
