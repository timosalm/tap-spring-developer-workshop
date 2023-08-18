Let's first have a look at the Continuous integration (CI) part of the supply chain, which automates the process of building and testing the application we like to deploy.

The first step in the path to production **watches** the **repository with the source code** configured in the Workload for new commits and makes the source code available as an archive via HTTP. 

##### Source Tester
 
The Source Tester uses [Tekton](https://tekton.dev) by default to execute tests part as part of the pipeline.

TAP ships with an out-of-the-box test pipeline for Spring Boot applications.  We can see the test pipeline definition by running the following command.
```execute
kubectl eksporter Pipeline --keep metadata.labels
```
Let's open the supply chain of the `product-service` app we just deployed and view the test logs from the Source Tester step.

```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/supply-chain/host/{{ session_namespace }}/product-service
```

In the supply chain UI, select Source Tester and click the GUID in the Stage Details.

![](../images/source-tester-pipeline.png)

By selecting the step-test in the resulting popup window, you can view the logs of the `mvn test` command.

![](../images/select-test-step.png)


##### Image Provider

Since TAP is built upon Kubernetes we need to package our application into a container, this is what the image provider step does.

The most obvious way to do this is to write a Dockerfile, run `docker build`, and push it to the container registry of our choice via `docker push`.

For the building of container images from a Dockerfile, TAP uses the open-source tool [kaniko](https://github.com/GoogleContainerTools/kaniko).
If you want to use a Dockerfile you can setup your applications Workload to do so using the following `spec.params`. 
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

However, contructing a Dockerfile that is both optimized and free from security issues can be quite challenging for most developers, and frankly is not something they want to have to concern themselves with.  
In TAP, the default approach to building a container image for your application is to use [Cloud Native Buildpacks](https://buildpacks.io/). The benefit of using Cloud Native Buildpacks is that the buildpack takes care of compiling your application into a container image that is both secure and optimized.  The best part is all you need to do is provide TAP with the source code for your application (which we already did in our application's Workload).


##### Image Scanner

In the next step, the built **image will be scanned** for known vulnerabilities.

To see any vulnerabilities in the `product-service` image, open its supply chain, and select the Image Scanner step.
```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/supply-chain/host/{{ session_namespace }}/product-service
```
This will show any known vulnerability for the image that was built, and you can see additional details by clicking on the CVE IDs.

![](../images/image-scanner.png)


TAP also provides a dashboard to discover all the CVEs in the organizations and workloads that are affected.
```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/security-analysis
```

For image scans to happen, **scan policies** must be defined on a namespace level which can be done during the automated provisioning of new namespaces. It defines how to evaluate whether the artifacts scanned are compliant.  Depending on how restrictive those policies are will determine whether the artifact is compliant or not.  If an artifact is not compliant, it will not be deployed.

Let's go back to the visualization of the supply chain and **click on the policy name in the detail view of the Image Scanner**.

Our image step didn't fail because the `notAllowedSeverities` configuration in the scan policy is only set to `["UnknownSeverity"]`. It's also possible to whitelist CVEs with the `ignoreCves` configuration.  You can read more about possible scan policy configuration in the [TAP documentation](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.6/tap/scst-scan-policies.html).

The **container image includes the full stack** required to run the application, which includes more information than just running a source code scan (**for source code scans, most of the CVE scanners don't download the dependencies, which leads often to false positives or missed CVEs**).


##### Config Provider, App Config, Service Bindings, Api Descriptors 

The steps between "Image Scanner" and "Config Writer" in the supply chain generate the YAML of all the Kubernetes resources required to run the application.

![](../images/image-scanner-config-writier.png)

##### Config Writer 
After generating the YAML of all the Kubernetes resources required to run the application, it's time to apply them to a cluster. Usually, there is more than one cluster the application should run on, for example, on a test cluster before production.

The Config Writer is responsible for writing the YAML files either to a Git repository for **GitOps** or, as an alternative, packaging them in a container image and pushing it to a container registry for **RegistryOps**.  This workshop environment is configured to use RegistryOps, so the configuration is pushed to a container registry in the Config Writer step.

##### Delivery
With the deployment configuration of our application available, we are now able to deploy it automatically to a fleet of clusters on every change. 
**Cartographer** also **provides a way to define a continuous delivery workflow** resource on the target cluster, which picks up that configuration, and deploys it.  After the deployment, a delivery workflow could then potentially run some integration tests on the app before routing traffic to it.

For the sake of simplicity, our application is deployed to the same cluster we used for building it. 

In the next section, you'll get some information about components that are relevant to the running application.
