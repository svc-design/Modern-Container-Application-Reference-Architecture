helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
kubectl create namespace redis
helm upgrade --install redis bitnami/redis --namespace redis \
  --set global.security.allowInsecureImages=true             \
  --set architecture=standalone                              \
  --set image.registry="images.onwalk.net"                   \
  --set image.repository="public/redis"                      \
  --set image.tag="7.4.1-debian-12-r3"                       \
  --set auth.enabled=false                                   \
  --set cluster.enabled=false                                \
  --set cluster.nodes=1                                      \
  --set persistence.enabled=true                             \
  --set persistence.size=8Gi
kubectl get pods --namespace redis
kubectl get svc --namespace redis
