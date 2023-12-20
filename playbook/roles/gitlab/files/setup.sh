#!/bin/bash

check_empty() {
  if [ -z "$1" ]; then
    echo "$2"
    exit 1
  fi
}

check_empty "$1" "Please provide a version name as the first argument"
check_empty "$2" "Please provide a domain name as the second argument"
check_empty "$3" "Please provide a namespace as the third argument"
check_empty "$4" "Please provide a GitLab secret as the fourth argument"
check_empty "$5" "Please provide a GitLab database secret as the fifth argument"
check_empty "$6" "Please provide a GitLab SSO secret as the sixth argument"
check_empty "$7" "Please provide a GitLab SMTP secret as the seventh argument"
check_empty "$8" "Please provide a GitLab Redis secret as the eighth argument"

version=$1
domain=$2
namespace=$3
gitlab_secret=$4
gitlab_db_secret=$5
gitlab_sso_secret=$6
gitlab_smtp_secret=$7
gitlab_redis_secret=$8

cat > gitlab-values.yaml <<EOF
global:
  edition: ce
  hosts:
    domain: $domain
    gitlab:
      name: gitlab.$domain
    https: true
  ingress:
    class: nginx
    configureCertmanager: false
    enabled: true
    tls:
      enabled: true
      secretName: $gitlab_secret
  minio:
    enabled: true
  gitaly:
    persistence:
      enabled: true
  psql:
    host: postgresql.database.svc.cluster.local
    port: 5432
    username: postgres
    database: gitlabhq_production
    password:
      secret: $gitlab_db_secret
      key: password
  redis:
    host: redis-master.redis.svc.cluster.local
    port: 6379
    password:
      enabled: true
      secret: $gitlab_redis_secret
      key: password
  email:
    from: 'manbuzhe2009@qq.com'
    display_name: GitLab-System
  smtp:
    tls: true
    pool: true
    port: 465
    enabled: true
    domain: exmail.qq.com
    address: smtp.exmail.qq.com
    user_name: 'manbuzhe2009@qq.com'
    password:
      secret: $gitlab_smtp_secret
      key: password
    authentication: "login"
    starttls_auto: false
    openssl_verify_mode: "peer"
  appConfig:
    omniauth:
      enabled: true
      autoLinkLdapUser: false
      autoLinkSamlUser: false
      blockAutoCreatedUsers: false
      autoSignInWithProvider: null
      autoLinkUser:
        - 'openid_connect'
      allowSingleSignOn:
        - 'openid_connect'
      providers:
      - secret: $gitlab_sso_secret
        key: provider
certmanager:
  install: false
  installCRDs: false
  startupapicheck:
    enabled: false
postgresql:
  install: false
redis:
  install: false
kas:
  enabled: false
nginx-ingress:
  enabled: false
gitlab-exporter:
  enabled: false
prometheus:
  install: false
upgradeCheck:
  enabled: false
EOF

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
helm repo add gitlab https://charts.gitlab.io/
helm repo up
kubectl create namespace gitlab || true
helm upgrade --install gitlab gitlab/gitlab --version=$version --namespace gitlab -f gitlab-values.yaml --timeout=3m --debug
