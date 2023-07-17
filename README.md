# Installation

## Prerequisites

- A TAP 1.6 environment with OOTB Testing/Scanning Supply Chain installed
- [Gitea](https://gitea.io) for the creation of Git repositories for each session with ENABLE_PUSH_CREATE_USER enabled in the app.ini file
 
## App Accelerator
The Application Accelerator used for this application can be registered in the TAP environment via the following command.
```
kubectl apply -f https://raw.githubusercontent.com/timosalm/tap-spring-developer-workshop/main/setup/accelerator/accelerator-resource.yaml
```

## Workshop installation
This repository includes a GitHub Actions workflow that builds a container image based on this [Dockerfile](Dockerfile) and publishes it as a package [here](https://github.com/timosalm/tap-spring-developer-workshop/pkgs/container/tap-spring-developer-workshop).
The correct image tag for this image is already set in the `values-example.yaml`.

Copy the values-example.yaml to values.yaml and set configuration values.
```
cp values-example.yaml values.yaml
```
Run the installation script.
```
./install.sh
```

# Development

As the workshop content is being downloaded from a Git repository, we can update the content in place without needing to restart the workshop session. To perform an update, after you have pushed back any changes to the hosted Git repository from the workshop session terminal run:
```
update-workshop
```
This command will download any workshop content from the Git repository, unpack it into the live workshop session, and re-run any script files found in the workshop/setup.d directory.
Once the workshop content has been updated you can reload the current page of the workshop instructions by clicking on the reload icon of your browser or the one on the dashboard while holding down the shift key.

Note that if additional pages were added to the workshop instructions or pages renamed, you will need to restart the workshop renderer process. This can be done by running:
```
restart-workshop
```
So long as you didn’t rename the current page, you can trigger a reload of the current page, or if the name had changed, click on the home icon (so long as name of the first page hadn’t changed), or refresh the whole browser window.