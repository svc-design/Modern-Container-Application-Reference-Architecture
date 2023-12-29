# Modern Container Application Reference Architecture

## Introduction
Modern application architecture is characterized by four key features: scalability, portability, resilience, and agility. These fundamentals underpin many different aspects of modern architecture.

### Characteristics
- **Scalability:** Capable of scaling up or down quickly and seamlessly to adapt to changing global demands.
- **Portability:** Easily deployable across a variety of devices and infrastructure, whether in public clouds or local environments.
- **Resilience:** Able to perform failover in new clusters or virtual environments across various availability zones, clouds, or data centers.
- **Agility:** Facilitates updates through automated CI/CD pipelines, enhancing code velocity and frequency of code pushes.

## Reference Architecture
This repository offers a reference architecture for modern container applications, emphasizing the following principles:

![PlantUML Diagram](https://www.plantuml.com/plantuml/png/XPL1JnD15CVlxrECN3nnwis3WPIcD9A6A7UpRL_BfhkpP6QsQ8o9qKXY0ke1HNlGH2NqOglnO3WGlWopYz_26RAbmylkq5Ft_N_px__jpBokI1K8bSOHtEbXF-J87ZRgMwljvaQ3TQD0Ie15eHcgzRHJRpcbpJHAun0eunJM0z59X5FOI8RkWZN4dNwKxBgc8ebHRMCgdU9gX4B50Gy6wBhLex0xt4vIYMu84VGDwLJQWv0_SN-r_SZrtcmr0uMxmLE0kqp_6ETlP_hRApqTNvo-WNuIzL2mfJKSOPJinCWLQ_1HA19klo-nPy3CnsrfzFX1sa71KQ4i4OSr2S-lVRTGgf0F_9uM8gP49Qxc9VRIhWeJxZUs734cQc4Cy-rdoyltYtrczzZ5sNb-E2b4AnLdmaZ_NX_aPrCeder4tWnLXZMtH5kc4iLf8rIoEDmCOCNYW9guUdggFq-oFnEzjmz57Wz1ujr6-ir8-5j8lrbfbrSNm80jFX0efTiVrKXd7gR2W7JZOIeCIZkmSyCWsT6nFZzoybE5fYydoXVJv5L4-MAmZxO-7q16qkzcboTxUlyZp0TT9R0OUvM8EmIl86UDkMylnldNOrYCHEAJVVYL7Kprpq_wvGJ0Z42hEyFF89SdtxClxs5HAxcs5lixomz_bs73MhLETyR7UOteBdcv6qOho7lstmx-0m00)

- **Platform Agnosticism:** Designed to be independent of platforms, allowing deployment on various container orchestration platforms like Kubernetes (k8s) or k3s.
- **Open Source Software Priority:** Prioritizes open-source software (OSS) for robust, widely-adopted tools and technology.
- **Everything As Code:** Utilizes Infrastructure as Code (IaC) for defining and configuring all necessary application resources.
- **CI/CD Automation:** Implements continuous integration and deployment pipelines using GitHub CI.
- **Security-Conscious Development:** Adopts security best practices at every stage, including containerized builds and secure container repositories like Harbor.
- **Distributed Storage:** Includes distributed storage solutions for high availability and scalability of application data.

## Toolchain
- **Pipeline:** GitHub CI
- **IaC Tools:** Pulumi/Terraform
- **Code Repository:** GitHub
- **Container Repository:** Harbor
- **Monitoring:**
  - Logs: Loki
  - Tracing: Deepflow
  - Metrics: Prometheus
  - Notifications: Alertmanager
- **Data Storage:** Clickhouse
- **Visualization:** Grafana
- **Cluster Management:** Kubernetes (k8s), Lightweight Kubernetes (k3s)
- **Ingress:** Nginx
- **DNS:** DNS Service SaaS

## Getting Started
Follow these steps to start using this reference architecture.

## Documentation
1. [Multi-cluster Operations (I)](https://cloud.tencent.com/developer/article/2373761): Automated delivery, building, deployment, release, and monitoring.
2. [Multi-cluster Operations (II)](https://cloud.tencent.com/developer/article/2375570): Progressive application release.

## Issues
- **APISIX and External DNS Integration**
- **Metrics Collection with FluxCD, Flagger, and APISIX Ingress**
- **Monitoring of Canary Releases**

## To Do
- Multi-cluster Operations (III) to (VI) covering progressive release, multidimensional monitoring, vulnerability testing, and AIOps.
- SSL Certificate Management
  - Apply for Let's Encrypt certificates and save them to Vault
  - Configure CertManager to read certificates from Vault

## Contributions
Contributions to this reference architecture are welcome. Feel free to submit pull requests for suggestions, improvements, or bug fixes.

## License
Released under the GPL V3 license.

