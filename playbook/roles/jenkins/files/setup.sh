#!/bin/bash
set -x
export domain=$1
export secret=$2
export namespace=$3
export mysql_db_password=$4

cat > values.yaml << EOF
persistence:
  enabled: true
  storageClass: "local-path"
  size: "50Gi"

# Default values for Jenkins.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.

controller:
  adminUser: "admin"
  adminPassword: "jenkins"
  ingress:
    enabled: true
    ingressClassName: nginx
    hostName: jenkins.example.com

# Jenkins Master settings
master:
  replicas: 2
  image: "jenkins/jenkins"
  tag: "lts"
  pullPolicy: "IfNotPresent"
  adminUser: "admin"
  adminPassword: "admin"
  jenkinsHome: "/var/jenkins_home"
  servicePort: 8080
  targetPort: 8080

  # Install plugins including the Database plugin
  installPlugins:
    - "kubernetes:1.28.6"
    - "workflow-job:2.39"
    - "workflow-aggregator:2.6"
    - "credentials-binding:1.23"
    - "git:4.4.5"
    - "database:1.1.3"

  JCasC:
    enabled: true
    defaultConfig: true
    configScripts:
      database: |
        unclassified:
          globalDatabaseConfiguration:
            database: mysql
            hostname: my-mysql-host
            name: jenkins
            password: my-password
            username: my-user
            validationQuery: "SELECT 1"

agent:
  enabled: true
  image: "jenkins/inbound-agent"
  tag: "4.3-4"
  customJenkinsLabels: []
  # Number of executors
  numExecutors: 1
  replicas: 3

networkPolicy:
  enabled: false
backup:
  enabled: false
additionalConfig: {}
EOF

helm repo add jenkins https://charts.jenkins.io
helm repo update
helm upgrade --install jenkins jenkins/jenkins --version 4.1.1 -f values.yaml
