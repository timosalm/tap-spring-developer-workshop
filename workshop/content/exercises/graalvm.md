**Factor eight**, concurrency, advises us that **cloud-native applications should scale out using the process model**. There was a time when, if an application reached the limit of its capacity, the solution was adding CPUs, RAM, and other resources (virtual or physical), which is called **vertical scaling**.

A much more **modern approach**, one ideal for the kind of elastic scalability that the cloud supports, is to **scale out, or horizontally** where you create multiple instances of your application, and then distribute the load among those.
As you already learned, **VMware Tanzu Application Platform provides horizontal auto-scaling capabilities via Knative**.

**Disposability is the ninth of the original 12 factors**.
A cloud-native **application’s processes** are disposable, which means they **can be started or stopped rapidly**. An application cannot scale, deploy, release, or recover rapidly if it cannot start rapidly and shut down gracefully. 

**TODO: Add all about GraalVM and maybe a short notice about CRaC. Use Shipping service for example**
