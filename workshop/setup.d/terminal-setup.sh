#!/bin/bash
set -x
set +e

cat <<EOT >> .netrc
machine $(echo $GITEA_BASE_URL | awk -F/ '{print $3}')
       login $GITEA_USERNAME
       password $GITEA_PASSWORD
EOT

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