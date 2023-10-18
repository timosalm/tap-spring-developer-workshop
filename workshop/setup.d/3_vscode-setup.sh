#!/bin/bash
set -x
set +e

code-server --install-extension redhat.java@1.24.2023101204
code-server --install-extension redhat.vscode-yaml@1.14.0
code-server --install-extension vscjava.vscode-java-debug@0.54.0
#code-server --install-extension vmware.tanzu-dev-tools@1.0.6
#code-server --install-extension VMware.tanzu-app-accelerator@1.0.1
code-server --install-extension tanzu-vscode-extension.vsix && rm tanzu-vscode-extension.vsix
code-server --install-extension tanzu-app-accelerator.vsix && rm tanzu-app-accelerator.vsix

code-server --install-extension vscjava.vscode-maven@0.42.0
code-server --install-extension vscjava.vscode-java-dependency@0.23.1
code-server --install-extension vscjava.vscode-java-test@0.39.1
code-server --install-extension vmware.vscode-spring-boot@1.49.0

jq ". + { \"java.server.launchMode\": \"Standard\", \"redhat.telemetry.enabled\": false, \"vs-kubernetes.ignore-recommendations\": true, \"tanzu-app-accelerator.tanzuApplicationPlatformGuiUrl\": \"https://tap-gui.${TAP_INGRESS}\", \"tanzu.sourceImage\": \"harbor.learningcenter.tap.ryanjbaxter.com/s1-2023-workshop/${session_namespace}\",  \"files.exclude\": { \"**/.**\": true} }" /home/eduk8s/.local/share/code-server/User/settings.json | sponge /home/eduk8s/.local/share/code-server/User/settings.json
