#!/bin/bash

ingress_ip=$1

helm repo add apisix https://charts.apiseven.com || echo true
helm repo update
kubectl create ns ingress || echo true
cat > values.yaml << EOF
config:
  etcdserver:
    enabled: false
  apisix:
    serviceName: apisix-admin
    serviceNamespace: ingress
gateway:
  type: NodePort
  tls:
    enabled: true
    nodePort: 443
  externalIPs:
    - $ingress_ip
serviceMonitor:
  enabled: true
  namespace: "monitoring"
  interval: 15s
EOF
helm upgrade --install apisix apisix/apisix-ingress-controller --namespace ingress -f values.yaml
