Created in 2012, the **12-factor app methodology provides a well-defined framework for developing modern microservices and helps us to identify challenges we may face**.

```dashboard:create-dashboard
name: The Twelve Factors
url: https://{{ session_namespace }}-twelve-factors.{{ ingress_domain }}#the_twelve_factors
```

We will now have a look at the factors that are relevant for the implementation of our application and the solution Spring provides for them.

#### Factor 1: Codebase
The code of our sample **application is already tracked in revision control**, as suggested. Some of you may prefer to use a mono-repository for the microservices, which has the benefit that everything is in one place. For your real-world microservices application, it could be a sign that you've chosen the wrong architecture, and a modular monolith could be a better choice.
```dashboard:open-url
url: {{ ENV_GITEA_BASE_URL }}/order-service/src/{{ session_namespace }}
```

#### Factor 2: Dependencies
For the second factor, **Maven and Gradle** are two of the most popular tools in the Java world that allow us to **declare dependencies** and let the tool be responsible for ensuring that those dependencies are satisfied. The sample application is using Maven, but it should be easy for you to switch to Gradle if you prefer it.
```editor:open-file
file: ~/order-service/pom.xml
line: 34
```

