FROM registry.tanzu.vmware.com/tanzu-application-platform/tap-packages@sha256:c184e9399d2385807833be0a9f1718c40caa142b6e1c3ddf64fa969716dcd4e3

USER root

# Tanzu CLI
RUN apt-get install -y ca-certificates curl gpg
RUN curl -fsSL https://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub | sudo gpg --dearmor -o /etc/apt/keyrings/tanzu-archive-keyring.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/tanzu-archive-keyring.gpg] https://storage.googleapis.com/tanzu-cli-os-packages/apt tanzu-cli-jessie main" | sudo tee /etc/apt/sources.list.d/tanzu.list
RUN apt-get update
RUN apt-get install -y tanzu-cli 
RUN tanzu config set env.TANZU_CLI_ADDITIONAL_PLUGIN_DISCOVERY_IMAGES_TEST_ONLY projects.registry.vmware.com/tanzu_cli_stage/plugins/plugin-inventory:latest 
RUN yes | tanzu plugin install --group vmware-tap/default:v1.6.0-rc.2 


# Install Tanzu Dev Tools
ADD tanzu-vscode-extension.vsix /tmp
ADD tanzu-app-accelerator.vsix /tmp
RUN curl -fsSL https://code-server.dev/install.sh | sh -s -- --version=4.14.1
RUN cp -rf /usr/lib/code-server/* /opt/code-server/
RUN rm -rf /usr/lib/code-server /usr/bin/code-server

RUN code-server --install-extension /tmp/tanzu-vscode-extension.vsix
RUN code-server --install-extension /tmp/tanzu-app-accelerator.vsix

RUN curl -fsSL https://raw.githubusercontent.com/tilt-dev/tilt/master/scripts/install.sh | bash 
RUN chown -R eduk8s:users /home/eduk8s/.tilt-dev

RUN chown -R eduk8s:users /home/eduk8s/.cache
RUN chown -R eduk8s:users /home/eduk8s/.local
RUN chown -R eduk8s:users /home/eduk8s/.config

# TBS
RUN curl -L -o /usr/local/bin/kp https://github.com/vmware-tanzu/kpack-cli/releases/download/v0.10.0/kp-linux-amd64-0.10.0 && \
  chmod 755 /usr/local/bin/kp

# Install krew
RUN \
( \
  set -x; cd "$(mktemp -d)" && \
  OS="$(uname | tr '[:upper:]' '[:lower:]')" && \
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" && \
  KREW="krew-${OS}_${ARCH}" && \
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" && \
  tar zxvf "${KREW}.tar.gz" && \
  ./"${KREW}" install krew \
)
RUN echo "export PATH=\"${KREW_ROOT:-$HOME/.krew}/bin:$PATH\"" >> ${HOME}/.bashrc
ENV PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
ENV KUBECTL_VERSION=1.25
RUN kubectl krew install tree
RUN kubectl krew install eksporter
RUN chmod 775 -R $HOME/.krew
RUN apt update
RUN apt install ruby-full -y

# Utilities
RUN apt-get update && apt-get install -y unzip moreutils openjdk-17-jdk

RUN chown -R eduk8s:users /home/eduk8s/.config

RUN rm -rf /tmp/*

USER 1001

RUN fix-permissions /home/eduk8s