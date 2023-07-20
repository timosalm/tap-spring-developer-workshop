Let's first have a look at the Continuous integration (CI) part of the supply chain, which automates the process of building and testing the application we like to deploy.

##### Source Provider

The first step in the path to production **watches** the in the Workload configured **repository with the source code** for new commits and makes the source code available for the following steps as an archive via HTTP. 

[Flux Source Controller](https://fluxcd.io/flux/components/source/) is used for this functionality, but as with any other tool we provide with TAP it can be easily replaced by an alternative.

For integration with existing CI systems, such as Jenkins, it's also possible to pull **artifacts from existing Maven repositories**, and 
to make it possible via the tanzu CLI to provide source code from a local directory, **container images containing source code** can be also defined as a source.

##### Source Tester
 
The Source Tester step executes uses by default [Tekton](https://tekton.dev) and as an alternative Jenkins (more to come in the future) to run a Pipeline that executes tests part of the application's source code. 
Depending on how much flexibility developers need, they can define it for their applications or as the rest of the supply chain, it will also be defined and provided by the operators. The pipeline can also be applied via GitOps, in our case, there is already a very basic example that just works for Spring Boot applications using Maven applied to the cluster.
```execute
kubectl eksporter Pipeline --keep metadata.labels
```

To decouple the pipeline from the supply chain, its not directly stamped out by a template or referenced by name and instead will be detected based on its `apps.tanzu.vmware.com/pipeline: test` label.

The Pipeline will be executed by stamping out a `PipelineRun` custom resource.

This type of integration of Tekton into the Cartographer world is heavily used within the OOTB supply chains to integrate tools outside of Kubernetes.

Let's now jump to **TAP-GUI to view the logs of the test run** in the detail view of the Source Tester step.

##### Source Scanner

In the next step, the provided **source code will be scanned** for known vulnerabilities by default using [Grype](https://github.com/anchore/grype). VMware Tanzu Application platform also offers integrations to other scanners like **Trivy** or **Snyk**.

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

In the next section, we will have a closer look at aspects like container building and continuous delivery.