#!/bin/bash
set -x
set +e

mkdir -p config/gateway
mkdir -p config/auth
mkdir -p config/config-server

(cd /opt/git/repositories && git init && git config --global --add safe.directory /opt/git/repositories && git instaweb)

for serviceName in order-service shipping-service; do
    sed -i 's~REGISTRY_HOST~'"$REGISTRY_HOST"'~g' ${serviceName}/config/workload.yaml
    sed -i 's~SOURCE_GIT_URL~'"$GIT_PROTOCOL"'://'"$GIT_HOST"'/'"${serviceName}"'.git~g' ${serviceName}/config/workload.yaml
done

(cd ~/samples/externalized-configuration && sed -i 's~NAMESPACE~'"$SESSION_NAMESPACE"'~g' order-service.yaml)