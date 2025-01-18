# Modern Container Application Reference Architecture

Welcome to the repository for the Modern Container Application Reference Architecture. This repository contains a comprehensive guide and reference architecture for building scalable, portable, resilient, and agile containerized applications.

## Overview

The project aims to create a multi-cloud environment that leverages containers for deploying modern applications. The key objective is to set up a unified authentication system using **OIDC** via **Auth0 by Okta** for **AWS**, **GCP**, **Azure**, **GitHub**, and **Grafana **.

## Phase 1: Implementing OIDC Login

In this first phase, we focus on implementing OpenID Connect (OIDC) login functionality for the following platforms:
- [AWS](docs/aws-oidc-setup.md)
- [GCP](docs/gcp-oidc-setup.md)
- [Azure](docs/azure-oidc-setup.md)
- [GitHub](docs/github-oidc-setup.md)
- [Grafana Cloud](docs/grafana-oidc-setup.md)

## Cloud Resouces

| Cloud | Host Name               | Public IP      | VPN IP       | Costs | Service                                                                                   |
|-------|-------------------------|----------------|--------------|-------|-------------------------------------------------------------------------------------------|
| ALI   | cn-gateway.svc.plus     | 8.130.10.142   | 10.254.0.1   | ---   |  cn-proxy.onwalk.net                                                                      |
| HW    | hw-node.onwalk.net      | 139.9.139.22   | ---          | ---   |  images.onwalk.net                                                                        |
| AWS   | global-gateway.svc.plus | 52.196.108.28  | 10.255.0.1   | ---   |  tky-connector.onwalk.net </br>global-images.onwalk.net                                   |
| AWS   | us-gateway.svc.plus     | 54.183.199.99  | ---          | ---   |  us-connector.onwalk.net </br>grafana.onwalk.net</br>metrics.onwalk.net                   |
| AWS   | canada-gateway.svc.plus | 35.182.201.252 | ---          | ---   |  ca-connector.onwalk.net </br>logs.onwalk.net                                             |

## Key Components Overview

| **Component**                               | **Description**                                                                                                  | **Tools/Technologies**                       |
|---------------------------------------------|------------------------------------------------------------------------------------------------------------------|----------------------------------------------|
| **1. LDP (Login Delegation Protocol)**       | Centralized authentication and Single Sign-On (SSO) using **Auth0 by Okta** for various platforms.                | Auth0 by Okta, OIDC                          |
| **2. IaC (Infrastructure as Code)**          | Infrastructure management and provisioning using automated tools.                                                 | Terraform, Pulumi                            |
| **3. Monitoring**                            | Comprehensive observability and monitoring for the application, including system metrics, network, and performance.| Grafana Cloud, Prometheus, DeepFlow, ClickHouse |
| **4. Git Repository**                        | Version control and source code management for the project.                                                       | GitHub                                       |
| **5. CI/CD (Continuous Integration/Delivery)**| Automated build, test, and deployment pipelines.                                                                  | GitHub Actions                               |
## key Components Service

| **Name**              | **Domain**                 | **Version**     | **Deploy**                | **Docker Compose**      | **Chart**                  | **CI/CD**                 |
|-------------------|------------------------|-------------|-----------------------|---------------------|------------------------|-----------------------|
| **1. Keycloak**       | keycloak.onwalk.net    | 26.0        | Docker                | Yes                 | Yes                    | GitHub Actions        |
| **2. Harbor**         | images.onwalk.net      | 2.12        | Docker                | Yes                 | Yes                    | GitHub Actions        |
| **3. ChartMuseum**    | charts.onwalk.net      | 0.14.0      | Docker                | Yes                 | Yes                    | GitHub Actions        |
| **4. Vault**          | vault.onwalk.net       | 1.15        | Docker                | Yes                 | Yes                    | GitHub Actions        |
| **5. Nginx/OSS**      | mirrors.onwalk.net     | 1.21        | Kubernetes            | Yes                 | Yes                    | GitHub Actions        |

| **Name**            | **Domain**                           |   **Version   |      Deploy               |  Docker Compose** | **Chart**              | **CI/CD**             |
|-------------------|--------------------------------|-------------|---------------------------|---------------------|------------------------|-----------------------|
| **5. OpenIPA**        | freeipa.onwalk.net             | 4.10        | Kubernetes, Docker, BareMetal| Yes                | Yes                    | GitHub Actions        |
| **1. PostgreSQL**     | db.onwalk.net                  | 16.0        | Kubernetes, Docker         | Yes                 | Yes                    | GitHub Actions        |
| **8. Prometheus**     | monitoring.onwalk.net          | 2.35        | Kubernetes, Docker         | Yes                 | Yes                    | GitHub Actions        |
| **9. Grafana**        | monitoring.onwalk.net          | 8.4         | Kubernetes, Docker         | Yes                 | Yes                    | GitHub Actions        |
| **10. Consul**        | consul.onwalk.net              | 1.12        | Kubernetes, Docker         | Yes                 | Yes                    | GitHub Actions        |
| **12. Jenkins**       | jenkins.onwalk.net             | 2.319       | Kubernetes, Docker         | Yes                 | Yes                    | GitHub Actions        |
| **13. GitLab**        | gitlab.onwalk.net              | 15.5        | Kubernetes, Docker         | Yes                 | Yes                    | GitHub Actions        |
| **14. MinIO**         | minio.onwalk.net               | 2023.2.0    | Kubernetes, Docker         | Yes                 | Yes                    | GitHub Actions        |


---

### 1. **LDP (Login Delegation Protocol)** - **Auth0 by Okta**
   - Set up **Auth0 by Okta** as the identity provider to enable **OpenID Connect (OIDC)** login for multiple platforms:
     - **AWS**, **GCP**, **Azure**, **GitHub**, **Grafana Cloud**
   - OIDC allows secure Single Sign-On (SSO) across all these platforms.
   - For more details, refer to [Platform-Specific OIDC Setup Docs](./docs).

### 2. **IaC (Infrastructure as Code)** - **Terraform / Pulumi**
   - Infrastructure for AWS, GCP, and Azure is provisioned using **Terraform** and **Pulumi** scripts.
   - These scripts allow easy and reproducible deployment and management of cloud resources.
   - See the `iac/` folder for the setup files.

### 3. **Monitoring** - **Grafana Cloud / Prometheus / DeepFlow / ClickHouse**
   - Monitoring stack includes:
     - **Prometheus** for metrics collection.
     - **DeepFlow** for network and system observability.
     - **ClickHouse** for storing and querying large amounts of observability data.
     - **Grafana Cloud** for visualizing all collected metrics and logs.
   - Configuration files for monitoring tools can be found in the `monitoring/` folder.

### 4. **Git Repository** - **GitHub**
   - All project code, infrastructure configurations, and documentation are managed within this **GitHub** repository.
   - GitHub also integrates with **GitHub Actions** for CI/CD.

### 5. **CI/CD** - **GitHub Actions**
   - Automated CI/CD pipeline is set up using **GitHub Actions** to ensure continuous integration and deployment.
   - Pipelines handle code testing, building, and multi-cloud deployments for platforms like AWS, GCP, and Azure.
   - YAML workflow files for GitHub Actions can be found in the `.github/workflows/` directory.

---

For detailed instructions on configuring each platform, see:

- [Set up Auth0 by Okta for OIDC](./docs/auth0-oidc-setup.md)
- [Configure OIDC login for AWS](./docs/aws-oidc-setup.md)
- [Configure OIDC login for GCP](./docs/gcp-oidc-setup.md)
- [Configure OIDC login for Azure](./docs/azure-oidc-setup.md)
- [Configure OIDC login for GitHub](./docs/github-oidc-setup.md)
- [Configure OIDC login for Grafana Cloud](./docs/grafana-oidc-setup.md)
- [Test and validate OIDC logins](./docs/testing-oidc-logins.md)

## TODO

- [ ] Set up **Auth0 by Okta** as the identity provider for OIDC authentication.
- [ ] Configure OIDC login for **AWS**.
- [ ] Configure OIDC login for **GCP**.
- [ ] Configure OIDC login for **Azure**.
- [ ] Configure OIDC login for **GitHub**.
- [ ] Configure OIDC login for **Grafana Cloud**.
- [ ] Test and validate login workflows across all platforms.

## Documentation

For more detailed information, please refer to the documentation available in two languages:

- [中文文档 (Chinese Documentation)](docs/README_CN.md)
- [English Documentation](docs/README_EN.md)

## Getting Started

git submodule add --force https://github.com/svc-design/ansible.git
git submodule add --force https://github.com/svc-design/iac_modules.git
git submodule init
git submodule update

## New Ideas

CI Code Stages
- ctags
- https://github.com/KDAB/codebrowser
- SonarQube
- gitleaks

CD Deploy Stages
- IAC
- ArgoCD
- Ansible Playbook


Follow the links above to the documentation in your preferred language to get started with using this reference architecture.

## Contributing

We welcome contributions to this project. If you have suggestions, improvements, or find any issues, feel free to submit a pull request.

## License

This project is released under the GPL V3 license. For more details, see the LICENSE file.
