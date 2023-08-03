The goal of this interactive workshop was to learn how to mitigate the challenges of a typical microservice application with Spring and the capabilities of VMware Tanzu Application Platform.

**You can download the sample application you created via the following commands.**

```terminal:execute
description: Archive sample code for download
command: |
  mkdir /tmp/tap-spring-developer-workshop-sample
  cp -a order-service /tmp/tap-spring-developer-workshop-sample/
  cp -a product-service /tmp/tap-spring-developer-workshop-sample/
  cp -a shipping-service /tmp/tap-spring-developer-workshop-sample/
  cp -a samples/. /tmp/tap-spring-developer-workshop-sample/
  zip -r tap-spring-developer-workshop-sample.zip /tmp/tap-spring-developer-workshop-sample/
clear: true
```
```files:download-file
path: tap-spring-developer-workshop-sample.zip
```

For any questions, reach out to your VMware or VMware Tanzu sales contact or use the contact form on our website.
```dashboard:open-url
url: https://tanzu.vmware.com/contact
```