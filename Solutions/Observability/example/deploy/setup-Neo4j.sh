# 添加 Neo4j Helm 仓库
helm repo add neo4j https://helm.neo4j.com/neo4j

# 更新 Helm 仓库
helm repo update

# 创建 Neo4j 的 values.yaml
cat > neo4j-values.yaml << EOF
auth:
  enabled: true
  neo4j:
    username: neo4j
    password: myneo4jpassword
neo4j:
  edition: community
core:
  numberOfServers: 1
  resources:
    requests:
      cpu: "500m"
      memory: "512Mi"
    limits:
      cpu: "1000m"
      memory: "1Gi"
EOF

# 部署 Neo4j
helm upgrade --install my-neo4j neo4j/neo4j -f neo4j-values.yaml
