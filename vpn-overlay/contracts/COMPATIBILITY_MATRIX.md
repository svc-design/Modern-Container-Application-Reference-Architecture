# XConnect-One v1 contract compatibility matrix

Status date: 2026-08-28. This records consumer compatibility; it does not
supersede Accounts OpenAPI/handlers, Gateway Agent Go types, or XConnect-APP
verification code.

| Boundary | Canonical implementation | Infra mirror | Compatibility gate |
|---|---|---|---|
| SignedConfig projection/signature | Accounts projection | `signed-config.schema.json`, `signed-config-ed25519.json` | Accounts, IAC, and XConnect-APP vector SHA-256 is `5302888289f008df6389e1165ac4f79d8a4ad967b139ea2c889f49208ae0f0a7` |
| Signing key publication | Accounts `/api/overlay/v1/signing-keys` | `signing-keys-response.schema.json` | Ed25519 public-only ring, unique IDs, exactly one current key |
| One-time invite create/exchange | Accounts join handlers/OpenAPI | `join-token-*` | one issued use; read/ACK-only enrollment scope; no-store |
| Enrollment config ACK | Accounts enrollment wrapper + config ACK | `enrollment-config-ack.schema.json` | device/network binding and strict consumer document |
| Enrollment SignedConfig ACK | Accounts projection ACK | `enrollment-signed-config-ack.schema.json` | generation path plus device/config binding; idempotent producer receipt |
| GatewaySnapshot | Accounts gateway projection → Playbooks Gateway Agent | `gateway-snapshot.schema.json`, `gateway-snapshot-ed25519.json` | Playbooks Batch03 golden payload/signature verifies byte-for-byte |
| Gateway heartbeat | Gateway Agent → Accounts | `gateway-heartbeat.schema.json` | node bearer; shadow + Xray; applied generation remains 0 |
| Gateway apply-result | Gateway Agent → Accounts | `gateway-apply-result*.schema.json` | node bearer; runtime applied false; retry receipt exposes duplicate |
| Node credential lifecycle | Accounts management handlers | `node-credential-create-*.schema.json` plus HTTP matrix | create/revoke uses `X-Service-Token`; bearer is one-time/no-store; revoke is 204 |
| Static client import | Playbooks Batch04 importer → Accounts | `static-client-import*.schema.json` | owner UUID, canonical body hash, `X-Service-Token`, deterministic receipt |

## Platform/runtime declaration

- Client platforms: Linux, macOS, Windows, iOS, Android.
- Gateway Agent: Linux shadow-mode only in this batch.
- Runtime: Xray-core/libXray only.
- Data-plane mutation: out of scope; these contracts do not enable Gateway
  WireGuard or nftables application.

## Dependencies not claimed as E2E

- Accounts internal Gateway/static-import endpoints must be merged and deployed
  before integration use.
- Passing schemas proves wire compatibility, not live authorization, database
  persistence, network connectivity, or data-plane application.
- Node credential revoke has no JSON response body; the HTTP matrix represents
  its 204 boundary rather than inventing a receipt.
