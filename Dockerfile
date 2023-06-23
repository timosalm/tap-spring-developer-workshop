FROM registry.tanzu.vmware.com/tanzu-application-platform/tap-packages@sha256:c184e9399d2385807833be0a9f1718c40caa142b6e1c3ddf64fa969716dcd4e3

USER root

# Tanzu CLI
ADD tanzu-framework-linux-amd64.tar /tmp
RUN mv $(find /tmp/ -name 'tanzu-core-linux_amd64' -print0) /usr/local/bin/tanzu && \
  chmod 755 /usr/local/bin/tanzu && \
  tanzu plugin install --local /tmp/cli/ all && \
  chmod -R 755 .config/tanzu

# Install Tanzu Dev Tools
ADD tanzu-vscode-extension.vsix /tmp
ADD tanzu-app-accelerator.vsix /tmp
RUN curl -fsSL https://code-server.dev/install.sh | sh -s -- --version=4.14.0
RUN cp -rf /usr/lib/code-server/* /opt/code-server/
RUN rm -rf /usr/lib/code-server /usr/bin/code-server

RUN code-server --install-extension /tmp/tanzu-vscode-extension.vsix
RUN code-server --install-extension /tmp/tanzu-app-accelerator.vsix

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
RUN kubectl krew install tree
RUN kubectl krew install eksporter
RUN chmod 775 -R $HOME/.krew
RUN apt update
RUN apt install ruby-full -y

# Utilities
RUN apt-get update && apt-get install -y unzip moreutils

RUN chown -R eduk8s:users /home/eduk8s/.config

RUN rm -rf /tmp/*

USER 1001

RUN fix-permissions /home/eduk8s