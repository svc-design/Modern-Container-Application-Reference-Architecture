# XConnect-One v1 consumer contracts

This package freezes infrastructure-owned **consumer mirrors** of contracts
already implemented by Accounts, XConnect-APP, and the Playbooks Gateway Agent.
It is not a new API source of truth: Accounts remains authoritative for the
HTTP API and signing protocol, while producer and consumer repositories own
their executable implementations.

| Contract group | Schemas / vectors | Producer → consumer |
|---|---|---|
| Product discovery | `product-plugin-manifest.schema.json` | XConnect-APP plugin host → built-in XConnect-One plugin |
| Client projection | `signed-config.schema.json`, `signed-config-ed25519.json` | Accounts → XConnect-APP |
| Signing keys | `signing-keys-response.schema.json` | Accounts → XConnect-APP |
| One-time enrollment | `join-token-*`, `enrollment-*-ack` | Accounts → `xconnect join` |
| Device lifecycle | `device-*-request`, `device-lifecycle-response` | Accounts → `xconnect` / account administration |
| Gateway projection | `gateway-snapshot.schema.json`, `gateway-snapshot-ed25519.json` | Accounts → Gateway Agent |
| Dynamic ACL source | `network-policy-v1alpha1.schema.json` | Accounts management API → ACL compiler |
| ACL enforcement | `policy-enforcement-artifact.schema.json`, policy SHA-256 golden | Accounts compiler → Gateway Agent |
| Gateway reports | `gateway-heartbeat`, `gateway-apply-result*` | Gateway Agent → Accounts |
| Gateway credentials | `node-credential-create-*` | Accounts management boundary → Gateway bootstrap |
| Static migration | `static-client-import*` | Playbooks migration tool → Accounts |
| HTTP boundary | `control-plane-http-contracts.schema.json` | Accounts route/auth/cache contract → all consumers |

## v1 invariants

- The only accepted proxy core is `xray`; sing-box is not a v1 runtime or fallback.
- Signed documents never contain WireGuard private keys, refresh tokens, Vault
  tokens, passwords, or raw deployment secrets.
- A Gateway snapshot with no peers is rejected unless its safety block
  explicitly authorizes an empty peer set.
- Configuration generation is monotonic and expired documents are rejected.
- JSON documents are single-value and duplicate-member-free. Strict request
  boundaries reject unknown fields and trailing JSON.
- NetworkPolicy is default-deny. The Gateway artifact contains only expanded
  device identifiers; users, email addresses, groups, tags, and tag owners stay
  at the management boundary.
- Join invites are one-time: create input accepts `remaining_uses` only as `0`
  (default compatibility input) or `1`, and issued invites always report `1`.
- Enrollment scope is exactly `overlay:config:read`, `overlay:config:ack`, and
  `overlay:device:revoke`, bound to one user/network/device/public-key
  enrollment. The bearer remains short-lived and is not a durable leave token.
- Device key/state mutations use optimistic versions. Revocation is terminal;
  a bound enrollment revoke request is empty and cannot name another device.
- Gateway nodes are explicitly authorized as either `shadow` or `apply` by the
  control plane. Shadow reports cannot imply mutation. Apply success requires
  an exact observed/applied generation and equal runtime readback; failures
  preserve an older checkpoint. A rollback failure is not auto-upgradable.
- Control-plane URLs are HTTPS. Secret-bearing join, Gateway, credential, and
  static-import responses use `no-store` where recorded in the HTTP fixture.

## SignedConfig signing bytes

The Ed25519 signature covers compact UTF-8 JSON with no trailing newline and
without the top-level `signature` member. Top-level member order is fixed as:

```text
schema_version, config_id, network_id, device_id, generation,
issued_at, expires_at, proxy_core, transport, wireguard
```

`vectors/signed-config-ed25519.json` is byte-for-byte identical across
Accounts, this IAC mirror, and the XConnect-APP Go verifier. The seed is
development test material and must never become a deployment key.

## GatewaySnapshot signing bytes

`vectors/gateway-snapshot-ed25519.json` copies the Playbooks Batch03 Gateway
Agent golden payload and signature. The signature excludes `signature` and
covers compact UTF-8 JSON in this order:

```text
schema_version, snapshot_id, node_id, generation,
expected_previous_generation, issued_at, expires_at, proxy_core,
safety, wireguard, relay, policy
```

The vector validates field order, Xray-only runtime, transition metadata,
safety, relay references, policy digest, key id, and Ed25519 verification.

## Secret fixture policy

Normal goldens use `<redacted>` or `REDACTED_*` placeholders. The only raw
token-shaped string is fake test material quarantined in
`fixtures/invalid/join-token-exchange-raw-secret-redaction.json`; the suite
requires that it remain the only such file. Never replace it with a credential
from any environment.

## HTTP and idempotency

`fixtures/valid/control-plane-http-contracts.json` mirrors the implemented
method, path, authentication boundary, media type, strict JSON, HTTPS, and cache
behavior. It distinguishes Gateway node bearer from the management
`X-Service-Token` boundary.

Static imports use compact canonical JSON and:

```text
Idempotency-Key: sha256-<sha256 of exact canonical request bytes>
```

The v1 fixture is frozen to
`sha256-911905502b4aa02c4c82b16e200f5f13caebd534898566b8b87384d972ed1fd2`.

## Validation

Install the isolated dependencies and run:

```bash
python3 -m pip install -r vpn-overlay/contracts/requirements.txt
vpn-overlay/contracts/scripts/validate.sh
```

Every fixture must be registered in `tests/test_contracts.py`. The suite checks
schemas, strict JSON, time/generation transitions, empty-peer safety, unique
identities/keys/addresses, key windows, Gateway diff consistency, canonical
static-import digests, idempotency, signing vectors, and secret rejection.

The device-bound enrollment revoke endpoint covers only the short enrollment
window. A hash-only, rotatable device refresh credential is a release blocker
for durable `xconnect sync` and `xconnect leave`; extending or persisting the
short-lived enrollment bearer is not an accepted substitute.

To compare working copies of Accounts and XConnect-APP during a coordinated
change, pass their existing vector paths:

```bash
XCONNECT_ACCOUNTS_SIGNED_CONFIG_VECTOR=/path/to/accounts/tests/fixtures/overlay/signed-config-ed25519-vector.json \
XCONNECT_CLIENT_SIGNED_CONFIG_VECTOR=/path/to/xconnect-app/go_core/overlay/signedconfig/testdata/signed-config-ed25519-vector.json \
vpn-overlay/contracts/scripts/validate.sh
```

The executable ACL artifact is also byte-for-byte frozen across Accounts, IAC,
and Playbooks. Pass both producer/consumer copies when validating coordinated
branches:

```bash
XCONNECT_ACCOUNTS_POLICY_ARTIFACT=/path/to/accounts/tests/fixtures/overlay/network-policy-enforcement.golden.json \
XCONNECT_PLAYBOOKS_POLICY_ARTIFACT=/path/to/playbooks/tools/xconnect-gateway-agent/internal/gateway/testdata/network-policy-enforcement.golden.json \
vpn-overlay/contracts/scripts/validate.sh
```

See `COMPATIBILITY_MATRIX.md` for producer/consumer ownership and limitations.
