Inspired by [start.spring.io](https://start.spring.io), **Application Accelerators for VMware Tanzu** enables developers to create new applications based on templates that follow enterprise standards of your organization. This accelerates how you go from idea to production with ready-made, enterprise-conformant code and configurations without needing to read tons of docs straight away.

By clicking on the below link, you will open the IDE plugin to see a list of Accelerators available.
```editor:execute-command
command: workbench.view.extension.tanzu-app-accelerator
```

Select the **Inclusion** accelerator from the list, fill in the details that the project needs and press **Continue** until you see **Generate Project**. When you click on **Generate Project** (Click **OK** at the pop-up window), a new tab will open. The Accelerator has now generated the code in a new tab. We can close the tab and continue to work on the IDE integrated into the workshop UI.

```editor:open-file
file: ~/inclusion/config/workload.yaml
```

The important bit here is the **workload.yaml** file. It configures the continuous path to production.