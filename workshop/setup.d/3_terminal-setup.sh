#!/bin/bash
set -x
set +e

mkdir -p config/gateway config/auth config/config-server config/service-registry

(cd /opt/git/repositories && git init && git config --global --add safe.directory /opt/git/repositories && git instaweb)

for serviceName in order-service shipping-service product-service; do
    sed -i 's~REGISTRY_HOST~'"$REGISTRY_HOST"'~g' samples/spring-cloud-demo/${serviceName}/config/workload.yaml
    sed -i 's~SOURCE_GIT_URL~'"$GIT_PROTOCOL"'://'"$GIT_HOST"'/'"${serviceName}"'.git~g' samples/spring-cloud-demo/${serviceName}/config/workload.yaml
done

cp -r samples/spring-cloud-demo/order-service .
cp -r samples/spring-cloud-demo/shipping-service .

(cd ~/samples/externalized-configuration && sed -i 's~NAMESPACE~'"$SESSION_NAMESPACE"'~g' order-service.yaml)