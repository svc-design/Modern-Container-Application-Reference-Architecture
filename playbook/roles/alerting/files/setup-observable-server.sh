#!/bin/bash

export domain=$1
export secret=$2
export namespace=$3
export mysql_db_password=$4

kubectl label nodes k3s-server prometheus=true --overwrite

cat > values.yaml << EOF
deepflow:
  enabled: true
  clickhouse:
    enabled: false
  mysql:
    enabled: false
  grafana:
    enabled: true
    ingress:
      enabled: true
      ingressClassName: nginx
      hosts:
        - grafana.${domain}
      tls:
        - secretName: ${secret}
          hosts:
            - grafana.${domain}
  global:
    externalClickHouse:
      enabled: true
      type: ep
      clusterName: default
      storagePolicy: default
      username: default
      password: ''
      hosts:
      - ip: 10.1.2.3
        port: 9000
      - ip: 10.1.2.4
        port: 9000
      - ip: 10.1.2.5
        port: 9000
    externalMySQL:
      enabled: true
      ip: mysql.database.svc.cluster.local
      port: 3306
      username: root
      password: {{ mysql_db_password }}
prometheus:
  enabled: true
  alertmanager:
    enabled: false
  prometheus-pushgateway:
    enabled: false
  kube-state-metrics:
    enabled: false
  server:
    ingress:
      ingressClassName: nginx
      hosts:
        - prometheus.${domain}
      tls:
        - secretName: ${secret}
          hosts:
            - prometheus.${domain}
    alertmanagers:
    - static_configs:
      - targets:
        - alertmanager.${domain}
  serverFiles:
    prometheus.yml:
      rule_files:
        - /etc/config/recording_rules.yml
        - /etc/config/alerting_rules.yml
alertmanager:
  configmapReload:
    enabled: false
  config:
    global:
      resolve_timeout: 5m
      smtp_smarthost: 'smtp.qq.com:465'
      smtp_from: '11111111@qq.com'
      smtp_auth_username: '11111111@qq.com'
      smtp_auth_password: '123456'
      smtp_require_tls: false
    templates:
      - '/etc/alertmanager/*.tmpl'
    receivers:
      - name: 'default-receiver'
        email_configs:
        - to: '{{ template "email.to" . }}'
          html: '{{ template "email.to.html" . }}'
    route:
      group_wait: 10s
      group_interval: 5m
      receiver: default-receiver
      repeat_interval: 1h
EOF

helm repo add stable https://artifact.onwalk.net/chartrepo/public/ || echo true
helm repo update
helm upgrade --install observable-server stable/observableserver -n ${namspace} -f values.yaml
