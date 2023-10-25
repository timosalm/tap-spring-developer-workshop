# Installation

## Prerequisites

- A TAP 1.6 environment with OOTB Testing/Scanning and Basic Supply Chain installed
 
## App Accelerator
The Application Accelerator used for this application can be registered in the TAP environment via the following command.
```
kubectl apply -f https://raw.githubusercontent.com/timosalm/tap-spring-developer-workshop/main/setup/accelerator/accelerator-resource.yaml
```

## API Docs

To have API docs for the application available in TAP Developer Portal run the following command. Our commercial Spring Cloud currently doesn't support API aggregation (will be released soon), therefore we are using the following workaround, and consume an OpenAPI spec from another TAP instance.
```
kubectl apply -f https://raw.githubusercontent.com/timosalm/tap-spring-developer-workshop/main/setup/api-docs.yaml
```
## Workshop installation
Copy the values-example.yaml to values.yaml and set configuration values.
```
cp values-example.yaml values.yaml
```
Run the installation script.
```
./install.sh
```
