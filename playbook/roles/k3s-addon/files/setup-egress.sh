#!/bin/bash
ip=$1
namespace=$2

cat > /tmp/egress.yaml << EOF
apiVersion: cilium.io/v2
kind: CiliumEgressGatewayPolicy
metadata:
  name: egress-nat-policy
spec:
  selectors:
  - podSelector:
      matchLabels:
        role: egress-gateway
        io.kubernetes.pod.namespace: $namespace
  destinationCIDRs:
  - "0.0.0.0/0"
  egressGateway:
    nodeSelector:
      matchLabels:
        node.kubernetes.io/name: tky-connector.onwalk.net
    egressIP: $ip
EOF
kubectl apply -f /tmp/egress.yaml
