# XConnect-One v1 contracts

This package freezes the infrastructure-facing Batch 01 contracts shared by
XConnect-APP, the control plane, and Gateway Agent implementations.

| Schema | Consumer | Purpose |
|---|---|---|
| `product-plugin-manifest.schema.json` | XConnect-APP | Product discovery, host compatibility, and capability grants |
| `signed-config.schema.json` | XConnect-One Client | Versioned client configuration without private key material |
| `gateway-snapshot.schema.json` | Gateway Agent | Complete desired peer, relay, and policy state |

## v1 invariants

- The only accepted proxy core is `xray`.
- Client builds embed the repository-pinned `libXray`; Gateway and Relay nodes
  use the pinned Xray-core package.
- sing-box identifiers, dependencies, configurations, binaries, and fallback
  paths are outside the v1 contract.
- Signed documents never contain WireGuard private keys, refresh tokens, or
  Vault tokens.
- A Gateway snapshot with no peers is rejected unless its safety block
  explicitly authorizes an empty peer set.
- Configuration generation is monotonic and expired documents are rejected.

## SignedConfig signing bytes

The Ed25519 signature covers compact UTF-8 JSON with no trailing newline and
without the top-level `signature` member. Top-level member order is fixed as:

```text
schema_version, config_id, network_id, device_id, generation,
issued_at, expires_at, proxy_core, transport, wireguard
```

Nested member order and timestamp requirements are frozen by the reusable
`vectors/signed-config-ed25519.json` interoperability vector. Go, Dart, Swift,
Kotlin, and Windows implementations must reproduce and verify that vector
before accepting the v1 SignedConfig capability. The included seed is test
material and must never be used as a deployment key.

## Validation

Install the isolated development dependency and run the fixture suite:

```bash
python3 -m pip install -r vpn-overlay/contracts/requirements.txt
vpn-overlay/contracts/scripts/validate.sh
```

Every fixture must be registered in `tests/test_contracts.py`. Add both a
valid fixture and a negative case when extending a security-sensitive field.
The JSON Schema checks structure; the test suite also enforces temporal,
generation, empty-peer, unique-device, and secret-field invariants.

The accounts control-plane repository is the canonical API and signing-protocol
source. These infrastructure copies are integration mirrors and must remain
byte-for-byte compatible with its schemas and interoperability vectors.
