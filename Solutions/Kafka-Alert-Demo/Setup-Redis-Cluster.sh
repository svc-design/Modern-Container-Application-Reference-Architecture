helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
kubectl create namespace redis
helm install redis bitnami/redis-cluster --namespace redis \
  --set cluster.enabled=true \
  --set cluster.nodes=6 \
  --set persistence.enabled=true \
  --set persistence.size=8Gi
kubectl get pods --namespace redis
kubectl get svc --namespace redis
