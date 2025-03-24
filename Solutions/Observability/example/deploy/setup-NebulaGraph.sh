
# 添加 NebulaGraph Helm 仓库
helm repo add nebula-graph https://vesoft-inc.github.io/nebula-helm/

# 更新 Helm 仓库
helm repo update

# 创建 NebulaGraph 的 values.yaml
cat > nebulagraph-values.yaml << EOF
metad:
  replicas: 1
  resources:
    requests:
      cpu: "500m"
      memory: "512Mi"
    limits:
      cpu: "1000m"
      memory: "1Gi"
storaged:
  replicas: 1
  resources:
    requests:
      cpu: "500m"
      memory: "512Mi"
    limits:
      cpu: "1000m"
      memory: "1Gi"
graphd:
  replicas: 1
  resources:
    requests:
      cpu: "500m"
      memory: "512Mi"
    limits:
      cpu: "1000m"
      memory: "1Gi"
EOF

# 部署 NebulaGraph
helm upgrade --install my-nebulagraph nebula-graph/nebula-graph -f nebulagraph-values.yaml

