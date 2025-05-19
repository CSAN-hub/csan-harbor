#!/bin/bash

# Install and configure Harbor

# @author  Fabrice Jammes

set -euxo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

. $DIR/conf.sh

ciux ignite -l e2e "$DIR"

argocd login --core
kubectl config set-context --current --namespace="$argocd_ns"

argocd app create harbor-registry --dest-server https://kubernetes.default.svc \
    --dest-namespace "$argocd_ns" \
    --repo "$csan_repo" \
    --path cd/apps
    -p spec.source.targetRevision.default="$CSAN_HARBOR_WORKBRANCH" \

argocd app sync harbor-registry

ink "Synk operator dependencies for harbor-registry"
argocd app sync -l app.kubernetes.io/part-of=harbor-registry,app.kubernetes.io/component=operator
argocd app wait -l app.kubernetes.io/part-of=harbor-registry,app.kubernetes.io/component=operator

ink "Synk all apps for harbor-registry"
argocd app sync -l app.kubernetes.io/part-of=harbor-registry

