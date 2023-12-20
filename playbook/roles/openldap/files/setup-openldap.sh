#!/bin/bash

export domain=$1
export secret=$2
export namespace=$3
export password=$4

cat > openldap-vaules.yaml << EOF
global:
  ldapDomain: $domain
  adminPassword: $password
  configPassword: $password
service:
  type: NodePort
  ldapPortNodePort: 389
  sslLdapPortNodePort: 636
phpldapadmin:
  enabled: true
  ingress:
    enabled: true
    ingressClassName: nginx
    hosts:
      - openldap-admin.${domain}
    tls:
    - secretName: ${secret}
      hosts:
      - openldap-admin.${domain}
ltb-passwd:
  enabled: true
  ingress:
    enabled: true
    ingressClassName: nginx
    hosts:
      - openldap-ltb.${domain}
    tls:
    - secretName: ${secret}
      hosts:
      - openldap-ltb.${domain}
EOF

helm repo add openldap https://jp-gouin.github.io/helm-openldap/
helm repo up
kubectl create ns ${namespace} || echo true
helm upgrade --install openldap openldap/openldap-stack-ha -n ${namespace} --create-namespace -f openldap-vaules.yaml
