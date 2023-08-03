Let's first have a look at the Continuous integration (CI) part of the supply chain, which automates the process of building and testing the application we like to deploy.

The first step in the path to production **watches** the in the Workload configured **repository with the source code** for new commits and makes the source code available for the following steps as an archive via HTTP. 

For integration with existing CI systems, such as Jenkins, it's also possible to pull **artifacts from existing Maven repositories**, and to make it possible via the tanzu CLI to provide source code from a local directory, **container images containing source code** can be also defined as a source.

##### Source Tester
 
The Source Tester step executes uses by default [Tekton](https://tekton.dev) and as an alternative Jenkins (more to come in the future) to run a Pipeline that executes tests part of the application's source code. 
Depending on how much flexibility developers need, they can define it for their applications or as the rest of the supply chain, it will also be defined and provided by the operators. The pipeline can also be applied via GitOps, in our case, there is already a very basic example that just works for Spring Boot applications using Maven applied to the cluster.
```execute
kubectl eksporter Pipeline --keep metadata.labels
```
Let's now jump to **TAP-GUI to view the logs of the test run** in the detail view of the Source Tester step.

##### Source Scanner

In the next step, the provided **source code will be scanned** for known vulnerabilities.

**Go to TAP-GUI** and have a look at the details view of the Source Scanner step. You can see that some critical were found by the scanner. 
You can **click on the CVE's ID** to get more information.
The TAP-GUI also provides a dashboard to discover all the CVEs in the organizations and workloads that are affected.
```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/security-analysis
```
If you have a closer look at the dashboard, you can see that some of the workloads don't violate a policy but also have several CVEs with critical or high severity.

For source scans to happen, **scan policies** must be defined on a namespace level which can be done during the automated provisioning of new namespaces. It defines how to evaluate whether the artifacts scanned are compliant, for example, allowing one to be either very strict or restrictive about particular vulnerabilities found. 
If an artifact is not compliant, the application will not be deployed.

Let's go back to the visualization of the supply chain and **click on the policy name in the detail view of the Source Scanner**.
```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/supply-chain/host/{{ session_namespace }}/product-service
```
Our source can step didn't fail because the `notAllowedSeverities`configuration in the scan policy is only set to `["UnknownSeverity"]`. If that would be different, it's also possible to whitelist CVEs with the `ignoreCves` configuration.

Now it's time to have a closer look at aspects like container building and continuous delivery.

##### Image Provider

To be able to get all the benefits our application Kubernetes provides, we have to containerize it.

The most obvious way to do this is to write a Dockerfile, run `docker build`, and push it to the container registry of our choice via `docker push`.

For the building of container images from a Dockerfile, TAP uses the open-source tool [kaniko](https://github.com/GoogleContainerTools/kaniko).
Developers have to specify the following parameter in their Workload configuration where the value references the path of the Dockerfile. 
```
apiVersion: carto.run/v1alpha1
kind: Workload
...
spec:
  params:
  - name: dockerfile
    value: ./Dockerfile
...
```

Because it's hard to create an optimized and secure container image (or Dockerfile), TAP uses a **different approach as default for the containerization of your applications via so-called Cloud Native Buildpacks**. They detect based on the application's source code what's needed to compile and package it in a container image with best practices in mind. Combined with a solution part of TAP, called **VMware Tanzu Build Service (TBS)**, it's even possible to do automated base image updates!
We will later have a closer look at it.

##### Image Scanner

If you **have a closer look at the Image Scanner step in TAP-GUI** you can see that **different CVEs were found than with the source scanning**.
Reasons for that are for example that the **container image includes the full stack** required to run the application, and **for source code scans, most of the CVE scanners don't download the dependencies, which leads often to false positives or missed CVEs**.

You may ask yourself whether there is still a value in source scans. The answer is yes, as **shifting security left in the path to production improves the productivity of developers**.
Due to the false positives, it makes sense to have **different scan policies for source scanning and image scanning**, which is supported by VMware Tanzu Application Platform but not implemented for this workshop.

##### Config Provider, App Config, Service Bindings, Api Descriptors 

The steps between "Image Scanner" and "Config Writer" in the supply chain generate the YAML of all the Kubernetes resources required to run the application.

##### Config Writer 
After generating the YAML of all the Kubernetes resources required to run the application, it's time to apply them to a cluster. Usually, there is more than one cluster the application should run on, for example, on a test cluster before production.

The Config Writer is responsible for writing the YAML files either to a Git repository for **GitOps** or, as an alternative, packaging them in a container image and pushing it to a container registry for **RegistryOps**.

**The workshop environment is configured for RegistryOps.**

##### Delivery
With the deployment configuration of our application available, we are now able to deploy it automatically to a fleet of clusters on every change. 
**Cartographer** also **provides a way to define a continuous delivery workflow** resource on the target cluster, which e.g. picks up that configuration, deploys it, and maybe runs some automated integration tests.

For the sake of simplicity, our application is deployed to the same cluster we used for building it. 

In the next section, you'll get some information about components that are relevant for the running application.