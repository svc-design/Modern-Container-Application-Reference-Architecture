# Modern Container Application Reference Architectures

## Modern App Architectures

We define modern app architectures as those driven by four characteristics: scalability, portability, resiliency, and agility. While many different aspects of a modern architecture exist, these are fundamental.

- Scalability – Quickly and seamlessly scale up or down to accommodate spikes or reductions in demand, anywhere in the world.
- Portability – Easy to deploy on multiple types of devices and infrastructures, on public clouds, and on premises.
- Resiliency – Can fail over to newly spun‑up clusters or virtual environments in different availability regions, clouds, or data centers.
- Agility – Ability to update through automated CI/CD pipelines with higher code velocity and more frequent code pushes.

![PlantUML Diagram](https://www.plantuml.com/plantuml/png/XPL1JnD15CVlxrECN3nnwis3WPIcD9A6A7UpRL_BfhkpP6QsQ8o9qKXY0ke1HNlGH2NqOglnO3WGlWopYz_26RAbmylkq5Ft_N_px__jpBokI1K8bSOHtEbXF-J87ZRgMwljvaQ3TQD0Ie15eHcgzRHJRpcbpJHAun0eunJM0z59X5FOI8RkWZN4dNwKxBgc8ebHRMCgdU9gX4B50Gy6wBhLex0xt4vIYMu84VGDwLJQWv0_SN-r_SZrtcmr0uMxmLE0kqp_6ETlP_hRApqTNvo-WNuIzL2mfJKSOPJinCWLQ_1HA19klo-nPy3CnsrfzFX1sa71KQ4i4OSr2S-lVRTGgf0F_9uM8gP49Qxc9VRIhWeJxZUs734cQc4Cy-rdoyltYtrczzZ5sNb-E2b4AnLdmaZ_NX_aPrCeder4tWnLXZMtH5kc4iLf8rIoEDmCOCNYW9guUdggFq-oFnEzjmz57Wz1ujr6-ir8-5j8lrbfbrSNm80jFX0efTiVrKXd7gR2W7JZOIeCIZkmSyCWsT6nFZzoybE5fYydoXVJv5L4-MAmZxO-7q16qkzcboTxUlyZp0TT9R0OUvM8EmIl86UDkMylnldNOrYCHEAJVVYL7Kprpq_wvGJ0Z42hEyFF89SdtxClxs5HAxcs5lixomz_bs73MhLETyR7UOteBdcv6qOho7lstmx-0m00)


## Modern Container Application Reference Architectures

This repository provides a reference architecture for modern container applications. It focuses on the following key principles:

* Platform Agnosticism: The architecture is designed to be platform-agnostic, allowing you to deploy your application on different container orchestration platforms such as Kubernetes (k8s) or lightweight alternatives like k3s.
* Prioritization of OSS: Open-source software (OSS) is prioritized, ensuring that the architecture is built on robust and widely adopted tools and technologies.
* Everything Defined by Code: Infrastructure as Code (IaC) is used to define and provision all the necessary resources for your application. This ensures consistency, reproducibility, and scalability.
* CI/CD Automation: Continuous Integration and Continuous Deployment (CI/CD) pipelines are implemented using GitHub CI, enabling automated build, test, and deployment processes.
* Security-minded Development: Security is a top priority in the architecture, with best practices implemented at every stage, including containerized builds, secure container registries like Harbor, and secure communication between services.
* Distributed Storage: The architecture incorporates distributed storage solutions to ensure high availability and scalability for your application's data.

## Tools Chain

The following tools are used in this reference architecture:

- Pipeline: GitHub CI
- IaC Tool: Pulumi
- Code Repository: GitHub
- Container Registry: Harbor
- Monitoring:
  - Logs: Loki
  - Tracing: Deepflow
  - Metrics: Prometheus
  - Notification: Alertmanager
  - Datastore: Clickhouse
  - Visualization: Grafana
- Cluster Management:
  - Kubernetes (k8s)
  - Lightweight Kubernetes (k3s)
- Ingress: Nginx
- DNS

# Getting Started

To get started with this reference architecture, follow these steps:

1. Clone this repository to your local machine.
2. Set up the required tools mentioned above, ensuring they are properly configured.
3. Modify the code and configuration files as per your application's requirements.
4. Use Pulumi to provision the necessary infrastructure resources defined in the IaC files.
5. Configure the CI/CD pipeline in GitHub CI to trigger builds and deployments automatically.
6. Monitor your application using the provided monitoring stack.
7. Deploy your application to the target cluster using k8s or k3s.
8. Set up Nginx Ingress and DNS for routing traffic to your application.

For more detailed instructions and examples, please refer to the documentation provided in this repository.

# Contributing

We welcome contributions from the community to enhance this reference architecture. If you have any suggestions, improvements, or bug fixes, please feel free to submit a pull request.

# License

This reference architecture is released under the GPL V3 License.

https://github.com/fluxcd/flux2-monitoring-example

# Doc

- 多集群运维(一)：自动化交付，构建，部署，发布，监控: https://cloud.tencent.com/developer/article/2373761
