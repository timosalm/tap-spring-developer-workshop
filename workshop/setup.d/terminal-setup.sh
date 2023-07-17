#!/bin/bash
set -x
set +e

cat <<EOT >> .netrc
machine $(echo $GITEA_BASE_URL | awk -F/ '{print $3}')
       login $GITEA_USERNAME
       password $GITEA_PASSWORD
EOT

git config --global user.email "$GITEA_USERNAME@example.com"
git config --global user.name "$GITEA_USERNAME"

kubectl() {
    if [[ $@ == *"secret"* ]]; then
        command echo "No resources found in $SESSION_NAMESPACE namespace."
    else
        command kubectl "$@"
    fi
}

k() {
    if [[ $@ == *"secret"* ]]; then
        command echo "No resources found in $SESSION_NAMESPACE namespace."
    else
        command kubectl "$@"
    fi
}