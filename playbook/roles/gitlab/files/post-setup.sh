#!/bin/bash

kubectl  delete hpa --all -A

# 获取所有部署
DEPLOYMENTS=$(kubectl get deploy -n gitlab -o jsonpath='{.items[*].metadata.name}')

# 遍历部署并设置副本数为1
for DEPLOY in $DEPLOYMENTS
do
  echo "Setting replicas=1 for deployment $DEPLOY"
  kubectl scale deploy/$DEPLOY -n gitlab --replicas=1
done

# 遍历部署并获取 CPU 和内存配置
for DEPLOY in $DEPLOYMENTS
do
  echo "Deployment: $DEPLOY"
  echo "===================="
  kubectl get deploy $DEPLOY -n gitlab -o=jsonpath='{range .spec.template.spec.containers[*]}{.name}:{"\n"}{"\t"}cpu: {.resources.requests.cpu}{"\n"}{"\t"}mem: {.resources.requests.memory}{"\n"}{end}'
  echo "===================="
done

# 遍历部署并设置 CPU 和内存请求
#for DEPLOY in $DEPLOYMENTS
#do
#  echo "Setting cpu=0.1 and mem=100m for deployment $DEPLOY"
#  kubectl patch deployment $DEPLOY -n gitlab -p '{"spec": {"template": {"spec": {"containers": [{"name": "'$DEPLOY'", "resources": {"requests": {"cpu": "0.1", "memory": "100m"}}}]}}}}'
#  echo "===================="
#done
