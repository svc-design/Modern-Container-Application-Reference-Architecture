# XConnect-One v1 consumer contracts

This package freezes infrastructure-owned **consumer mirrors** and coordinated
evolution contracts for Accounts, XConnect-APP, and the Playbooks Gateway
Agent. It is not an API source of truth: Accounts remains authoritative for the
HTTP API and signing protocol, while producer and consumer repositories own
their executable implementations. A compatibility row explicitly says when a
contract-first addition is not yet implemented by both sides.

| Contract group | Schemas / vectors | Producer → consumer |
|---|---|---|
| Product discovery | `product-plugin-manifest.schema.json` | XConnect-APP plugin host → built-in XConnect-One plugin |
| Client projection | SignedConfig v1/v2 schemas and Ed25519 vectors | Accounts → XConnect-APP |
| Signing keys | `signing-keys-response.schema.json` | Accounts → XConnect-APP |
| One-time enrollment | `join-token-*`, `enrollment-*-ack` | Accounts → `xconnect join` |
| Durable device session | `device-session-*`, `device-credential-*`, `device-bound-revoke-request` | Accounts → `xconnect sync/leave` |
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
- Join also returns one device credential exactly once. Its scope is exactly
  `overlay:session:mint`, `overlay:credential:rotate`, and
  `overlay:device:revoke`; it cannot read configuration. A minted enrollment
  bearer is at most 15 minutes and has only config read/ACK scope.
- Device credential secrets are high-entropy `xdc_` values. Accounts stores
  only their verifier digest. Rotation is client-generated: the client persists
  the successor before submitting its id and SHA-256 verifier, so a lost HTTP
  response cannot destroy the only usable credential.
- Device key/state mutations use optimistic versions. Revocation is terminal;
  a bound enrollment revoke request is empty and cannot name another device.
- A revoke that committed before policy recompilation failed is explicitly
  returned as pending and persisted to a service-token reconcile queue; its
  receipt must satisfy `processed = completed + failed`.
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

SignedConfig v2 is opt-in content negotiation. A client sends:

```text
Accept: application/vnd.xconnect.signed-config.v2+json
```

The no-header/default representation remains strict v1. Both responses are
`no-store` and `Vary: Accept`. V2 appends a signed `policy` member; its signing
order is:

```text
schema_version, config_id, network_id, device_id, generation,
issued_at, expires_at, proxy_core, transport, wireguard, policy
```

The signed policy path is same-origin and derived exactly from generation and
digest. Clients reject absolute URLs, redirects to another origin, media-type
mismatch, stale generation, and digest mismatch before accepting the artifact.

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

## Device authorization wire format

The only accepted device authorization value is:

```text
Authorization: Device xdc_<32 lowercase hex id>.<43 base64url characters>
```

The secret segment is 32 random bytes in canonical base64url without padding;
decode then re-encode must reproduce the exact segment. The response
`credential_id` is `xdcid_` plus the exact embedded hex id. Clients emit the
canonical `Device` scheme; servers compare that scheme ASCII-case-insensitively
as HTTP requires. Bearer, Basic, query-string, cookie, and other schemes are
rejected. The frozen machine-readable form is
`vectors/device-credential-wire.json`.

The rotation verifier is SHA-256 over the UTF-8 bytes of the exact complete
`xdc_<id>.<secret>` value—not the decoded secret, encoded segment, or id alone.

## Secret fixture policy

Normal goldens use `<redacted>` or `REDACTED_*` placeholders. Three fixed fake
token-shaped strings are committed: the invalid join-secret redaction case,
the all-`A` join credential, and the fixed canonical rotation vector. The suite requires
that they remain only in their known files. Never replace them with credentials
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
The `device-credential-authorization.json` vector additionally freezes active,
inactive, replaced, revoked, verifier-mismatch, and terminal-receipt behavior.

The durable device credential is a control credential, never a tunnel secret.
It must live in Keychain, Credential Manager, Android Keystore, or an atomic
0600 Linux secret file. Flutter preferences, logs, diagnostics, shell history,
and runtime metadata must not contain it. See
`DEVICE_CREDENTIAL_LIFECYCLE.md` for the crash-safe join/sync/rotate/leave
state machine.

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
