#!/bin/bash
set -x
set +e

jq ". + { \"java.server.launchMode\": \"Standard\", \"redhat.telemetry.enabled\": false, \"vs-kubernetes.ignore-recommendations\": true, \"tanzu-app-accelerator.tanzuApplicationPlatformGuiUrl\": \"https://tap-gui.${TAP_INGRESS}\",  \"files.exclude\": { \"**/.**\": true} }" /home/eduk8s/.local/share/code-server/User/settings.json | sponge /home/eduk8s/.local/share/code-server/User/settings.json