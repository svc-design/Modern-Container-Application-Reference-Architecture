#!/bin/bash

# Function to check if a variable is empty
check_empty() {
    if [ -z "${!1}" ]; then
        echo "$1 is empty. Aborting."
        exit 1
    fi
}

# List of variables to check ; Loop through variables and check if each one is empty

variables=("ak" "sk" "domain")
for var in "${variables[@]}"; do
    check_empty "$var"
done

ak=$1
sk=$2
domain=$3

cat > external-dns-values.yaml << EOF
clusterDomain: admin.local
sources:
  - service
  - ingress
domainFilters:
  - $domain
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
