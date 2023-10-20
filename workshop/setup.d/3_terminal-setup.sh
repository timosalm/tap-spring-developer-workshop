#!/bin/bash
set -x
set +e

mkdir -p config/gateway
mkdir -p config/auth

(cd /opt/git/repositories && git init && git config --global --add safe.directory /opt/git/repositories && git instaweb)

for serviceName in order-service shipping-service; do
    sed -i 's~SOURCE_GIT_URL~'"$GIT_PROTOCOL"'://'"$GIT_HOST"'/'"${serviceName}"'.git~g' ${serviceName}/config/workload.yaml
done

(cd ~/samples/externalized-configuration && sed -i 's~NAMESPACE~'"$SESSION_NAMESPACE"'~g' order-service.yaml)

#kubectl apply -f samples/workload-frontend-image.yaml
