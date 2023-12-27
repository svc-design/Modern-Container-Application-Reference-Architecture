#!/bin/bash

# 检查参数是否为空
check_not_empty() {
  if [[ -z $1 ]]; then
    echo "Error: $2 is empty. Please provide a value."
    exit 1
  fi
}

# 检查参数是否为空
check_not_empty "$1" "DNS_AK" && DNS_AK=$1
check_not_empty "$2" "DNS_SK" && DNS_SK=$2
check_not_empty "$3" "DOMAIN" && DOMAIN=$3

# Deploy external-dns
cat > external-dns-values.yaml << EOF
clusterDomain: admin.local
sources:
  - service
  - ingress
domainFilters:
  - $DOMAIN
policy: upsert-only
provider: alibabacloud
alibabacloud:
  accessKeyId: $DNS_AK
  accessKeySecret: $DNS_SK
  regionId: rg-acfm2akhd255pgi
  zoneType: public
EOF

helm repo add bitnami https://charts.bitnami.com/bitnami || echo true
helm repo update
kubectl create namespace external-dns || echo true
helm upgrade --install external-dns -f external-dns-values.yaml bitnami/external-dns -n external-dns
