#!/bin/bash
set -x
set +e

cat <<EOT >> .netrc
machine $(echo $GITEA_BASE_URL | awk -F/ '{print $3}')
       login $GITEA_USERNAME
       password $GITEA_PASSWORD
EOT

git config --global user.email "$GITEA_USERNAME@example.com"
git config --global user.name "$GITEA_USERNAME"

for serviceName in order-service shipping-service; do
    cd $serviceName && git init -b $SESSION_NAMESPACE && git remote add origin $GITEA_BASE_URL/${serviceName}.git && git add . && git commit -m "Initial implementation" && git push -u origin $SESSION_NAMESPACE -f
    cd ~
    sed -i 's~SOURCE_GIT_URL~'"$GITEA_BASE_URL"'/'"${serviceName}"'.git~g' ${serviceName}/config/workload.yaml
    sed -i 's/SOURCE_GIT_BRANCH/'"$SESSION_NAMESPACE"'/g' ${serviceName}/config/workload.yaml
    kubectl apply -f ${serviceName}/config/workload.yaml
done

cd ~/samples/externalized-configuration
sed -i 's~NAMESPACE~'"$SESSION_NAMESPACE"'~g' order-service.yaml
git init -b $SESSION_NAMESPACE && git remote add origin $GITEA_BASE_URL/externalized-configuration.git && git add . && git commit -m "Initial implementation" && git push -u origin $SESSION_NAMESPACE -f
cd ~

kubectl apply -f samples/workload-payment-service-native.yaml