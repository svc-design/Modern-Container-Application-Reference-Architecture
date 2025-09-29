#!/usr/bin/env bash
set -euo pipefail

: "${GITOPS_REPO:?GITOPS_REPO is required}"
: "${GITOPS_BRANCH:?GITOPS_BRANCH is required}"
: "${GITOPS_PATH:?GitOps path is not configured for container matrix entry}"

cat <<EOF_CONFIG > git-repository.yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: GitRepository
metadata:
  name: ${GITOPS_PATH//\//-}-gitops
  namespace: gitops-system
spec:
  interval: 1m0s
  ref:
    branch: ${GITOPS_BRANCH}
  url: ${GITOPS_REPO}
EOF_CONFIG

cat <<EOF_KUSTOMIZE > kustomization.yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: ${GITOPS_PATH//\//-}-sync
  namespace: gitops-system
spec:
  interval: 1m0s
  sourceRef:
    kind: GitRepository
    name: ${GITOPS_PATH//\//-}-gitops
  path: ./${GITOPS_PATH}
  prune: true
  wait: true
EOF_KUSTOMIZE

kubectl apply -f git-repository.yaml
kubectl apply -f kustomization.yaml
