#!/bin/bash
ingress=$1
ingress_ip=$2

if [[ $ingress == "default" ]]; then
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
helm repo add stable https://kubernetes.github.io/ingress-nginx
helm repo up

cat > value.yaml <<EOF
controller:
  name: controller
  config:
    use-http2: true
  ingressClassResource:
    name: nginx
  replicaCount: 2
  service:
    enabled: true
    type: NodePort
    externalIPs:
      - $ingress_ip
    nodePorts:
      http: 80
      https: 443
  admissionWebhooks:
    patch:
      enabled: true
defaultBackend:
  enabled: true
tcp:
  22: "gitlab/gitlab-gitlab-shell:22"
EOF

cat > svc-patch.yaml <<EOF
spec:
  ports:
  - name: 22-tcp
    nodePort: 22
    port: 22
    protocol: TCP
    targetPort: 22-tcp
EOF

kubectl create namespace ingress || echo true
helm upgrade --install nginx stable/ingress-nginx --namespace ingress -f value.yaml
kubectl patch svc nginx-ingress-nginx-controller -n ingress --patch-file svc-patch.yaml
kubectl delete pods --all -n ingress

elif [[ $ingress == "nginx" ]]; then
cat > value.yaml <<EOF
controller:
  nginxplus: false
  ingressClass: nginx
  replicaCount: 2
  service:
    enabled: true
    type: NodePort
    externalIPs:
      - $ingress_ip
EOF

cat > nginx-cm.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-nginx-ingress
  namespace: ingress
data:
  use-ssl-certificate-for-ingress: "false"
  external-status-address: $ingress_ip
  proxy-connect-timeout: 10s
  proxy-read-timeout: 10s
  client-header-buffer-size: 64k
  client-body-buffer-size: 64k
  client-max-body-size: 1000m
  proxy-buffers: 8 32k
  proxy-body-size: 1024m
  proxy-buffer-size: 32k
  proxy-connect-timeout: 10s
  proxy-read-timeout: 10s
EOF

cat > nginx-svc-patch.yaml << EOF
spec:
  ports:
  - name: http
    nodePort: 80
    port: 80
    protocol: TCP
    targetPort: 80
  - name: https
    nodePort: 443
    port: 443
    protocol: TCP
    targetPort: 443
EOF

helm repo add nginx-stable https://helm.nginx.com/stable || echo true
helm repo up
kubectl create namespace ingress || echo true
helm upgrade --install nginx nginx-stable/nginx-ingress --version=0.15.0 --namespace ingress -f value.yaml
kubectl apply -f nginx-cm.yaml
kubectl patch svc nginx-nginx-ingress -n ingress --patch-file nginx-svc-patch.yaml

elif [[ $ingress == "apisix" ]]; then

helm repo add apisix https://charts.apiseven.com || echo true
helm repo update
kubectl create ns ingress || echo true
cat > values.yaml << EOF
ingress-controller:
  enabled: true
  config:
    apisix:
      serviceNamespace: ingress
etcd:
  replicaCount: 1
gateway:
  enabled: true
  type: NodePort
  http:
    enabled: true
    nodePort: 80
  tls:
    enabled: true
    nodePort: 443
  externalIPs:
    - $ingress_ip
discovery:
  enabled: true
admin:
  enabled: true
  ingress:
    className: apisix
    enabled: true
    hosts:
      - host: apisix-admin.onwalk.net
        paths:
          - "/apisix"
    tls:
      - secretName: apisix-tls
        hosts:
          - apisix-admin.onwalk.net
EOF
helm upgrade --install apisix apisix/apisix --namespace ingress -f values.yaml
fi
