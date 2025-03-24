cat > value.yaml <<EOF
controller:
  nginxplus: false
  ingressClass: nginx
  replicaCount: 2
  service:
    enabled: true
    type: NodePort
    externalIPs:
      - 52.196.108.28
  tolerations:
  - key: "gateway"
    operator: "Equal"
    value: "true"
    effect: "NoExecute"
EOF
cat > nginx-cm.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-nginx-ingress
  namespace: ingress
data:
  use-ssl-certificate-for-ingress: "false"
  external-status-address: 52.196.108.28
  proxy-connect-timeout: 30s
  proxy-read-timeout: 30s
  client-header-buffer-size: 64k
  client-body-buffer-size: 64k
  client-max-body-size: 1000m
  proxy-buffers: 8 32k
  proxy-body-size: 1024m
  proxy-buffer-size: 32k
EOF
cat > nginx-svc-patch.yaml <<EOF
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
helm repo update
kubectl create namespace ingress || echo true
helm upgrade --install nginx nginx-stable/nginx-ingress --version=0.15.0 --namespace ingress -f value.yaml
kubectl apply -f nginx-cm.yaml
kubectl patch svc nginx-nginx-ingress -n ingress --patch-file nginx-svc-patch.yaml
