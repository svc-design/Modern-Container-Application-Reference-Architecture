#!/bin/bash

domain=$1
namespace=$2
admin_password=$3
secret_name=$4
storage_type=$5

cat > values.yaml << EOF
env:
  open:
    STORAGE: local
    DISABLE_API: false
    AUTH_ANONYMOUS_GET: true
  secret:
    BASIC_AUTH_USER: admin
    BASIC_AUTH_PASS: '$admin_password'
ingress:
  enabled: true
  hosts:
    - name: charts.$domain
      path: /
      tls: true
      tlsSecret: $secret_name
  ingressClassName: nginx
persistence:
  enabled: true
  accessMode: ReadWriteOnce
  size: 8Gi
  path: /storage
  storageClass: "local-path"
EOF

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
helm repo add chartmuseum https://chartmuseum.github.io/charts
helm repo update
helm upgrade --install chartmuseum chartmuseum/chartmuseum -f values.yaml -n $namespace
