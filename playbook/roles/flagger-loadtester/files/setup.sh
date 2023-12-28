#!/bin/bash
set -x

# 检查参数是否为空
check_not_empty() {
  if [[ -z $1 ]]; then
    echo "Error: $2 is empty. Please provide a value."
    exit 1
  fi
}

# 检查参数是否为空
check_not_empty "$1" "DOMAIN" && DOMAIN=$1

helm repo add flagger https://flagger.app
kubectl create ns monitoring || true
helm upgrade -i flaggerloadtester flagger/loadtester --namespace=monitoring

cat > flagger-loadtester-ingress.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  name: flagger
  namespace: monitoring
spec:
  ingressClassName: apisix
  rules:
  - host: flaggerloadtester.${DOMAIN}
    http:
      paths:
      - backend:
          service:
            name: flagger-loadtester
            port:
              number: 80
        path: /
        pathType: Prefix
  tls:
  - hosts:
    - flaggerloadtester.${DOMAIN}
    secretName: obs-tls
EOF

kubectl apply -f flagger-loadtester-ingress.yaml

