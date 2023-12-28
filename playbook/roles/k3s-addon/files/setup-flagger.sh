#!/bin/bash

# 检查参数是否为空
check_not_empty() {
  if [[ -z $1 ]]; then
    echo "Error: $2 is empty. Please provide a value."
    exit 1
  fi
}

# 检查参数是否为空
check_not_empty "$1" "DOMAIN" && DOMAIN=$1

helm repo add flagger https://flagger.app
helm repo update
kubectl create ns ingress || echo true
helm upgrade -i flagger flagger/flagger           \
--namespace ingress                               \
--set prometheus.install=false                    \
--set meshProvider=nginx                          \
--set metricsServer="https://prometheus.${DOMAIN}"
