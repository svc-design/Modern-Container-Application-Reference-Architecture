#!/bin/bash

ak=$1
sk=$2
domain=$3
namespace=$4
secret_name=$5
redis_password=$6
pg_db_password=$7
storage_type=$8

cat > harbor-arm-config.yaml << EOF
portal:
  image:
    repository: ghcr.io/octohelm/harbor/harbor-portal
    tag: v2.7.0@sha256:b3f4e0e990500362b554338579497ad89af5473e024564731563704ceab9305b
core:
  image:
    repository: ghcr.io/octohelm/harbor/harbor-core
    tag: v2.7.0@sha256:dd7f3898f32caf8e03cee046596f03034f4297231458d4de39775dd58709b55a 
jobservice:
  image:
    repository: ghcr.io/octohelm/harbor/harbor-jobservice
    tag: v2.7.0@sha256:7abd6694f546172ffec4a87e389e8ba425fa6ee82479782693c120a89a291435
registry:
  registry:
    image:
      repository: ghcr.io/octohelm/harbor/registry-photon
      tag: v2.7.0@sha256:d5f23b2bc4271b2eb1ec002eb0c0c51e708015944316e5bd17c61de73ea54415
  controller:
    image:
      repository: ghcr.io/svc-design/harbor-multi-arch-images/harbor-registryctl
      tag: v2.7.0@sha256:ba2412c1a629ca1c2ca4584ba51eb05e964c7eef7b1f9f6ddb39d67512debaf5 
chartmuseum:
  enabled: true
  image:
    repository: ghcr.io/octohelm/harbor/chartmuseum-photon
    tag: v2.7.0@sha256:0815066d46474b9403b2d2e5f6f9e2ae44d067d8d2f8523b95ea3d3f20f3d058
trivy:
  enabled: false
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
      core: harbor.${domain}
      notary: artifact-notary.${domain}
    className: "nginx"
externalURL: https://artifact.${domain}
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
    type: $storage_type
    oss:
      accesskeyid: $ak
      accesskeysecret: $sk
      region: "oss-cn-wulanchabu"
      bucket: "harbor-s3"
      endpoint: "oss-cn-wulanchabu.aliyuncs.com"
    s3:
      region: ap-east-1
      bucket: artifact-s3
      accesskey: $ak
      secretkey: $sk
EOF

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
helm repo add harbor https://helm.goharbor.io
helm repo update
helm upgrade --install artifact harbor/harbor -f harbor-arm-config.yaml --version 1.11.1 -n $namespace
