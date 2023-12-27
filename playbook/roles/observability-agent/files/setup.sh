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
helm upgrade --install observabilityagent stable/observabilityagent -n monitoring -f values.yaml
