# XConnect-One signed client policy projection

SignedConfig v2 binds a client to the same canonical enforcement artifact used
by the Gateway. Accounts remains the producer. The client never accepts policy
generation, digest, path, or expiry from an unsigned HTTP field or CLI flag.

## Negotiation and compatibility

SignedConfig v1 remains the default representation. Only a request with the
exact v2 media type receives schema version 2. Accounts returns `Vary: Accept`
and `Cache-Control: private, no-store`; unsupported media types fail explicitly
instead of being silently downgraded. V1 and v2 have independent strict
decoders and signing field orders.

## Fetch and verification

1. Verify the Ed25519 SignedConfig, key status/window, device/network binding,
   config generation floor, and expiry.
2. Derive the expected policy path from its signed generation and digest and
   require exact equality with the signed relative path.
3. Resolve only against the original HTTPS Accounts origin. Do not follow a
   redirect, accept userinfo, switch authority, or consume a file/data URL.
4. Fetch with the short enrollment bearer and exact policy media type. Enforce
   `private, no-store` and a 4 MiB body ceiling.
5. Strictly decode and canonicalize the artifact, require network id and
   compiler contract, then compare SHA-256 to the signed digest.
6. Enforce the monotonic policy generation floor. Equal generation with a new
   digest or lower generation is a replay and preserves the last-known-good
   policy.

The artifact contains expanded device identifiers only. It contains no users,
email addresses, groups, tag owners, credentials, or private keys. A client may
use it for local defense-in-depth and `policy explain`; the Gateway remains the
authoritative network enforcement point.

## Transaction boundary

Config and policy are staged together. A new runtime is committed only after
both signed config and referenced policy validate. ACK occurs after runtime
readback. A fetch, signature, digest, replay, or apply failure preserves the
previous runtime and policy floor and destroys the short enrollment bearer.
