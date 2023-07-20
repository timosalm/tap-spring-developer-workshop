#!/bin/bash
set -x
set +e

kubectl annotate namespace ${SESSION_NAMESPACE} secretgen.carvel.dev/excluded-from-wildcard-matching-
kubectl label namespaces ${SESSION_NAMESPACE} apps.tanzu.vmware.com/tap-ns=""
kubectl patch serviceaccount default -p '{"secrets": [{"name": "registry-credentials"},{"name": "git-https"}], "imagePullSecrets": [{"name": "registry-credentials"}]}'

cp -a samples/spring-cloud-demo/. .
rm -rf samples/spring-cloud-demo