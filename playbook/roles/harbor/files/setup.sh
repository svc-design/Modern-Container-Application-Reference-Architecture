#!/bin/bash

ak=$1
sk=$2
domain=$3
namespace=$4
secret_name=$5
redis_password=$6
pg_db_password=$7
storage_type=$8

cat > harbor-config.yaml << EOF
ingress:
  enabled: true
  core:
    ingressClassName: "nginx"
    extraTls:
      - hosts:
        - core.harbor.domain
          secretName: "$secret_name"
externalURL: https://harbor.onwalk.net

postgresql:
  enabled: false
redis:
  enabled: false

externalDatabase:
  host: postgresql.database.svc.cluster.local
  user: postgres
  port: 5432
  password: "$pg_db_password"
  sslmode: disable
  coreDatabase: harbor_core
  clairDatabase: harbor_clair
  clairUsername: "postgres"
  clairPassword: "$pg_db_password"
  notaryServerDatabase: harbor_notary_server
  notaryServerUsername: "postgres"
  notaryServerPassword: "$pg_db_password"
  notarySignerDatabase: harbor_notary_signer
  notarySignerUsername: "postgres"
  notarySignerPassword: "$pg_db_password"
externalRedis:
  host: redis-master.redis.svc.cluster.local
  port: 6379
  password: "$redis_password"
persistence:
  enabled: true
  imageChartStorage:
EOF

if [[ "$storage_type" == 'oss' ]] ; then
cat >> harbor-config.yaml << EOF
    type: oss
    oss:
      accesskeyid: $ak
      accesskeysecret: $sk
      region: "oss-cn-wulanchabu"
      bucket: "harbor-s3"
      endpoint: "oss-cn-wulanchabu.aliyuncs.com"
EOF
fi

if [[ "$storage_type" == 's3' ]] ; then
cat >> harbor-config.yaml << EOF
    type: s3
    s3:
      region: cn-northwest-1
      bucket: apollo-artifact
      accesskey: $ak
      secretkey: $sk
EOF
fi

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm upgrade --install artifact bitnami/harbor -f harbor-config.yaml --version 16.4.10 -n $namespace
