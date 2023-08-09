# Backing Services

A lot of challenges can be mitigated with the help of Spring Boot and Cloud, but regarding the deployment,
there is for example still a high effort to manage the cloud infrastructure for the microservice.

For our typical Spring Cloud architecture the following backing services are required:

* A Postgres database for storing orders
* A RabbitMQ messaging systems for asynchronous messaging between the order and product service
* A caching solution like Redis or Gemfire for caching of relational database and rest calls from the order service
* Spring Configuration Server
* OAuth 2 Authorization Server
* Spring Cloud Gateway
* A solution like Zipkin or VMware Aria Operations for Applications to provide distributed tracing capabilities


