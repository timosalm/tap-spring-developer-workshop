Created in 2012, the **12-factor app methodology provides a well-defined framework for developing modern microservices and helps us to identify challenges we may face**.

```dashboard:create-dashboard
name: The Twelve Factors
url: https://{{ session_namespace }}-twelve-factors.{{ ingress_domain }}#the_twelve_factors
```

We will now have a look at the factors that are relevant for the implementation of our application, and the solution Spring provides for them.

Regarding the **first factor**, you may recognize that the code for our sample **application is tracked in revision control** as suggested, but we used a mono-repository for the microservices which has the benefit that everything is in one place. For your real-world microservices application, it could be a sign that you've chosen the wrong architecture and a modular monolith could be a better choice.

For the **second factor**, **Maven and Gradle** are two of the most popular tools in the Java world that allow us to **declare dependencies** and let the tool be responsible for ensuring that those dependencies are satisfied. 

The **third factor** is about the **separation of configuration from code**. The reason for that is, that configuration can be significantly different across environments but the code is the same.





