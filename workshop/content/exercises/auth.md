Security is a vital part of any application and cloud environment!
**OAuth 2 is an authorization framework** granting clients access to protected resources via an authorization server.
To make the application secure, you can simply add Spring Security as a dependency. **By adding the Spring Security OAuth 2 Client, it will secure your app with OAuth 2** by default.  However we need an OAuth 2 authorization server to use with the client application.

**Spring Authorization Server delivers OAuth 2 Authorization Server** support to the Spring community.

**Application Single Sign-On for VMware Tanzu** (commonly called AppSSO) is based on the Spring Authorization.  Our apps running on TAP can use AppSSO as an OAuth 2 authorization server.

To use AppSSO we first need to create an Authorization Server along with an RSAKey key for signing tokens. This AuthServer example uses an **unsafe testing-only identity provider which should never be used in production environments!** Information on how to configure external identity providers for real world use cases is available [here](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.6/tap/app-sso-how-to-guides-service-operators-identity-providers.html).

Execute the following commands to create the YAML files needed to deploy the AppSSO server and the RSAKey it needs.

```editor:append-lines-to-file
file: ~/config/auth/authserver.yaml
text: |
  apiVersion: "sso.apps.tanzu.vmware.com/v1alpha1"
  kind: AuthServer
  metadata:
    name: authserver-1
    labels:
      name: authserver-1
      namespace: {{ session_namespace }}
    annotations:
      sso.apps.tanzu.vmware.com/allow-client-namespaces: "{{ session_namespace }}"
      sso.apps.tanzu.vmware.com/allow-unsafe-identity-provider: ""
      sso.apps.tanzu.vmware.com/allow-unsafe-cors: ""
  spec:
    replicas: 1
    tls:
      issuerRef:
        name: tap-ingress-selfsigned
        kind: ClusterIssuer  
    identityProviders:
      - name: "internal"
        internalUnsafe:
          users:
            - username: "developer"
              password: "123456"
              email: "developer@example.com"
              emailVerified: true
              roles:
                - "user"
    tokenSignature:
      signAndVerifyKeyRef:
        name: "authserver-signing-key"
    cors:
      allowAllOrigins: true
  ---
  apiVersion: secretgen.k14s.io/v1alpha1
  kind: RSAKey
  metadata:
    name: authserver-signing-key
  spec:
    secretTemplate:
      type: Opaque
      stringData:
        key.pem: $(privateKey)
        pub.pem: $(publicKey)
```

The `metadata.labels` uniquely identify the AuthServer. They are used as selectors by `ClientRegistration`s, to declare from which authorization server a specific client obtains tokens.

The `sso.apps.tanzu.vmware.com/allow-client-namespaces` annotation restricts the namespaces in which you can create ClientRegistrations targeting this authorization server.

The `tokenSignature` references a private RSA key used to sign ID Tokens, using JSON Web Signatures. Clients use the public key to verify the provenance and integrity of the ID tokens. 

To request client credentials for the AuthServer, we have to configure a `ClientRegistration`.
Execute the following command to creat the YAML for our `ClientRegistration`.

```editor:append-lines-to-file
file: ~/config/auth/clientregistration.yaml
text: |
  apiVersion: sso.apps.tanzu.vmware.com/v1alpha1
  kind: ClientRegistration
  metadata:
    name: client-registration
    namespace: {{ session_namespace }}
  spec:
    authServerSelector:
      matchLabels:
        name: authserver-1
        namespace: {{ session_namespace }}
    redirectURIs:
    -  https://gateway-{{ session_namespace }}.{{ ENV_TAP_INGRESS }}/frontend/index.html
    clientAuthenticationMethod: none
    authorizationGrantTypes:
      - "client_credentials"
      - "authorization_code"
      - "refresh_token"
    scopes:
    - name: openid
    - name: offline_access
    - name: email
    - name: profile
    - name: roles
```
In `spec.authServerSelector`, a `ClientRegistration` will uniquely identify an AuthServer. 
The Redirect URLs defined in `redirectURIs` are a critical part of the OAuth flow. They define where the authorization server will redirect the user after successfully authorizing an application.

For this workshop, the redirect URL is targeting a **single-page app acting as an OAuth client** (which is already deployed for you).
After the single-page app has obtained an access token, it will send it in the HTTP Authorization header 
of the requests to our services (known as resource servers in OAuth), which can then verify it to determine whether to process the request, find the associated user account, etc.

Public clients like a single-page or mobile app don't require credentials to obtain tokens and instead rely on the Proof Key for Code Exchange (PKCE) Authorization Code flow extension, which is the reason why `clientAuthenticationMethod` is set to `none`.

After applying our ClientRegistration to the cluster, **AppSSO will create a secret containing the credentials that client applications will use**, named after the client registration.
```terminal:execute
command: kubectl apply -f ~/config/auth/
clear: true
```

To **secure the product service with OAuth**, we first have to add the related dependency. As already mentioned, for our setup, the services are acting as an OAuth resource server but there is also a library for OAuth clients available.
 ```editor:insert-lines-before-line
file: ~/product-service/pom.xml
line: 33
text: |2
          <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-oauth2-resource-server</artifactId>
          </dependency> 
```

Next, we will configure the service as a resource server and protect all our endpoints with business-related functionality.
```editor:insert-lines-before-line
file: ~/product-service/src/main/java/com/example/productservice/WebSecurityConfiguration.java
line: 14
text: |2
              .requestMatchers("/api/**").authenticated()
```
```editor:insert-lines-before-line
file: ~/product-service/src/main/java/com/example/productservice/WebSecurityConfiguration.java
line: 17
text: |2
          .oauth2ResourceServer((oauth2) -> oauth2.jwt(Customizer.withDefaults()))
```
```editor:insert-lines-before-line
file: ~/product-service/src/main/java/com/example/productservice/WebSecurityConfiguration.java
line: 7
text: |2
  import org.springframework.security.config.Customizer;
```

The access token provided in the HTTP Authorization header of requests will be decoded, verified, and validated with a `JwtDecoder` bean, that will be automatically created based on the following configuration.
```editor:insert-value-into-yaml
file: ~/product-service/src/main/resources/application.yaml
path: spring
value:
  security.oauth2.resourceserver.jwt.jwk-set-uri: ${spring.security.oauth2.client.provider.appsso.issuer-uri}/oauth2/jwks
```

As this configuration is not available for our tests, we have to mock it so that they will not fail.
```editor:insert-lines-before-line
file: ~/product-service/src/test/java/com/example/productservice/ApplicationTests.java
line: 8
text: |2

    @MockBean
    private JwtDecoder jwtDecoder;
```
```editor:insert-lines-before-line
file: ~/product-service/src/test/java/com/example/productservice/ApplicationTests.java
line: 5
text: |2
  import org.springframework.boot.test.mock.mockito.MockBean;
  import org.springframework.security.oauth2.jwt.JwtDecoder;
```

By configuring a service binding in the Workload, we don't have to care about additional configuration.
```editor:insert-value-into-yaml
file: ~/product-service/config/workload.yaml
path: spec.serviceClaims
value:
  - name: auth-client
    ref:
      apiVersion: services.apps.tanzu.vmware.com/v1alpha1
      kind: ResourceClaim
      name: auth-client
```

Let's commit the updated source code and apply the Workload.
```terminal:execute
command: |
  (cd product-service && git add . && git commit -m "Add OAuth support" && git push)
clear: true
```
```terminal:execute
command: tanzu apps workload apply -f product-service/config/workload.yaml -y
clear: true
```

To configure the order service for OAuth, we only have to activate a profile that configures it in the same way as the product service and add the service binding.
```editor:append-lines-to-file
file: ~/samples/externalized-configuration/order-service.yaml
text: |
  spring.profiles.active: oauth
```
```terminal:execute
command: (cd samples/externalized-configuration && git add . && git commit -m "Enable OAuth for order service" && git push)
clear: true
```
```editor:insert-value-into-yaml
file: ~/order-service/config/workload.yaml
path: spec.serviceClaims
value:
  - name: auth-client
    ref:
      apiVersion: services.apps.tanzu.vmware.com/v1alpha1
      kind: ResourceClaim
      name: auth-client
```
**WORKAROUD**
```editor:insert-value-into-yaml
file: ~/order-service/config/workload.yaml
path: spec
value:
  env:
  - name: SPRING_PROFILES_ACTIVE
    value: auth
```
```terminal:execute
command: tanzu apps workload apply -f order-service/config/workload.yaml -y
clear: true
```

We also have to add a route for the frontend to the API gateway. 
In most cases, configuration of single-page applications for different environments is bundled with code - which is contrary to factor 3 for cloud-native applications. 
As we are not able to provide configuration for the OAuth flow for all possible workshop sessions and the related auth server urls at build time, there are [placeholders in the frontend source code](https://github.com/timosalm/tap-spring-developer-workshop/blob/main/setup/frontend/src/environments/environment.prod.ts) that will be replaced by the Gateway with the `RewriteResponseBody` filter. 
```editor:append-lines-to-file
file: ~/config/gateway/gateway-route-config.yaml
text: |2
    - uri: http://frontend.{{ session_namespace }}
      predicates:
      - Path=/frontend/**
      filters: 
      - 'StripPrefix=1'
      - RewriteResponseBody=ISSUER_SCHEME:https,ISSUER_HOST:authserver-1-{{ session_namespace }}.{{ ENV_TAP_INGRESS }},CLIENT_ID_VALUE:{{ session_namespace }}_client-registration
``` 
```terminal:execute
command: kubectl apply -f config/gateway/
clear: true
```

Run the following command to see when the OAuth-enabled version of the product service is deployed based on the HTTP response status code change from 200 to 401 due to the missing, now required, Authentication header including a valid token.
```terminal:execute
command: watch -n 1 'curl -I https://gateway-{{ session_namespace }}.{{ ENV_TAP_INGRESS }}/services/product-service/api/v1/products'
clear: true
```
```terminal:interrupt
session: 2
```
 
Now it's finally time to see whether everything works as expected with the **username: `developer`**, and the **password: `123456`** as defined in the `AuthServer`.
```dashboard:open-url
url: https://gateway-{{ session_namespace }}.{{ ENV_TAP_INGRESS }}/frontend/
```

![Updated architecture with Authorization Server](../images/microservice-architecture-auth.png)


