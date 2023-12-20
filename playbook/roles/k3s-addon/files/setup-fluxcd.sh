#!/bin/bash

# 检查参数是否为空
check_not_empty() {
  if [[ -z $1 ]]; then
    echo "Error: $2 is empty. Please provide a value."
    exit 1
  fi
}

# 检查参数是否为空
check_not_empty "$1" "Git repository URL" && git_repo=$1
check_not_empty "$2" "Cluster name" && cluster_name=$2

helm repo add fluxcd https://fluxcd-community.github.io/helm-charts
helm repo update
kubectl create namespace gitops-system || true
helm upgrade --install fluxcd fluxcd/flux2 --version 2.12.1 -n gitops-system

cat > cluster-config.yaml << EOF
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: GitRepository
metadata:
  name: stable
  namespace: gitops-system
spec:
  interval: 1m0s
  ref:
    branch: main 
  url: $git_repo 
---
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: cluster
  namespace: gitops-system
spec:
  interval: 1m0s
  sourceRef:
    kind: GitRepository
    name: stable
  path: ./clusters/${cluster_name}
  prune: true
EOF

kubectl apply -f cluster-config.yaml && rm cluster-config.yaml -f
