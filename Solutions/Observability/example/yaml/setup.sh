cat > vaules.yaml << EOF
server:
  ingress:
    enabled: true
    ingressClassName: "nginx"
    hosts:
      - host: vault.onwalk.net
        paths:
          - /
    tls:
      - secretName: vault-tls
        hosts:
          - vault.onwalk.net
EOF

helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo up
kubectl create ns vault || echo true
kubectl create secret tls vault-tls  --key=/etc/ssl/onwalk.net.key --cert=/etc/ssl/onwalk.net.pem -n vault
helm upgrade --install vault-server hashicorp/vault -n vault --create-namespace -f vaules.yaml
