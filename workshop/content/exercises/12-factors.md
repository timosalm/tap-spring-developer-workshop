Created in 2012, the **12-factor app methodology provides a well-defined framework for developing modern microservices and helps us to identify challenges we may face**.

```dashboard:create-dashboard
name: The Twelve Factors
url: https://{{ session_namespace }}-twelve-factors.{{ ingress_domain }}#the_twelve_factors
autostart: true
hidden: true
```

We will now have a look at the factors that are relevant for the implementation of our application and the solution Spring provides for them.

#### Factor 1: Codebase
The code of our sample **application is already tracked in source control**.

The source code for the product service can be found here.
```dashboard:reload-dashboard
name: GIT UI
url: {{ ingress_protocol }}://git-ui-{{ session_name }}.{{ ingress_domain }}?p=product-service.git;a=tree
```

#### Factor 2: Dependencies
**Maven and Gradle** are two of the most popular tools in the Java ecosystem that allow us to **declare and manage dependencies**. As we have already seen, the product service is using Maven.

```editor:open-file
file: ~/product-service/pom.xml
line: 34
```

