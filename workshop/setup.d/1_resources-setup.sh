#!/bin/bash
set -x
set +e

kubectl annotate namespace ${SESSION_NAMESPACE} secretgen.carvel.dev/excluded-from-wildcard-matching-
kubectl label namespaces ${SESSION_NAMESPACE} apps.tanzu.vmware.com/tap-ns=""
# kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "educates-registry-credentials"}], "secrets": [{"name": "educates-registry-credentials"}]}'

cp -a -R samples/spring-cloud-demo/. .
rm -rf samples/spring-cloud-demo



apiVersion: v1
imagePullSecrets:
- name: registries-credentials
kind: ServiceAccount
metadata:
  annotations:
    doc: This resource has been created for you as part of the necessary resources
      for running your cluster supply chain. You are free to make changes to suit
      your needs. If you need to revert your changes, deleting this resource will
      cause it to be re-created in a default state.
    kapp.k14s.io/create-strategy: fallback-on-update
    kapp.k14s.io/identity: v1;default//ServiceAccount/default;v1
    kapp.k14s.io/original: '{"apiVersion":"v1","imagePullSecrets":[{"name":"registries-credentials"}],"kind":"ServiceAccount","metadata":{"annotations":{"doc":"This
      resource has been created for you as part of the necessary resources for running
      your cluster supply chain. You are free to make changes to suit your needs.
      If you need to revert your changes, deleting this resource will cause it to
      be re-created in a default state.","kapp.k14s.io/create-strategy":"fallback-on-update","namespace-provisioner.apps.tanzu.vmware.com/no-overwrite":""},"labels":{"kapp.k14s.io/app":"1691266728780706925","kapp.k14s.io/association":"v1.521d16fb27f264e82c374d42b91195b6"},"name":"default","namespace":"default"},"secrets":[{"name":"registries-credentials"}]}'
    kapp.k14s.io/original-diff-md5: 58e0494c51d30eb3494f7c9198986bb9
    namespace-provisioner.apps.tanzu.vmware.com/no-overwrite: ""
  creationTimestamp: "2023-04-17T10:16:38Z"
  labels:
    kapp.k14s.io/app: "1691266728780706925"
    kapp.k14s.io/association: v1.521d16fb27f264e82c374d42b91195b6
  name: default
  namespace: default
  resourceVersion: "108000748"
  uid: c9f7eb86-6f95-4ce5-9135-57956a4cfef6
secrets:
- name: registries-credentials