Before we have a closer look at the challenges of our typical microservice application, let's **implement** one of the services from scratch - in this case the **product service**.

The easiest way to get started you're probably familiar with is visiting [start.spring.io](https://start.spring.io), select your Spring Boot version and the dependencies you want to use.

Inspired by the Spring Initializr, **Application Accelerators for VMware Tanzu** enables developers to create new applications based on templates implemented in any technology that follow enterprise standards of your organization. This accelerates how you go from idea to production with ready-made, enterprise-conformant code and configurations without needing to read tons of docs straight away.

By clicking on the below link, you will open the IDE plugin to see a list of Accelerators available.
```editor:execute-command
command: workbench.view.extension.tanzu-app-accelerator
```

Select the **Spring Microservice** accelerator from the list, and change the following values in the form:
- **Name:** `product-service`
- **Git base url:** `{{ ENV_GITEA_BASE_URL}}/product-service.git`
- **Git branch:** `{{ session_namespace }}`
- **Deployment namespace:** `{{ session_namespace }}`
Press **Continue** until you see **Generate Project**. When you click on **Generate Project** (Click **OK** at the pop-up window), a new tab will open. The Accelerator has now generated the code in a new tab. We can close the tab and continue to work on the IDE integrated into the workshop UI.


```editor:open-file
file: product-service/src/main/java/com/example/productservice/Application.java
```

The next step is to push the code to a Git repository to collaborate with your team members on it. 
```terminal:execute
command: cd product-service && git init -b {{ session_namespace }} && git remote add origin {{ ENV_GITEA_BASE_URL}}/product-service.git && git add . && git commit -m "Initial implementation" && git push -u origin {{ session_namespace }} && cd ..
clear: true
```

**TODO: Automate much of the stuff via educates instructions** to get to https://github.com/timosalm/spring-cloud-demo-tap/tree/main/product-service/src/main/java/com/example/productservice without e.g. @RefreshScope and advanced security configuration.

**TODO: Use VSCode Tanzu Plugin for iterate and debug**

After the basic implementation of our product service, we will now configure a continuous path to production.