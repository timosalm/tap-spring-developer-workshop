```dashboard:open-dashboard
name: The Twelve Factors
```

**TODO: Use Shipping service for example. Due to build time, already deploy something beforehand**

**Factor eight**, concurrency, advises us that **cloud-native applications should scale out using the process model**. There was a time when, if an application reached the limit of its capacity, the solution was adding CPUs, RAM, and other resources (virtual or physical), which is called **vertical scaling**.

A much more **modern approach**, one ideal for the kind of elastic scalability that the cloud supports, is to **scale out, or horizontally** where you create multiple instances of your application, and then distribute the load among those.
As you already learned, **VMware Tanzu Application Platform provides horizontal auto-scaling capabilities via Knative**.

By executing the following two commands. You should be able to see how the number of pods will be scaled up based on the generated traffic with the `hey` tool.
```execute-2
watch kubectl get pods
```
**TODO: Adjust parameters / automatically terminate to not overload the cluster**
```terminal:execute
command: hey -z 60s -c 1000 -m GET https://product-service-{{session_namespace}}.{{ ENV_TAP_INGRESS }}
clear: true
```
Exit both commands with `ctrl + c` and take a closer look at the CPU and memory consumption of the `user-container` and remember them for later reference.
```terminal:execute
command: kubectl top pods -l app=product-service-00001 --containers
clear: true
```

**Disposability is the ninth of the original 12 factors**.
A cloud-native **application’s processes** are disposable, which means they **can be started or stopped rapidly**. An application cannot scale, deploy, release, or recover rapidly if it cannot start rapidly and shut down gracefully. 

If we have a look at the application's logs, we can see how long it took until the application was started. Remember this number as a reference for later.
```terminal:execute
command: kubectl logs -l app=product-service-00001 -c user-container | grep "Started ProductServiceApplication"
clear: true
```

Let’s find out how you can **improve both, the startup time and resource consumption to reduce costs and maximize robustness of our application!**

###### Just-in-Time vs Ahead-of-Time compilation
In **traditional** Java applications, **Java code is compiled into Java ‘bytecode’** and packaged into a JAR archive. The Java Virtual Machine **(JVM) then executes the Java program** contained in the Java Archive on the host platform **with a bytecode interpreter**. 

The **execution of Java bytecode by an interpreter is always slower** than the execution of the **same program compiled into a native machine language**. This problem is mitigated by **just-in-time (JIT) compilers**. 

A JIT compiler **translates Java bytecode into native machine language while executing the program for parts of a program that are frequently executed**. The translated parts of the program can then be **executed much faster**. This way a **JIT compiler can significantly speed up the overall execution time**. 

The **downside** is that the JIT compilation **impacts the application startup time** and a Java program running on a Java Virtual Machine is always **more resource consuming than native execution**. 

With **ahead-of-time compilation** of the Java code to a standalone executable, called a **native image**, you are able to mitigate these problems and make your **application start faster and consume fewer resources**.

![](../images/jit-vs-aot.png)

###### What are native images?
- Standalone executable of ahead-of-time compiled Java code
- Includes the application classes, classes from its dependencies, runtime library classes, and statically linked native code from JDK
- Runs without the need of a JVM, necessary components like for memory management, thread scheduling, and so on are included in a runtime system, called “Substrate VM” 
- Specific to the OS and machine architecture for which it was compiled
- Requires fewer resources, is smaller, and faster than regular Java applications running on a JVM

The only way to do this at present is to use **GraalVM**, but in the future, similar technology may be available, like the OpenJDK Project Leyden. 

##### GraalVM - A high-performance JDK distribution
GraalVM is a high-performance JDK distribution by Oracle designed to **execute applications written in Java and other JVM languages** while **also providing runtimes for JavaScript, Ruby, Python, and a number of other popular languages**, which is made possible by **GraalVM’s Truffle language implementation framework**.

GraalVM **adds an advanced just-in-time (JIT) optimizing compiler**, which is written in Java, to the HotSpot Java Virtual Machine.

GraalVM offers **three runtime modes**:
- JVM runtime mode
- Native image 
- Java on Truffle for those none JVM languages

![](../images/graalvm.png)

##### Tradeoffs between JVM and native images
**Native images** are able to **improve both, the startup time and resource consumption** for your applications deployed on a serverless runtime, but you have to keep in mind that there are some trade-offs compared to the JVM.

They **offer lower throughput and higher latency** because they can’t optimize hot paths during runtime as much as the JVM can. 
The **compilation takes much longer and consumes more resources**, which is bad for developer productivity. 
Finally, the **platform is also less mature**, but it evolves and improves quickly.

![](../images/graalvm-tradeoffs.png)

For GraalVM native images, all the bytecode in the application needs to be **observed** and **analyzed** at **build time**.

One area the analysis process is responsible for is to determine which classes, methods and fields need to be included in the executable. The **analysis is static**, so it might need some configuration to correctly include the parts of the program that use dynamic features of the language.

However, this analysis cannot always completely predict all usages of the **Java Reflection, Java Native Interface (JNI), Dynamic Proxy objects (java.lang.reflect.Proxy)**, or **classpath** resources (**Class.getResource)**. 

**Undetected usages of these dynamic features need to be provided to the native-image tool in the form of configuration files.**

To **make preparing these configuration files easier** and more convenient, GraalVM provides an **agent that tracks all usages of dynamic features of execution on a regular Java VM**. 
During execution, the agent interfaces with the Java VM to intercept all calls that look up classes, methods, fields, resources, or request proxy accesses.

##### Spring Boot's GraalVM Native Image Support

**Spring Boot 3 added support for compiling Spring applications to lightweight native images using the GraalVM native-image compiler.**

Spring Boot applications are typically dynamic and configuration is performed at runtime, but when creating native images with GraalVM, **a closed-world approach is used to retain static analysis benefits**. This means implies the following restrictions:
- **The classpath is fixed and fully defined at build time**
- The **beans defined in your application cannot change at runtime**. So the `@Profile` annotation, profile-specific configuration, and Properties that change if a bean is created are not supported

When these restrictions are in place, it becomes possible for Spring to perform ahead-of-time processing during build-time and generate additional assets that GraalVM can use. 

You can **get started** very **easily by using start.spring.io to create a new project**.

The `spring-boot-starter-parent` declares a native profile that configures the executions that need to run to create a native image. You can activate profiles using the `-P` flag on the command line.

Spring Boot includes buildpack support for native images directly for both Maven and Gradle. The resulting image doesn’t contain a JVM, which leads to smaller images.

For the second option to build your native image, the `native-maven-plugin` was added to our pom file to be able to invoke the native image compiler from your build.

Let's now see how the product service **performs as a native image on a Serverless runtime**!

The startup time is dramatically reduced compared to the same application running on the JVM ...
```terminal:execute
command: kubectl logs -l app=spring-boot-hello-world-native-00001 -c user-container | grep "Started HelloWorldApplication"
clear: true
```

... and we can also check how fast the number of pods will be scaled up.
```execute-2
watch kubectl get pods
```
```terminal:execute
command: hey -z 60s -c 1000 -m GET https://product-service-native-{{session_namespace}}.{{ ENV_TAP_INGRESS }}
clear: true
```

The memory and CPU consumption of the `user-container` is also reduced.
```terminal:execute
command: kubectl top pods -l app=product-service-native-00001 --containers
clear: true
```

To provide the configuration to the native-image tool that is needed for the undetected usages of dynamic language features with Spring Boot, there is a `RuntimeHints API`.
It collects the need for reflection, resource loading, serialization, and JDK proxies at runtime. 
Several contracts are handled automatically during AOT processing. For cases that the **core container cannot infer**, you can **register such hints programmatically** by implementing the `RuntimeHintsRegistrar` interface. Implementations of this interface can be registered using `@ImportRuntimeHints` on any Spring bean or @Bean factory method.

If you have **classes that need binding** (mostly needed when serializing or deserializing JSON), most of the hints are automatically inferred, for example when accepting or returning data from a @RestController method. But when you work with WebClient or RestTemplate directly, you might need to use [@RegisterReflectionForBinding](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/aot/hint/annotation/RegisterReflectionForBinding.html) annotation.

VMware Tanzu offers Enterprise Support for Spring Boot Native Applications compiled with the BellSoft Liberica native image Kit which is based on GraalVM Open Source.

###### A future solution: JVM Checkpoint Restore

Spring Framework 6.1 M1 integrates with checkpoint/restore as implemented by [Project CRaC](https://openjdk.org/projects/crac/) to reduce the startup and warmup times of Spring-based Java applications with the JVM. The CRaC (Coordinated Restore at Checkpoint) project researches coordination of Java programs with mechanisms to checkpoint (make an image of, snapshot) a Java instance while it is executing and restoring it.