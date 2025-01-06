kubectl create namespace kafka
helm install kafka bitnami/kafka --namespace kafka \
  --set replicaCount=3 \
  --set persistence.enabled=true \
  --set persistence.size=8Gi \
  --set externalZookeeper.enabled=false \
  --set zookeeper.enabled=true
kubectl get pods --namespace kafka
kubectl get svc --namespace kafka
