# XConnect-One device credential lifecycle v1

The durable device credential (`xdc_`) authenticates one device in one overlay
network. It is separate from the one-time join invite, the short-lived
enrollment bearer (`xenr_`), WireGuard keys, Xray credentials, and account
tokens. It never authorizes account administration or direct config reads.

## Stored representation

The raw authorization value is exactly
`xdc_<32-lowercase-hex-id>.<43-base64url-characters>` and is sent only as
`Authorization: Device <value>`. The secret segment decodes to 32 random bytes,
must be canonical base64url without padding, and re-encodes byte-for-byte to
the same segment. Clients emit `Device`; HTTP scheme comparison is
ASCII-case-insensitive. `credential_id` is `xdcid_` plus the same hex id. The
database stores the id, device/network/user
binding, SHA-256 verifier, scope, expiry, status, and replacement relation. It
does not store the raw secret. Comparisons are constant-time after lookup by
id. Logs and audit events contain the credential id only.

One credential is active per device. Revoked, expired, replaced, suspended, or
device-revoked credentials cannot authorize a new session, rotation, or revoke.
The only exception is route-scoped replay of an already committed terminal
revoke receipt. Device revocation and credential revocation commit in the same
transaction.

## Join checkpoint

1. Exchange the one-time invite over HTTPS and require `Cache-Control:
   no-store`.
2. Validate exact scopes, device/network binding, token types, time windows,
   and all signing keys before accepting either secret.
3. Persist the `xdc_` value in protected storage before applying configuration.
4. Apply and verify the signed config, ACK it with the short `xenr_`, then erase
   `xenr_` from memory and the checkpoint.
5. A crash before ACK resumes from the protected checkpoint. It must not issue
   a second device or write either bearer into ordinary state files.

## Sync

`xconnect sync` authenticates with the device credential and mints a bearer
whose only scopes are `overlay:config:read` and `overlay:config:ack`. The bearer
expires in at most 15 minutes. The response must echo the request UUID nonce;
the client rejects a mismatch before accepting the bearer. It then verifies the
returned device/network binding and public signing-key ring. The new key ring
must contain a still-trusted key and exactly one current key; otherwise the
client retains the previous ring. It then fetches and verifies the signed config and any
verified policy reference, applies transactionally, ACKs, and destroys the
bearer. Failure preserves the last-known-good runtime and durable credential.

## Rotation

The client generates a new credential id and random secret, stores them as a
pending successor, and sends only the id and SHA-256 verifier of the UTF-8
bytes of the exact full `xdc_<id>.<secret>` value while authenticated by the
current credential. Accounts atomically activates the
successor and marks the old credential replaced. The canonical request digest
is the idempotency key.

If the response is lost, the client probes with the pending successor. Success
promotes it locally; a definitive not-active response permits retry with the
old credential. The pending secret is never overwritten until one credential
has been proven active. Rotation uses a new id and a maximum 31-day lifetime;
clients begin rotation before the remaining lifetime reaches seven days.

## Leave and recovery

`xconnect leave` calls the device-bound revoke endpoint directly with `xdc_`.
The UUID nonce and canonical request digest form the replay identity. Accounts
retains the verifier tombstone and terminal receipt: the revoke route may
verify a revoked credential only to replay that receipt, never to authorize a
different operation. This closes the lost-response window. Only a successful
or already-terminal server receipt permits local runtime and credential
deletion. A pending policy reconciliation still means the device
revocation committed and may be cleaned locally while surfacing the pending
Gateway convergence state.

If account administration revoked the device first, the same route may return
the current terminal receipt after verifying any historical credential bound
to that device. It still exposes no config and cannot reactivate the device.

`xconnect leave --local-only` is an explicit recovery operation: it removes
owned local runtime and secrets without claiming remote revocation. Losing the
only device credential requires account-authenticated device revocation and a
new one-time invite; the short enrollment bearer is never extended or reused
as a recovery credential.

## Platform storage boundary

- macOS: Keychain, with Packet Tunnel operations owned by the Network Extension.
- iOS: Keychain, accessed through the protected host bridge.
- Windows: Credential Manager or a DPAPI-protected application secret.
- Android: Keystore-backed encrypted storage through the protected host bridge.
- Linux: atomic owner-only file in the XConnect state directory; parent
  directory 0700 and file 0600, with symlink and ownership checks.

Diagnostics expose only credential id, expiry, storage health, and rotation
state. They never expose raw secrets or verifier digests.
