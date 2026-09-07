# XConnect disposable cross-cloud lab

This dedicated Terraform root extends `vpn-overlay` with one AWS x86_64 Spot client
and one Vultr Ubuntu gateway. The existing WireGuard/VLESS overlay architecture is
reused; the sample site keys and configs elsewhere in this tree are not deployed.
There are no containers and no dependency on existing Accounts overlay APIs.

The reviewed GitOps `topology/sit/xconnect-lab.json` is the nonsecret declaration.
The consuming `platform-ops-toolkit/.github/workflows/xconnect-cloud-lab.yml`
resolves the declared Ubuntu image from provider catalogs, supplies variables,
configures software, tests the data plane, and destroys the run's resources.
Software scripts intentionally live in the pipeline repository, not Terraform.

All resources are new: VPC/subnet/internet gateway/routes/security group/keypair,
one one-time Spot instance, Vultr SSH key/firewall/rules, and one Vultr instance.
No existing VPC, instance, SSH key, or state is imported or modified. There are no
HCL loops or provisioners. Runtime public addresses and IDs are the only outputs.
Private provider state (including Vultr's initial password) stays in the Vault
configured remote backend and is never uploaded as an Actions artifact.

Backend key: `sit/xconnect-lab/xcl-RUN_ID-ATTEMPT/terraform.tfstate`. The workflow
serializes lab runs and cleanup; no shared SIT environment state is consumed.
AWS resources carry `ManagedBy`, `LabRun`, `ExpiresAt`, and `Environment` tags.
Vultr instances carry the run identity and expiry tags. Expiry tags express a
90-minute TTL. Before apply, the pipeline stores a durable nonsecret expiry lease
beside the state. A 15-minute scheduled reaper dispatches scoped cleanup for expired
leases, including after runner loss. Normal failure/success cleanup uses `always()`.
Schedules can be delayed or disabled by GitHub; the explicit `cleanup` mode remains
available with the original identity and pinned refs. Keep remote state available
until cleanup has been verified. Tags alone are not a provider-side billing cutoff.

Ingress: AWS SSH from the current runner /32 only; Vultr SSH from that runner,
TLS 443 and Zero 8443 from the fresh AWS client /32 only. Public UDP 51820 and
HTTP 8080 are closed. The test verifies WG carried over VLESS TLS/XUDP, with HTTP
bound only to the private WG address. No L2 VXLAN/gretap test is claimed.

Required Terraform variables are listed in `main.tf`. Provider credentials arrive
through OIDC/environment, never GitOps or tfvars. All input values are supplied by
the consumer; this root carries no environment-specific cloud sizing defaults.
