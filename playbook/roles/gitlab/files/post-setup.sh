#!/bin/bash

# 获取所有部署
DEPLOYMENTS=$(kubectl get deploy -n gitlab -o jsonpath='{.items[*].metadata.name}')

# 遍历部署并设置副本数为1
for DEPLOY in $DEPLOYMENTS
do
  echo "Setting replicas=1 for deployment $DEPLOY"
  kubectl scale deploy/$DEPLOY -n gitlab --replicas=1
done
