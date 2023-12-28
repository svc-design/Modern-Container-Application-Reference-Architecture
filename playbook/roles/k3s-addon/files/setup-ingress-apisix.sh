#!/bin/bash

ingress_ip=$1

helm repo add apisix https://charts.apiseven.com || echo true
helm repo update
kubectl create ns ingress || echo true
cat > values.yaml << EOF
ingress-controller:
  enabled: true
  config:
    apisix:
      serviceNamespace: ingress
etcd:
  replicaCount: 1
gateway:
  enabled: true
  type: NodePort
  http:
    enabled: true
    nodePort: 80
  tls:
    enabled: true
    nodePort: 443
  externalIPs:
    - $ingress_ip
discovery:
  enabled: true
admin:
  enabled: false
EOF
helm upgrade --install apisix apisix/apisix --namespace ingress -f values.yaml
