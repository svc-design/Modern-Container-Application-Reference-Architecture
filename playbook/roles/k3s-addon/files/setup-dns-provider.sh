#!/bin/bash

ak=$1
sk=$2

cat > external-dns-values.yaml << EOF
clusterDomain: admin.local
sources:
  - service
  - ingress
domainFilters:
  - onwalk.net
policy: upsert-only
provider: alibabacloud
alibabacloud:
  accessKeyId: $ak
  accessKeySecret: $sk
  regionId: rg-acfm2akhd255pgi
  zoneType: public
EOF

helm repo add bitnami https://charts.bitnami.com/bitnami || echo true
helm repo update
kubectl create namespace external-dns || echo true
helm upgrade --install external-dns -f external-dns-values.yaml bitnami/external-dns -n external-dns
