#!/bin/bash
set -x
export domain=$1
export secret=$2
export namespace=$3
export mysql_db_password=$4

cat > values.yaml << EOF

controller:
  adminUser: "admin"
  adminPassword: "jenkins"
  jenkinsHome: "/var/jenkins_home"
  ingress:
    enabled: true
    ingressClassName: nginx
    hostName: jenkins.$domain
    tls:
      - secretName: $secret
        hosts:
          - jenkins.$domain
  installLatestPlugins: true
  installPlugins:
    - git:5.1.0
    - database:1.1.3
    - workflow-job:2.39
    - credentials-binding:1.23
    - kubernetes:4029.v5712230ccb_f8
    - workflow-aggregator:596.v8c21c963d92d
    - configuration-as-code:1670.v564dc8b_982d0
  JCasC:
    enabled: true
    defaultConfig: true
    configScripts:
      database: |
        unclassified:
          globalDatabaseConfiguration:
            database: jenkins
            hostname: mysql.database.svc.cluster.local
            name: jenkins
            password: $mysql_db_password
            username: root
            validationQuery: "SELECT 1"
agent:
  enabled: true
  numExecutors: 1
  replicas: 3

persistence:
  enabled: true
  storageClass: "local-path"
  size: "10Gi"
networkPolicy:
  enabled: false
backup:
  enabled: false
additionalConfig: {}
EOF

helm repo add jenkins https://charts.jenkins.io
helm repo update
#helm upgrade --install jenkins jenkins/jenkins --version 4.1.1 -f values.yaml
helm upgrade --install jenkins jenkins/jenkins -n $namespace --create-namespace -f values.yaml 
