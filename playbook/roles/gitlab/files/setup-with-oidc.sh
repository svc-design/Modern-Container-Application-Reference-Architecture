#!/bin/bash

domain=$1
namespace=$2
object_bucket=$3
gitlab_secret=$4
gitlab_stmp_secret=$5
smtp_port=$7
smtp_domain=$8
smtp_address=$9
smtp_username=$10
smtp_emailfrom=$11
smtp_display_name=$12
oidc_issuer_url=$13
oidc_client_id=$14
oidc_client_token=$15

cat > gitlab-values.yaml <<EOF
global:
  edition: ce
  hosts:
    https: true
    domain: $domain
    gitlab:
      name: gitlab.$domain
  ingress:
    class: nginx
    enabled: true
    configureCertmanager: false
    tls:
      enabled: true
      secretName: ${gitlab_secret}
  minio:
    enabled: true
  appConfig:
    email:
      from: $smtp_emailfrom
      display_name: $smtp_display_name
    smtp:
      tls: true
      enabled: true
      port: $smtp_port
      domain: $smtp_domain
      address: $smtp_address
      user_name: $smtp_username
      password:
        secret: $gitlab_smtp_secret
        key: password
      authentication: "login"
      starttls_auto: true
      openssl_verify_mode: "peer"
      pool: true
    omniauth:
      enabled: true
      syncProfileAttributes: [email]
      allowSingleSignOn: ['openid_connect']
      autoLinkLdapUser: false
      autoLinkSamlUser: false
      providers:
        - name: 'openid_connect'
          label: 'keycloak_oidc'
          args:
            discovery: true
            response_type: 'code'
            name: 'openid_connect'
            uid_field: 'gltlab_openid'
            client_auth_method: 'query'
            issuer: $oidc_issuer_url
            scope: ['openid','profile','email']
            send_scope_to_token_endpoint: false
            client_options:
              identifier: $oidc_client_id
              secret: $oidc_client_token
              redirect_uri: 'https://gitlab.${domain}/users/auth/openid_connect/callback'
registry:
  enabled: true
  ingress:
    enabled: false
gitlab-exporter:
  enabled: false
kas:
  enabled: false
nginx-ingress:
  enabled: false
prometheus:
  install: false
redis:
  metrics:
    enabled: false
postgresql:
  metrics:
    enabled: false
certmanager:
  install: false
  installCRDs: false
  startupapicheck:
    enabled: false
upgradeCheck:
  enabled: false
EOF

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
helm repo add gitlab https://charts.gitlab.io/
helm repo up
kubectl create namespace gitlab || true
helm upgrade --install gitlab gitlab/gitlab --version=6.6.1 --namespace gitlab -f gitlab-values.yaml
