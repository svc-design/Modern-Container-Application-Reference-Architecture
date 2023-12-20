#!/bin/bash

export domain=$1
export secret=$2
export namespace=$3
export keycloak_ui_password=$4
export keycloak_db_password=$5

cat > keycloak-values.yaml << EOF
proxy: reencrypt
auth:
  adminPassword: "$keycloak_ui_password"
ingress:
  enabled: true
  ingressClassName: "nginx"
  hostname: keycloak.${domain}
  tls: true
  extraTls:
  - hosts:
      - keycloak.${domain}
    secretName: $secret
postgresql:
  enabled: false
externalDatabase:
  host: "postgresql.database.svc.cluster.local"
  port: 5432
  user: postgres
  database: keycloak
  password: "$keycloak_db_password"
EOF

helm repo add bitnami https://charts.bitnami.com/bitnami || echo true
helm repo update
kubectl create ns ${namespace} || echo true
helm upgrade --install keycloak bitnami/keycloak -n $namespace -f keycloak-values.yaml
