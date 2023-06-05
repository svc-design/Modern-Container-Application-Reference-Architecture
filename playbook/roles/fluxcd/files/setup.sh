#!/bin/bash

export version=$1
export namespace=$2

cat > flux-values.yaml << EOF
imagePullSecrets:
  - name: artifact-registry-tls
cli:
  image: artifact.roche.com.cn/cpc-iac-docker-prd-l/flux-cli
  tag: v0.31.3-customized
helmcontroller:
  create: true
  image: artifact.roche.com.cn/cpc-iac-docker-prd-l/flux-helm-controller
  tag: v0.22.1-customized
imageautomationcontroller:
  image: artifact.roche.com.cn/cpc-iac-docker-prd-l/flux-image-automation-controller
  tag: v0.23.4-customized
imagereflectorcontroller:
  create: true
  image: artifact.roche.com.cn/cpc-iac-docker-prd-l/flux-image-reflector-controller
  tag: v0.19.2-customized
kustomizecontroller:
  create: true
  image: artifact.roche.com.cn/cpc-iac-docker-prd-l/flux-kustomize-controller
  tag: v0.26.2-customized
notificationcontroller:
  create: true
  image: artifact.roche.com.cn/cpc-iac-docker-prd-l/flux-notification-controller
  tag: v0.24.0-customized
sourcecontroller:
  create: true
  image: artifact.roche.com.cn/cpc-iac-docker-prd-l/flux-source-controller
  tag: v0.24.0-customized
EOF

helm repo add fluxcd https://fluxcd-community.github.io/helm-charts
helm repo update
kubectl create namespace $namespace || echo true
helm upgrade --install fluxcd fluxcd/flux2 -n $namespace --version=$version
