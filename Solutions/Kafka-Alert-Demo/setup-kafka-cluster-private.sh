helm repo add bitnami https://charts.bitnami.com/bitnami
#helm repo update
kubectl create namespace kafka || true
#helm upgrade --install kafka bitnami/kafka --namespace kafka \
helm upgrade --install kafka kafka-31.1.1.tgz --namespace kafka \
  --set global.security.allowInsecureImages=true             \
  --set image.registry='images.onwalk.net'  \
  --set image.repository='public/kafka'     \
  --set image.tag='3.9.0-debian-12-r4'      \
  --set replicaCount=3                      \
  --set sasl.enabledMechanisms="PLAIN"      \
  --set sasl.interBrokerMechanism=PLAIN     \
  --set sasl.controllerMechanism=PLAIN      \
  --set rbac.create=true                    \
  --set sasl.client.users[0]=user1          \
  --set sasl.client.passwords="test"        \
  --set persistence.enabled=true            \
  --set persistence.size=8Gi                \
  --set externalZookeeper.enabled=false     \
  --set zookeeper.enabled=false
kubectl get pods --namespace kafka
kubectl get svc --namespace kafka
