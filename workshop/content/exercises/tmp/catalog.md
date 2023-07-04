Let's now have a look at the details of the application. 
So I log into the TAP GUI (General User Interface) here:
```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/catalog
```

If you access the web portal for the first time, you'll have to select the Guest tile and press Enter.

You should be able to see the TAP catalog with all the applications deployed, including the Inclusion application.
By clicking on the Inclusion app, you can access pieces of information, such as:

1. **The Logical graph of the app** - all the services and their relationship.
```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/catalog/default/system/emoji-world/diagram
```

3. **API Swagger definition** - the app API documentation.
```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/catalog/dev-space/api/inclusion-{{ ENV_TAP_INGRESS }}/definition
```

4. **Runtime Resources** - to see application runtime resources such as application deployment objects and logs/metrics for monitoring and debugging. Here I can also find the application URL. 
As my application deploys further, I will be able to see more.
```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/catalog/default/component/inclusion/workloads
```

Let’s now look closely at the Supply Chain, the CI/CD (Continuous Integration/Continuous Delivery) set of tools that come out of the box with the TAP installation.