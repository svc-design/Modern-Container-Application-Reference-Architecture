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
portal:
  image:
    repository: artifact.onwalk.net/public/harbor-portal
    tag: v2.7.1
core:
  image:
    repository: goharbor/harbor-core
    tag: v2.7.1
jobservice:
  image:
    repository: goharbor/harbor-jobservice
    tag: v2.7.1
registry:
  registry:
    image:
      repository: goharbor/registry-photon
      tag: v2.7.1
  controller:
    image:
      repository: goharbor/harbor-registryctl
      tag: v2.7.1
trivy:
  image:
    repository: goharbor/trivy-adapter-photon
    tag: v2.7.1
notary:
  server:
    image:
      repository: goharbor/notary-server-photon
      tag: v2.7.1
  signer:
    image:
      repository: goharbor/notary-signer-photon
      tag: v2.7.1
notary:
  enabled: false
expose:
  type: ingress
  tls:
    enabled: true
    certSource: secret
    secret:
      secretName: $secret_name
      notarySecretName: $secret_name
  ingress:
    hosts:
      core: artifact.${domain}
      notary: artifact.${domain}
    className: "nginx"
externalURL: https://harbor.${domain}
database:
  type: external
  external:
    host: "postgresql.database.svc.cluster.local"
    port: "5432"
    username: "postgres"
    password: "$pg_db_password"
    coreDatabase: "registry"
    notaryServerDatabase: "notary_server"
    notarySignerDatabase: "notary_signer"
redis:
  type: external
  external:
    addr: "redis-master.redis.svc.cluster.local:6379"
    password: "$redis_password"
persistence:
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
helm repo add harbor https://helm.goharbor.io
helm repo update
helm upgrade --install artifact harbor/harbor -f harbor-config.yaml --version 1.11.1 -n $namespace
