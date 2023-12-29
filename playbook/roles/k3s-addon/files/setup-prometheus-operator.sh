#!/bin/bash

# 检查参数是否为空
check_not_empty() {
  if [[ -z $1 ]]; then
    echo "Error: $2 is empty. Please provide a value."
    exit 1
  fi
}

# 检查参数是否为空
check_not_empty "$1" "DOMAIN" && DOMAIN=$1

cat > prometheus-values.yaml << EOF
global:
  imageRegistry: "artifact.onwalk.net/base"
prometheus:
  enabled: true
  agentMode: false
  prometheusSpec:
    remoteWrite:
    - name: remote_prometheus
      url: 'https://prometheus.${DOMAIN}/api/v1/write'
    retention: 30m
    resources:
      requests:
        cpu: 200m
        memory: 200Mi
    podMonitorNamespaceSelector: { }
    podMonitorSelector:
      matchLabels:
        app.kubernetes.io/component: monitoring
nodeExporter:
  enabled: true
kubeStateMetrics:
  enabled: true
grafana:
  enabled: false
prometheus-windows-exporter:
  enabled: false
alertmanager:
  enabled: false
defaultRules:
  create: false
EOF

node_name=`kubectl get nodes | awk 'NR>1 {print $1}'`
kubectl create namespace monitoring || echo true
kubectl label nodes $node prometheus=true --overwrite || echo true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install prometheus-agent prometheus-community/kube-prometheus-stack -n monitoring -f prometheus-values.yaml
