helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo up
kubectl create ns redis
helm upgrade --install redis bitnami/redis --set architecture=standalone -n redis
