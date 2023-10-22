#!/bin/bash
set -x
set +e

jq ". + { \"java.server.launchMode\": \"Standard\", \"redhat.telemetry.enabled\": false, \"vs-kubernetes.ignore-recommendations\": true, \"tanzu-app-accelerator.tanzuApplicationPlatformGuiUrl\": \"https://tap-gui.${TAP_INGRESS}\", \"tanzu.sourceImage\": \"${REGISTRY_HOST}/vs-code-source-image\",  \"files.exclude\": { \"**/.**\": true}, \"editor.fontSize\": 16 }" /home/eduk8s/.local/share/code-server/User/settings.json | sponge /home/eduk8s/.local/share/code-server/User/settings.json

cat <<EOL >> spring-cloud-demo.code-workspace
{
  "folders": [
    {
      "name": "Order Service",
      "path": "order-service"
    },
    {
      // Docs and release notes
      "name": "Shipping Service",
      "path": "shipping-service"
    },
    {
      // Yeoman extension generator
      "name": "Product Service",
      "path": "product-service"
    }
  ]
}
EOL