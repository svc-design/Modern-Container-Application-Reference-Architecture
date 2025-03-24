# 添加 ClickHouse Helm 仓库
helm repo add clickhouse https://helm-clickhouse-test-repo.storage.googleapis.com/

# 更新 Helm 仓库
helm repo update

# 创建 ClickHouse 的 values.yaml
cat > clickhouse-values.yaml << EOF
replicas: 1
resources:
  requests:
    cpu: "500m"
    memory: "512Mi"
  limits:
    cpu: "1000m"
    memory: "1Gi"
EOF

# 部署 ClickHouse
helm upgrade --install clickhouse clickhouse/clickhouse -f clickhouse-values.yaml
