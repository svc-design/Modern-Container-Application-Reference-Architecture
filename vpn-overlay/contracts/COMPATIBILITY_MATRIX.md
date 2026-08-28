# XConnect-One v1 contract compatibility matrix

Status date: 2026-08-28. This records consumer compatibility; it does not
supersede Accounts OpenAPI/handlers, Gateway Agent Go types, or XConnect-APP
verification code.

| Boundary | Canonical implementation | Infra mirror | Compatibility gate |
|---|---|---|---|
| SignedConfig projection/signature | Accounts projection | `signed-config.schema.json`, `signed-config-ed25519.json` | Accounts, IAC, and XConnect-APP vector SHA-256 is `5302888289f008df6389e1165ac4f79d8a4ad967b139ea2c889f49208ae0f0a7` |
| SignedConfig v2 policy reference | Coordinated contract; Accounts/XConnect-APP producers pending | `signed-config-v2.schema.json`, `signed-config-v2-ed25519.json` | explicit Accept negotiation; v1 default preserved; signed same-origin generation/digest/path; vector SHA-256 `18ca0ead8e764e3cebc1dca4821221aa92124c474e9095676bcd43a258165416` |
| Signing key publication | Accounts `/api/overlay/v1/signing-keys` | `signing-keys-response.schema.json` | Ed25519 public-only ring, unique IDs, exactly one current key |
| One-time invite create/exchange | Accounts join handlers/OpenAPI | `join-token-*` | one issued use; read/ACK/self-revoke enrollment scope; no-store |
| Durable device session | Accounts device credential handlers | `device-session-*`, `device-credential-*`, `device-bound-revoke-request`, authorization vector | hash-only verifier; device-bound auth; 15-minute config session; crash-safe client-generated rotation; route-scoped terminal receipt |
| Device lifecycle | Accounts device lifecycle handlers | `device-*-request`, `device-lifecycle-response` | account CAS key/state mutation; terminal revoke; enrollment request cannot select another device |
| Enrollment config ACK | Accounts enrollment wrapper + config ACK | `enrollment-config-ack.schema.json` | device/network binding and strict consumer document |
| Enrollment SignedConfig ACK | Accounts projection ACK | `enrollment-signed-config-ack.schema.json` | generation path plus device/config binding; idempotent producer receipt |
| GatewaySnapshot | Accounts gateway projection → Playbooks Gateway Agent | `gateway-snapshot.schema.json`, `gateway-snapshot-ed25519.json` | Playbooks Batch03 golden payload/signature verifies byte-for-byte |
| Gateway heartbeat | Gateway Agent → Accounts | `gateway-heartbeat.schema.json` | node bearer; controller-authorized shadow/apply mode; applied never exceeds observed |
| Gateway apply-result | Gateway Agent → Accounts | `gateway-apply-result*.schema.json` | shadow is non-mutating; apply success is exact/equal; safe failure may advance once to success; rollback-failed is terminal |
| Node credential lifecycle | Accounts management handlers | `node-credential-create-*.schema.json` plus HTTP matrix | create/revoke uses `X-Service-Token`; bearer is one-time/no-store; revoke is 204 |
| Static client import | Playbooks Batch04 importer → Accounts | `static-client-import*.schema.json` | owner UUID, canonical body hash, `X-Service-Token`, deterministic receipt |
| NetworkPolicy v1alpha1 | Accounts management API → ACL compiler | `network-policy-v1alpha1.schema.json` | strict source, default deny, user/group tag owners, no secret fields |
| Enforcement artifact | Accounts ACL compiler → Playbooks Gateway Agent | `policy-enforcement-artifact.schema.json` + SHA-256 golden | device-only runtime IR, deny-first, exact protected flows, digest-bound fetch |

## Platform/runtime declaration

- Client platforms: Linux, macOS, Windows, iOS, Android.
- Gateway Agent: Linux shadow by default; apply requires explicit node
  authorization and the Playbooks transactional runtime.
- Runtime: Xray-core/libXray only.
- Data-plane mutation is contractually modeled but remains disabled by default.
  Passing these mirrors does not authorize a node for apply mode.

## Dependencies not claimed as E2E

- Accounts internal Gateway/static-import endpoints must be merged and deployed
  before integration use.
- SignedConfig v2 must be implemented and pass the mirrored vector in Accounts
  and XConnect-APP before clients advertise its Accept media type.
- Passing schemas proves wire compatibility, not live authorization, database
  persistence, network connectivity, or data-plane application.
- Accounts and XConnect-APP must ship the device credential producer/consumer
  together before durable sync/leave is enabled; older enrollment-only clients
  fail closed on the newly required join response member.
- Node credential revoke has no JSON response body; the HTTP matrix represents
  its 204 boundary rather than inventing a receipt.
