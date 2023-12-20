
# GCP 服务账号凭据的 JSON 文件：

1. 创建服务账号：
在 GCP 控制台中，导航到 "IAM & admin" -> "Service accounts"，然后点击 "Create Service Account"。填写必要的信息，为服务账号选择适当的角色（例如，Editor 角色以获得足够的权限），然后点击 "Create"。

2. 生成服务账号密钥：
在创建服务账号后，找到刚刚创建的服务账号，然后点击 "Add Key"。选择 JSON 格式，然后点击 "Create"。这将下载一个 JSON 文件，其中包含你的服务账号凭据。

3. 示例 GCP 凭据 JSON 文件：以下是一个示例 GCP 凭据 JSON 文件的结构：

```json
Copy code
{
  "type": "service_account",
  "project_id": "your-gcp-project-id",
  "private_key_id": "your-private-key-id",
  "private_key": "-----BEGIN PRIVATE KEY-----\nYour-Private-Key-Here\n-----END PRIVATE KEY-----\n",
  "client_email": "your-service-account@your-gcp-project-id.iam.gserviceaccount.com",
  "client_id": "your-client-id",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://accounts.google.com/o/oauth2/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/your-service-account%40your-gcp-project-id.iam.gserviceaccount.com"
}
```

- "project_id" 是你的 GCP 项目的 ID。
- "private_key" 包含服务账号的私钥。在实际使用时，你可以通过读取 JSON 文件并提供 "private_key" 字段的值来配置 Terraform 提供者。
- "client_email" 是服务账号的邮箱地址。
其他字段是用于 OAuth2 认证的元数据。**确保谨慎处理这些凭据文件，并不要泄露它们。在实际使用中，可以通过环境变量或其他安全方式提供凭据，而不是将其硬编码到配置文件中。**

4. 将 GCP 凭据文件添加到 GitHub Secrets：
在你的 GitHub 存储库中，导航到 "Settings" -> "Secrets"，然后点击 "New repository secret"。创建一个名为 GCP_CREDENTIALS_JSON 的新秘密，并将下载的 GCP 凭据 JSON 内容粘贴到值字段中。保存该秘密。

5. 配置 GitHub Actions Workflow 文件引用：
存储库中创建一个 .github/workflows/main.yml 文件，以定义 GitHub Actions 的工作流,secret变量引用方式参考 ${{ secrets.GCP_CREDENTIALS_JSON }}
