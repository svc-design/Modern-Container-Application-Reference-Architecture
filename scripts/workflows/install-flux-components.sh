#!/usr/bin/env bash
set -euo pipefail

kubectl create namespace gitops-system --dry-run=client -o yaml | kubectl apply -f -
flux install --namespace=gitops-system --components-extra=image-reflector-controller,image-automation-controller
