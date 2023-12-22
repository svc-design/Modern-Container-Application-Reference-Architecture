#!/bin/bash
set -x
export domain=$1
export deepflowserverip=$2
export deepflowk8sclusterid=$3

cat > values.yaml << EOF
deepflow-agent:
  enabled: true
  deepflowServerNodeIPS:
    - $deepflowserverip
  deepflowK8sClusterID: $deepflowk8sclusterid
prometheus:
  enabled: false
  server:
    extraFlags:
    - enable-feature=expand-external-labels
    - web.enable-lifecycle
    remoteWrite:
    - name: remote_prometheus
      url: 'https://prometheus.${domain}/api/v1/write'
  alertmanager:
    enabled: false
  rometheus-pushgateway:
    enabled: false
promtail:
  enabled: true
  config:
    clients:
      - url: https://data-gateway.${domain}/loki/api/v1/push
EOF

node_name=`kubectl get nodes | awk 'NR>1 {print $1}'`
kubectl create namespace monitoring || echo true
kubectl label nodes $node prometheus=true --overwrite || echo true
helm repo add stable https://charts.onwalk.net/ || echo true
helm repo update
helm upgrade --install observableagent stable/observabilityagent -n monitoring -f values.yaml

cat > prometheus-agent-values.yaml << EOF
prometheus:
  agentMode: true
  prometheusSpec:
    remoteWrite:
    - name: remote_prometheus
      url: 'https://prometheus.svc.ink/api/v1/write'
    retention: 24h
    resources:
      requests:
        cpu: 200m
        memory: 200Mi
    podMonitorNamespaceSelector: { }
    podMonitorSelector:
      matchLabels:
        app.kubernetes.io/component: monitoring
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
helm repo add stable https://charts.onwalk.net/ || echo true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install prometheus-agent prometheus-community/kube-prometheus-stack -n monitoring -f prometheus-agent-values.yaml
