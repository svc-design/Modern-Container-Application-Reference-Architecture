#!/bin/bash
cat > prometheus-values.yaml << EOF
global:
  imageRegistry: "artifact.onwalk.net/base"
prometheus:
  enabled: false
defaultRules:
  create: false
grafana:
  enabled: false
prometheus-windows-exporter:
  enabled: false
alertmanager:
  enabled: false
EOF

node_name=`kubectl get nodes | awk 'NR>1 {print $1}'`
kubectl create namespace monitoring || echo true
kubectl label nodes $node prometheus=true --overwrite || echo true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install prometheus-agent prometheus-community/kube-prometheus-stack -n monitoring -f prometheus-values.yaml
