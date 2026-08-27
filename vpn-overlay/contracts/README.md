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

The control-plane repository becomes the canonical API source once its working
tree is restored. Until then these immutable `$id` values are the integration
baseline. Generated or mirrored copies must remain byte-for-byte compatible.
