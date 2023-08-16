```dashboard:open-dashboard
name: The Twelve Factors
```

####  Factor 8: Concurrency
**Factor eight**, concurrency, advises us that **cloud-native applications should scale out using the process model**. There was a time when, if an application reached the limit of its capacity, the solution was adding CPUs, RAM, and other resources (virtual or physical), which is called **vertical scaling**.

A much more **modern approach**, one ideal for the kind of elastic scalability that the cloud supports, is to **scale horizontally**, where you create multiple instances of your application and then distribute the load among those instances.
TAP includes a serverless application runtime for Kubernetes, which provides **configurable horizontal auto-scaling** and **scale-to-zero** functionality called **Knative**.

```dashboard:open-url
url: https://knative.dev/docs/
```

The major **subprojects of Knative** are Serving and Eventing.
- **Serving** supports deploying upgrading, routing, and scaling of stateless applications and functions
- **Eventing** enables developers to use an event-driven architecture with serverless applications and is **out of the scope of this workshop**
- **Functions**: Enables developers to easily create, build, and deploy stateless, event-driven functions

Knative Serving abstracts away a lot of the Kubernetes resources, like a deployment, service, ingress, etc., we usually have to configure to get an application running on Kubernetes.
In addition to auto-scaling, it offers features like rollbacks, canary and blue-green deployment via revisions, and traffic splitting.
For this workshop though, we will just focus on the scaling feature Knative provides.

By executing the following two commands, you should be able to see how the number of pods will be scaled up based on the generated traffic with the `hey` tool.
```execute-2
watch kubectl get pods -l serving.knative.dev/service=product-service
```
```terminal:execute
command: hey -n 1000 -c 1000 -m GET https://product-service-{{session_namespace}}.{{ ENV_TAP_INGRESS }}/api/v1/products
clear: true
```

Have a closer look at the CPU and memory consumption of the **`workload` container** and remember them for later reference.
```terminal:execute
command: kubectl top pods -l serving.knative.dev/service=product-service --containers
clear: true
```
You will see something similar to these results.

{% raw %}
```
$ kubectl top pods -l serving.knative.dev/service=product-service --containers
POD                                                NAME          CPU(cores)   MEMORY(bytes)   
product-service-00001-deployment-f686bb89f-fc54w   queue-proxy   37m          41Mi            
product-service-00001-deployment-f686bb89f-fc54w   workload      2m           263Mi
```
{% endraw %}

####  Factor 9: Disposability
Cloud-native applications are disposable, which means they **can be started or stopped rapidly**. An application cannot scale, deploy, release, or recover rapidly if it cannot start rapidly and shut down gracefully. 

If we have a look at the application's logs, we can see how long it took our application to start. Remember this number as a reference for later.
```terminal:execute
command: kubectl logs -l serving.knative.dev/service=product-service -c workload | grep "Started"
clear: true
```
You will see something similar to this.

{% raw %}
```
$ kubectl logs -l serving.knative.dev/service=product-service -c workload | grep "Started"
2023-08-14T19:08:47.891Z  INFO 1 --- [           main] com.example.productservice.Application   : Started Application in 3.357 seconds (process running for 3.771)
````
{% endraw %}

In the case where you may scale your apps rapidly and run hundreds of applications, startup time and compute resources become a concern. If an application starts slowly, it might mean your app cannot scale fast enough to handle a sudden increase in demand, and if it consumes a lot of resources (memory, CPU, etc) and scales to a large degree, that means increased cost.

Making sure we can optimize both performance (start time) and resource consumption can be a game changer in the cloud. 
Let's see how Spring solves this problem for you!

##### Just-in-Time vs Ahead-of-Time compilation
In **traditional** Java applications, **Java code is compiled into Java ‘bytecode’** and packaged into a JAR archive. The Java Virtual Machine **(JVM) then executes the Java program** contained in the Java Archive on the host platform **with a bytecode interpreter**. 

The **execution of Java bytecode by an interpreter is always slower** than the execution of the **same program compiled into a native machine language**. This problem is mitigated by **just-in-time (JIT) compilers**. 

A JIT compiler **translates Java bytecode into native machine language while executing the program for parts of a program that are frequently executed**. The translated parts of the program can then be **executed much faster**. This way, a **JIT compiler can significantly speed up the overall execution time**. 

The **downside** is that the JIT compilation **impacts the application startup time**, and a Java program running on a Java Virtual Machine is always **more resource-consuming than native execution**. 

With the **ahead-of-time compilation** of the Java code to a standalone executable, called a **native image**, you are able to mitigate these problems and make your **application start faster and consume fewer resources**.

![](../images/jit-vs-aot.png)

###### What are native images?
- Standalone executables of ahead-of-time compiled Java code
- Includes the application classes, classes from its dependencies, runtime library classes, and statically linked native code from JDK
- Runs without the need for a JVM, necessary components like for memory management, thread scheduling, and so on are included in a runtime system called "Substrate VM" 
- Specific to the OS and machine architecture for which it was compiled
- Requires fewer resources, is smaller, and faster than regular Java applications running on a JVM

The only way to do this at present is to use **GraalVM**, but in the future, similar technology may be available, like the OpenJDK Project Leyden. 

##### GraalVM - A high-performance JDK distribution
GraalVM is a high-performance JDK distribution by Oracle designed to **execute applications written in Java and other JVM languages** while **also providing runtimes for JavaScript, Ruby, Python, and a number of other popular languages**, which is made possible by **GraalVM's Truffle language implementation framework**.

GraalVM **adds an advanced just-in-time (JIT) optimizing compiler**, which is written in Java, to the HotSpot Java Virtual Machine.

GraalVM offers **three runtime modes**:
- JVM runtime mode
- Native image 
- Java on Truffle for those none JVM languages

![](../images/graalvm.png)

##### Tradeoffs between JVM and native images
**Native images** are able to **improve both the startup time and resource consumption** for your applications deployed on a serverless runtime, but you have to keep in mind that there are some trade-offs compared to the JVM.

They **offer lower throughput and higher latency** because they can't optimize hot paths during runtime as much as the JVM can. 
The **compilation takes much longer and consumes more resources**, which is bad for developer productivity. 
Finally, the **platform is also less mature**, but it evolves and improves quickly.

![](../images/graalvm-tradeoffs.png)

For GraalVM native images, all the bytecode in the application needs to be **observed** and **analyzed** at **build time**.

One area the analysis process is responsible for is determining which classes, methods, and fields need to be included in the executable. The **analysis is static**, so it might need some configuration to correctly include the parts of the program that use dynamic features of the language.

However, this analysis cannot always completely predict all usages of the **Java Reflection, Java Native Interface (JNI), Dynamic Proxy objects (java.lang.reflect.Proxy)**, or **classpath** resources (**Class.getResource)**. 

**Undetected usages of these dynamic features need to be provided to the native-image tool in the form of configuration files.**

To **make preparing these configuration files easier** and more convenient, GraalVM provides an **agent that tracks all usages of dynamic features of execution on a regular Java VM**. 
During execution, the agent interfaces with the Java VM to intercept all calls that look up classes, methods, fields, resources, or request proxy accesses.

##### Spring Boot's GraalVM Native Image Support

**Spring Boot 3 added support for compiling Spring applications to lightweight native images using the GraalVM native-image compiler.**

Spring Boot applications are typically dynamic, and configuration is performed at runtime, but when creating native images with GraalVM, **a closed-world approach is used to retain static analysis benefits**. This means implies the following restrictions:
- **The classpath is fixed and fully defined at build time**
- The **beans defined in your application cannot change at runtime**. So the `@Profile` annotation, profile-specific configuration, and Properties that change if a bean is created are not supported

When these restrictions are in place, it becomes possible for Spring to perform ahead-of-time processing during build-time and generate additional assets that GraalVM can use. 

You can **get started** very **easily by using start.spring.io to create a new project**.

The `spring-boot-starter-parent` declares a `native` profile that configures the executions that need to run to create a native image. You can activate profiles using the `-P` flag on the command line.

Spring Boot includes buildpack support for native images directly for both Maven and Gradle. The resulting image doesn't contain a JVM, which leads to smaller images.
```
./mvnw spring-boot:build-image -Dspring-boot.build-image.imageName=myorg/myapp -Pnative
./gradlew bootBuildImage --imageName=myorg/myapp -Pnative
```

For the second option to build your native image, the `native-maven-plugin` was added to our pom file to be able to invoke the native image compiler from your build.

Let's now see how the product service **performs as a native image on a Serverless runtime**! 
As you learned, the compilation of native images takes much longer and consumes more resources. Therefore, it's already done for you, and the application is running in your cluster.

Execute both commands to check how fast the number of pods will be scaled up.
```terminal:interrupt-all
```
```execute-2
watch kubectl get pods -l serving.knative.dev/service=product-service-native
```
```terminal:execute
command: hey -n 1000 -c 1000 -m GET https://product-service-native-{{session_namespace}}.{{ ENV_TAP_INGRESS }}/api/v1/products
clear: true
```

The startup time is dramatically reduced compared to the same application running on the JVM ...
```terminal:execute
command: kubectl logs -l serving.knative.dev/service=product-service-native -c workload | grep "Started"
clear: true
```
You will see something similar to this.

{% raw %}
```
$ kubectl logs -l serving.knative.dev/service=product-service-native -c workload | grep "Started"
2023-08-14T16:04:44.452Z  INFO 1 --- [           main] com.example.productservice.Application   : Started Application in 0.276 seconds (process running for 0.281)
2023-08-14T16:04:42.362Z  INFO 1 --- [           main] com.example.productservice.Application   : Started Application in 0.339 seconds (process running for 0.343)
2023-08-14T16:04:44.342Z  INFO 1 --- [           main] com.example.productservice.Application   : Started Application in 0.259 seconds (process running for 0.264)
2023-08-14T16:04:44.239Z  INFO 1 --- [           main] com.example.productservice.Application   : Started Application in 0.274 seconds (process running for 0.278)
2023-08-14T16:04:44.188Z  INFO 1 --- [           main] com.example.productservice.Application   : Started Application in 0.254 seconds (process running for 0.261)
2023-08-14T16:04:44.205Z  INFO 1 --- [           main] com.example.productservice.Application   : Started Application in 0.239 seconds (process running for 0.244)
2023-08-14T16:04:44.507Z  INFO 1 --- [           main] com.example.productservice.Application   : Started Application in 0.227 seconds (process running for 0.231)
```
{% endraw %}

... and the memory and CPU consumption of the `workload` is also reduced.
```terminal:execute
command: kubectl top pods -l serving.knative.dev/service=product-service-native --containers
clear: true
```

You will see something similar to this.

{% raw %}
```
$ kubectl top pods -l serving.knative.dev/service=product-service-native --containers
POD                                                        NAME          CPU(cores)   MEMORY(bytes)   
product-service-native-00003-deployment-6469688668-5slj6   queue-proxy   1m           5Mi             
product-service-native-00003-deployment-6469688668-5slj6   workload      1m           60Mi            
product-service-native-00003-deployment-6469688668-6x4z8   queue-proxy   1m           6Mi             
product-service-native-00003-deployment-6469688668-6x4z8   workload      1m           60Mi            
product-service-native-00003-deployment-6469688668-gmk5b   queue-proxy   1m           65Mi            
product-service-native-00003-deployment-6469688668-gmk5b   workload      1m           145Mi           
product-service-native-00003-deployment-6469688668-jfs77   queue-proxy   1m           5Mi             
product-service-native-00003-deployment-6469688668-jfs77   workload      1m           60Mi            
product-service-native-00003-deployment-6469688668-mcx6s   queue-proxy   1m           5Mi             
product-service-native-00003-deployment-6469688668-mcx6s   workload      1m           60Mi            
product-service-native-00003-deployment-6469688668-pkt5q   queue-proxy   1m           5Mi             
product-service-native-00003-deployment-6469688668-pkt5q   workload      1m           60Mi            
product-service-native-00003-deployment-6469688668-sngnx   queue-proxy   1m           6Mi             
product-service-native-00003-deployment-6469688668-sngnx   workload      1m           60Mi            
product-service-native-00003-deployment-6469688668-vw7s5   queue-proxy   1m           5Mi             
product-service-native-00003-deployment-6469688668-vw7s5   workload      1m           60Mi  
```
{% endraw %}

Notice the drastic reduction in start time compared to the non-native product service.

To provide the configuration to the native-image tool that is needed for the undetected usages of dynamic language features with Spring Boot, there is a `RuntimeHints API`.
It collects the need for reflection, resource loading, serialization, and JDK proxies at runtime. 
Several contracts are handled automatically during AOT processing. For cases that the **core container cannot infer**, you can **register such hints programmatically** by implementing the `RuntimeHintsRegistrar` interface. Implementations of this interface can be registered using `@ImportRuntimeHints` on any Spring bean or @Bean factory method.

If you have **classes that need binding** (mostly needed when serializing or deserializing JSON), most of the hints are automatically inferred, for example when accepting or returning data from a @RestController method. But when you work with WebClient or RestTemplate directly, you might need to use [@RegisterReflectionForBinding](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/aot/hint/annotation/RegisterReflectionForBinding.html) annotation.

VMware Tanzu offers Enterprise Support for Spring Boot Native Applications compiled with the BellSoft Liberica native image Kit which is based on GraalVM Open Source.

###### A future solution: JVM Checkpoint Restore

Spring Framework 6.1 M1 integrates with checkpoint/restore as implemented by [Project CRaC](https://openjdk.org/projects/crac/) to reduce the startup and warmup times of Spring-based Java applications with the JVM. The CRaC (Coordinated Restore at Checkpoint) project researches the coordination of Java programs with mechanisms to checkpoint (make an image of, snapshot) a Java instance while it is executing and restoring it.
