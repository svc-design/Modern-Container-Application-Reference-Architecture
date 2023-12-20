#!/bin/bash

# 检查参数是否为空
check_not_empty() {
  if [[ -z $1 ]]; then
    echo "Error: $2 is empty. Please provide prometheus-server URL."
    exit 1
  fi
}

# 检查参数是否为空
check_not_empty "$1" "Git repository URL" && git_repo=$1
check_not_empty "$2" "Git repository URL" && git_repo=$1

helm repo add flagger https://flagger.app
helm repo update
helm upgrade -i flagger flagger/flagger           \
--namespace ingress-nginx                         \
--set prometheus.install=false                    \
--set meshProvider=nginx                          \
--set metricsServer="https://prometheus.svc.plus" \
