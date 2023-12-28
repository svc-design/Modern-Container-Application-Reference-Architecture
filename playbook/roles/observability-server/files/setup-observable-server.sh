#!/bin/bash
set -x
export domain=$1
export secret=$2
export namespace=$3
export mysql_db_password=$4
export ck_node_ip1=$5
export ck_node_ip2=$6
export ck_node_ip3=$7

node_name=`kubectl get nodes | awk '{print $1}' | tail -n 1`
kubectl label nodes $node_name app=prometheus --overwrite

cat > values.yaml << EOF
deepflow:
  enabled: true
  clickhouse:
    enabled: true
  mysql:
    enabled: false
  grafana:
    enabled: true
    ingress:
      enabled: true
      ingressClassName: apisix
      hosts:
        - grafana.${domain}
      tls:
        - secretName: ${secret}
          hosts:
            - grafana.${domain}
  global:
    #externalClickHouse:
    #  enabled: true
    #  type: ep
    #  clusterName: default
    #  storagePolicy: default
    #  username: default
    #  password: ''
    #  hosts:
    #  - ip: $ck_node_ip1
    #    port: 9000
    #  - ip: $ck_node_ip2
    #    port: 9000
    #  - ip: $ck_node_ip3
    #    port: 9000
    externalMySQL:
      enabled: true
      ip: mysql.database.svc.cluster.local
      port: 3306
      username: root
      password: $mysql_db_password
prometheus:
  enabled: true
  alertmanager:
    enabled: false
  prometheus-pushgateway:
    enabled: false
  kube-state-metrics:
    enabled: true
  server:
    extraArgs:
      enable-feature: remote-write-receiver
    ingress:
      enabled: true
      ingressClassName: apisix
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
    enabled: true
  ingress:
    enabled: true
    className: "nginx"
    hosts:
      - host: alertmanager.$domain
        paths:
          - path: /
            pathType: ImplementationSpecific
    tls:
      - secretName: ${secret}
        hosts:
          - alertmanager.$domain
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

helm repo add stable https://charts.onwalk.net/ || echo true
helm repo update
kubectl delete deploy  observability-server -n ${namespace} || echo true
helm upgrade --install observability-server stable/observableserver -n ${namespace} -f values.yaml
sudo curl -o /usr/bin/deepflow-ctl https://deepflow-ce.oss-cn-beijing.aliyuncs.com/bin/ctl/stable/linux/$(arch | sed 's|x86_64|amd64|' | sed 's|aarch64|arm64|')/deepflow-ctl
sudo chmod a+x /usr/bin/deepflow-ctl
