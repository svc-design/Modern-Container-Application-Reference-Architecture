import hashlib
import json
import os
import re
import unittest
from base64 import b64decode, urlsafe_b64decode
from copy import deepcopy
from datetime import datetime, timedelta
from ipaddress import ip_interface, ip_network
from pathlib import Path

from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey
from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[1]
SCHEMAS = ROOT / "schemas"
FIXTURES = ROOT / "fixtures"
VECTORS = ROOT / "vectors"


CASES = (
    ("product-plugin-manifest.schema.json", "valid/product-plugin-manifest.json", True),
    ("product-plugin-manifest.schema.json", "invalid/product-plugin-manifest-sing-box.json", False),
    ("signed-config.schema.json", "valid/signed-config.json", True),
    ("signed-config.schema.json", "invalid/signed-config-expired.json", False),
    ("signed-config-v2.schema.json", "valid/signed-config-v2.json", True),
    ("signed-config-v2.schema.json", "invalid/signed-config-v2-policy-origin.json", False),
    ("signed-config-v2.schema.json", "invalid/signed-config-v2-policy-binding.json", False),
    ("gateway-snapshot.schema.json", "valid/gateway-snapshot.json", True),
    ("gateway-snapshot.schema.json", "invalid/gateway-snapshot-empty-peers.json", False),
    ("signing-keys-response.schema.json", "valid/signing-keys-response.json", True),
    ("signing-keys-response.schema.json", "invalid/signing-keys-private-key.json", False),
    ("join-token-create-request.schema.json", "valid/join-token-create-request.json", True),
    ("join-token-create-request.schema.json", "invalid/join-token-create-remaining-uses.json", False),
    ("join-token-create-response.schema.json", "valid/join-token-create-response.json", True),
    ("join-token-create-response.schema.json", "invalid/join-token-create-response-reusable.json", False),
    ("join-token-exchange-request.schema.json", "valid/join-token-exchange-request.json", True),
    ("join-token-exchange-request.schema.json", "invalid/join-token-exchange-raw-secret-redaction.json", False),
    ("join-token-exchange-response.schema.json", "valid/join-token-exchange-response.json", True),
    ("join-token-exchange-response.schema.json", "invalid/join-token-exchange-admin-scope.json", False),
    ("device-session-mint-request.schema.json", "valid/device-session-mint-request.json", True),
    ("device-session-mint-request.schema.json", "invalid/device-session-mint-request-extra.json", False),
    ("device-session-mint-response.schema.json", "valid/device-session-mint-response.json", True),
    ("device-session-mint-response.schema.json", "invalid/device-session-mint-response-admin-scope.json", False),
    ("device-credential-rotate-request.schema.json", "valid/device-credential-rotate-request.json", True),
    ("device-credential-rotate-request.schema.json", "invalid/device-credential-rotate-request-raw-secret.json", False),
    ("device-credential-rotate-response.schema.json", "valid/device-credential-rotate-response.json", True),
    ("device-credential-rotate-response.schema.json", "invalid/device-credential-rotate-response-secret.json", False),
    ("device-bound-revoke-request.schema.json", "valid/device-bound-revoke-request.json", True),
    ("device-bound-revoke-request.schema.json", "invalid/device-bound-revoke-request-selector.json", False),
    ("enrollment-config-ack.schema.json", "valid/enrollment-config-ack.json", True),
    ("enrollment-config-ack.schema.json", "invalid/enrollment-config-ack-secret.json", False),
    ("enrollment-config-ack-receipt.schema.json", "valid/enrollment-config-ack-receipt.json", True),
    ("enrollment-config-ack-receipt.schema.json", "invalid/enrollment-config-ack-receipt-negative.json", False),
    ("enrollment-signed-config-ack.schema.json", "valid/enrollment-signed-config-ack.json", True),
    ("enrollment-signed-config-ack.schema.json", "invalid/enrollment-signed-config-ack-trailing-field.json", False),
    ("enrollment-signed-config-ack-receipt.schema.json", "valid/enrollment-signed-config-ack-receipt.json", True),
    ("enrollment-signed-config-ack-receipt.schema.json", "invalid/enrollment-signed-config-ack-receipt-zero-generation.json", False),
    ("gateway-heartbeat.schema.json", "valid/gateway-heartbeat.json", True),
    ("gateway-heartbeat.schema.json", "valid/gateway-heartbeat-apply.json", True),
    ("gateway-heartbeat.schema.json", "invalid/gateway-heartbeat-runtime-apply.json", False),
    ("gateway-heartbeat.schema.json", "invalid/gateway-heartbeat-apply-ahead.json", False),
    ("gateway-apply-result.schema.json", "valid/gateway-apply-result.json", True),
    ("gateway-apply-result.schema.json", "valid/gateway-apply-result-applied.json", True),
    ("gateway-apply-result.schema.json", "valid/gateway-apply-result-rolled-back.json", True),
    ("gateway-apply-result.schema.json", "invalid/gateway-apply-result-runtime-write.json", False),
    ("gateway-apply-result.schema.json", "invalid/gateway-apply-result-applied-generation-mismatch.json", False),
    ("gateway-apply-result-receipt.schema.json", "valid/gateway-apply-result-receipt.json", True),
    ("gateway-apply-result-receipt.schema.json", "invalid/gateway-apply-result-receipt-extra.json", False),
    ("node-credential-create-request.schema.json", "valid/node-credential-create-request.json", True),
    ("node-credential-create-request.schema.json", "invalid/node-credential-create-expiry.json", False),
    ("node-credential-create-response.schema.json", "valid/node-credential-create-response.json", True),
    ("node-credential-create-response.schema.json", "invalid/node-credential-create-response-private-key.json", False),
    ("static-client-import.schema.json", "valid/static-client-import.json", True),
    ("static-client-import.schema.json", "invalid/static-client-import-secret-tag.json", False),
    ("static-client-import-receipt.schema.json", "valid/static-client-import-receipt.json", True),
    ("static-client-import-receipt.schema.json", "invalid/static-client-import-receipt-bad-idempotency.json", False),
    ("control-plane-http-contracts.schema.json", "valid/control-plane-http-contracts.json", True),
    ("control-plane-http-contracts.schema.json", "invalid/control-plane-http-contracts-insecure.json", False),
    ("network-policy-v1alpha1.schema.json", "valid/network-policy-v1alpha1.json", True),
    ("network-policy-v1alpha1.schema.json", "invalid/network-policy-secret-field.json", False),
    ("policy-enforcement-artifact.schema.json", "valid/policy-enforcement-artifact.json", True),
    ("policy-enforcement-artifact.schema.json", "invalid/policy-enforcement-artifact-pii.json", False),
    ("device-key-rotate-request.schema.json", "valid/device-key-rotate-request.json", True),
    ("device-key-rotate-request.schema.json", "invalid/device-key-rotate-request-private-key.json", False),
    ("device-state-request.schema.json", "valid/device-state-request.json", True),
    ("device-state-request.schema.json", "invalid/device-state-request-zero-version.json", False),
    ("device-revoke-request.schema.json", "valid/device-revoke-request.json", True),
    ("device-revoke-request.schema.json", "invalid/device-revoke-request-owner-email.json", False),
    ("enrollment-device-revoke-request.schema.json", "valid/enrollment-device-revoke-request.json", True),
    ("enrollment-device-revoke-request.schema.json", "invalid/enrollment-device-revoke-request-scope.json", False),
    ("device-lifecycle-response.schema.json", "valid/device-lifecycle-response.json", True),
    ("device-lifecycle-response.schema.json", "valid/device-lifecycle-response-revoked.json", True),
    ("device-lifecycle-response.schema.json", "valid/device-lifecycle-response-reconcile-pending.json", True),
    ("device-lifecycle-response.schema.json", "invalid/device-lifecycle-response-revoked-without-time.json", False),
    ("policy-reconcile-receipt.schema.json", "valid/policy-reconcile-receipt.json", True),
    ("policy-reconcile-receipt.schema.json", "invalid/policy-reconcile-receipt-inconsistent.json", False),
)

RAW_SECRET = re.compile(r"\bx(?:jt|enr|gn|dc)_[A-Za-z0-9_.-]{40,}\b")
SECRET_TAG_PREFIXES = (
    "private_key:", "preshared_key:", "auth_id:", "password:", "token:",
    "secret:", "credential:", "uuid:", "vless_uuid:",
)


def _unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate JSON member: {key}")
        result[key] = value
    return result


def strict_json_bytes(raw: bytes):
    text = raw.decode("utf-8")
    decoder = json.JSONDecoder(object_pairs_hook=_unique_object)
    value, end = decoder.raw_decode(text)
    if text[end:].strip():
        raise ValueError("trailing JSON value or content")
    return value


def load_json(path: Path):
    return strict_json_bytes(path.read_bytes())


def parse_time(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def static_device_bytes(devices: list[dict]) -> bytes:
    return json.dumps(devices, separators=(",", ":"), ensure_ascii=False).encode()


def semantic_errors(schema_name: str, document: dict, fixture_name: str = "") -> list[str]:
    errors: list[str] = []
    if "issued_at" in document and "expires_at" in document:
        if parse_time(document["expires_at"]) <= parse_time(document["issued_at"]):
            errors.append("expires_at must be later than issued_at")
    if "proxy_core" in document and document["proxy_core"] != "xray":
        errors.append("v1 proxy_core must be xray")
    if "runtime_core_id" in document and document["runtime_core_id"] != "xray":
        errors.append("v1 runtime_core_id must be xray")

    if schema_name == "product-plugin-manifest.schema.json":
        if document.get("delivery") != "built-in":
            errors.append("v1 plugins must use built-in delivery")
        minimum = tuple(int(part) for part in document["host_api"]["minimum"].split("."))
        maximum = tuple(int(part) for part in document["host_api"]["maximum_exclusive"].split("."))
        if minimum >= maximum:
            errors.append("host_api maximum_exclusive must exceed minimum")

    if schema_name == "signed-config-v2.schema.json" and "policy" in document:
        policy = document["policy"]
        expected_path = f'/api/overlay/v1/enrollment/policy-artifacts/{policy["generation"]}/{policy["digest"]}'
        if policy["path"] != expected_path:
            errors.append("signed policy path must match generation and digest")

    if schema_name == "join-token-exchange-response.schema.json" and "device_credential" in document:
        credential = document["device_credential"]
        issued_at = parse_time(credential["issued_at"])
        expires_at = parse_time(credential["expires_at"])
        if expires_at <= issued_at or expires_at - issued_at > timedelta(days=31):
            errors.append("device credential lifetime must be positive and at most 31 days")
        raw_id = credential["credential"].split(".", 1)[0].removeprefix("xdc_")
        if credential["credential_id"] != f"xdcid_{raw_id}":
            errors.append("device credential id must match the raw credential id")

    if schema_name == "device-session-mint-response.schema.json":
        lifetime = parse_time(document["expires_at"]) - parse_time(document["issued_at"])
        if lifetime <= timedelta(0) or lifetime > timedelta(minutes=15):
            errors.append("device session lifetime must be positive and at most 15 minutes")

    if schema_name == "device-credential-rotate-response.schema.json":
        lifetime = parse_time(document["expires_at"]) - parse_time(document["issued_at"])
        if lifetime <= timedelta(0) or lifetime > timedelta(days=31):
            errors.append("rotated device credential lifetime must be positive and at most 31 days")
        if document["credential_id"] == document["replaces_credential_id"]:
            errors.append("rotation must replace a different credential id")

    if schema_name == "gateway-snapshot.schema.json":
        if document["generation"] <= document["expected_previous_generation"]:
            errors.append("generation must advance expected_previous_generation")
        peers = document["wireguard"]["peers"]
        if not peers and not document["safety"]["allow_empty_peers"]:
            errors.append("empty peers require an explicit safety override")
        device_ids = [peer["device_id"] for peer in peers]
        if len(device_ids) != len(set(device_ids)):
            errors.append("gateway peer device_id values must be unique")

    if schema_name == "signing-keys-response.schema.json":
        keys = document.get("keys", [])
        key_ids = [item.get("key_id") for item in keys]
        if len(key_ids) != len(set(key_ids)):
            errors.append("signing key ids must be unique")
        if sum(item.get("status") == "current" for item in keys) != 1:
            errors.append("exactly one signing key must be current")
        for item in keys:
            if item.get("not_after") and parse_time(item["not_after"]) <= parse_time(item["not_before"]):
                errors.append("signing key not_after must follow not_before")

    if schema_name == "gateway-apply-result.schema.json":
        diff = document.get("diff", {})
        if diff.get("status") == "unavailable":
            if diff.get("equal") or any(diff.get(key) for key in ("current_peers", "missing_peers", "unexpected_peers", "route_mismatches")):
                errors.append("unavailable WireGuard diff must not invent current state")
        elif diff.get("status") == "available":
            common_projected = diff.get("projected_peers", 0) - diff.get("missing_peers", 0)
            common_current = diff.get("current_peers", 0) - diff.get("unexpected_peers", 0)
            equal = not any(diff.get(key) for key in ("missing_peers", "unexpected_peers", "route_mismatches"))
            if common_projected != common_current or diff.get("route_mismatches", 0) > common_projected or diff.get("equal") != equal:
                errors.append("Gateway diff counters are inconsistent")
        result = document.get("result")
        observed = document.get("observed_generation", 0)
        applied = document.get("applied_generation", 0)
        if applied > observed:
            errors.append("applied generation cannot exceed observed generation")
        if result == "applied":
            if applied != observed or not document.get("runtime_applied") or diff.get("status") != "available" or not diff.get("equal"):
                errors.append("applied result requires exact generation and equal runtime readback")
        elif result in ("apply_rejected", "apply_failed_rolled_back", "apply_failed_rollback_failed"):
            if applied >= observed or document.get("runtime_applied"):
                errors.append("apply failure must preserve an older applied checkpoint")
        elif result in ("shadow_validated", "shadow_validated_wg_unavailable", "shadow_rejected"):
            if applied != 0 or document.get("runtime_applied"):
                errors.append("shadow result cannot report runtime mutation")

    if schema_name == "gateway-heartbeat.schema.json":
        if document.get("applied_generation", 0) > document.get("observed_generation", 0):
            errors.append("heartbeat applied generation cannot exceed observed generation")

    if schema_name == "device-lifecycle-response.schema.json":
        device = document.get("device", {})
        revoked = device.get("status") == "revoked"
        if revoked != bool(device.get("revoked_at")) or revoked != bool(device.get("revoked_reason")):
            errors.append("revoked device state requires a timestamp and reason")
        if document.get("revoked") is True and not revoked:
            errors.append("revoked response must contain a revoked device")
        if document.get("policy_reconcile_pending") is True and ("policy_generation" in document or "policy_digest" in document):
            errors.append("pending reconcile must not claim a completed policy generation")

    if schema_name == "policy-reconcile-receipt.schema.json":
        if document.get("processed") != document.get("completed", 0) + document.get("failed", 0):
            errors.append("reconcile receipt counters are inconsistent")

    if schema_name == "static-client-import.schema.json":
        devices = document.get("devices", [])
        if devices != sorted(devices, key=lambda item: item.get("device_id", "")):
            errors.append("static import devices must be sorted by device_id")
        for field in ("device_id", "wireguard_public_key"):
            values = [item.get(field) for item in devices]
            if len(values) != len(set(values)):
                errors.append(f"static import {field} values must be unique")
        addresses = [value for item in devices for value in item.get("addresses", [])]
        if len(addresses) != len(set(addresses)):
            errors.append("static import addresses must be unique")
        for item in devices:
            if item.get("tags", []) != sorted(item.get("tags", [])):
                errors.append("static import tags must be sorted")
            if item.get("attachments", []) != sorted(item.get("attachments", [])):
                errors.append("static import attachments must be sorted")
            for tag in item.get("tags", []):
                if tag.lower().startswith(SECRET_TAG_PREFIXES):
                    errors.append("static import tags must not contain secret material")
        digest = hashlib.sha256(static_device_bytes(devices)).hexdigest()
        if document.get("source", {}).get("baseline_sha256") != digest:
            errors.append("static import baseline_sha256 does not match canonical devices")

    if schema_name == "control-plane-http-contracts.schema.json" and document.get("https_required"):
        endpoints = document.get("endpoints", [])
        identities = [(item.get("method"), item.get("path"), item.get("accept")) for item in endpoints]
        if len(identities) != len(set(identities)):
            errors.append("HTTP endpoint method/path/accept tuples must be unique")
        for endpoint in endpoints:
            for member in ("request", "response"):
                referenced = endpoint.get(member)
                if referenced is not None and not (SCHEMAS / referenced).is_file():
                    errors.append(f"HTTP contract references missing schema: {referenced}")

    if schema_name == "policy-enforcement-artifact.schema.json":
        required_flows = [
            "control:controller-session",
            "control:gateway-apply-result",
            "control:gateway-heartbeat",
            "control:gateway-policy-artifact",
            "control:gateway-snapshot",
        ]
        if document.get("protected_flows") != required_flows:
            errors.append("protected control flows must be complete and canonical")
        rules = document.get("rules", [])
        canonical_order = sorted(rules, key=lambda rule: (rule.get("action") != "deny", rule.get("id", "")))
        if rules != canonical_order:
            errors.append("enforcement rules must use canonical deny-first order")
        if document.get("revision") == 0 and rules:
            errors.append("bootstrap policy revision zero must be empty")
        for rule in rules:
            for member in ("source_devices", "destination_devices", "protocols", "ports"):
                values = rule.get(member, [])
                if values != sorted(values):
                    errors.append(f"policy rule {member} must be sorted")
            protocols = rule.get("protocols", [])
            ports = rule.get("ports", [])
            if protocols == ["icmp"] and ports:
                errors.append("ICMP-only policy rules must not contain ports")
            if protocols != ["icmp"] and not ports:
                errors.append("TCP/UDP policy rules require ports")

    def validate_network_values(value):
        if isinstance(value, dict):
            for key, child in value.items():
                if key == "addresses" and isinstance(child, list):
                    for address in child:
                        try:
                            ip_interface(address)
                        except ValueError:
                            errors.append(f"invalid interface address: {address}")
                elif key == "allowed_ips" and isinstance(child, list):
                    for network in child:
                        try:
                            ip_network(network, strict=False)
                        except ValueError:
                            errors.append(f"invalid allowed IP network: {network}")
                validate_network_values(child)
        elif isinstance(value, list):
            for child in value:
                validate_network_values(child)

    validate_network_values(document)
    allowed_secret_fields = {
        "join-token-exchange-request.schema.json": {"join_token"},
        "join-token-exchange-response.schema.json": {"enrollment_token", "credential"},
        "device-session-mint-response.schema.json": {"enrollment_token"},
        "node-credential-create-response.schema.json": {"credential", "bearer_token"},
    }.get(schema_name, set())
    forbidden = {"private_key", "preshared_key", "refresh_token", "vault_token", "password", "token", "secret", "credential"}

    def walk(value):
        if isinstance(value, dict):
            for key, child in value.items():
                if key.lower() in forbidden and key not in allowed_secret_fields:
                    errors.append(f"forbidden secret field: {key}")
                walk(child)
        elif isinstance(value, list):
            for child in value:
                walk(child)

    walk(document)
    if RAW_SECRET.search(json.dumps(document)) and fixture_name != "valid/join-token-exchange-response.json":
        errors.append("raw secret-shaped value is forbidden in committed consumer fixtures")
    return errors


class ContractFixtureTests(unittest.TestCase):
    def test_schemas_are_valid_draft_2020_12(self):
        for path in sorted(SCHEMAS.glob("*.schema.json")):
            with self.subTest(schema=path.name):
                Draft202012Validator.check_schema(load_json(path))

    def test_fixture_matrix(self):
        for schema_name, fixture_name, expected_valid in CASES:
            with self.subTest(schema=schema_name, fixture=fixture_name):
                schema = load_json(SCHEMAS / schema_name)
                document = load_json(FIXTURES / fixture_name)
                errors = [error.message for error in Draft202012Validator(schema, format_checker=FormatChecker()).iter_errors(document)]
                errors.extend(semantic_errors(schema_name, document, fixture_name))
                self.assertEqual(expected_valid, not errors, msg="; ".join(errors))

    def test_every_fixture_is_registered(self):
        registered = {fixture for _, fixture, _ in CASES}
        discovered = {str(path.relative_to(FIXTURES)) for path in FIXTURES.glob("*/*.json")}
        self.assertEqual(discovered, registered)

    def test_valid_documents_reject_unknown_top_level_members(self):
        seen = set()
        for schema_name, fixture_name, expected_valid in CASES:
            if not expected_valid or schema_name in seen:
                continue
            seen.add(schema_name)
            document = deepcopy(load_json(FIXTURES / fixture_name))
            document["unexpected_contract_member"] = True
            validator = Draft202012Validator(load_json(SCHEMAS / schema_name))
            with self.subTest(schema=schema_name):
                self.assertTrue(list(validator.iter_errors(document)))

    def test_one_time_and_gateway_mode_guard_property_smoke(self):
        join_schema = load_json(SCHEMAS / "join-token-create-request.schema.json")
        join_validator = Draft202012Validator(join_schema)
        for remaining_uses in range(-8, 9):
            document = {"remaining_uses": remaining_uses}
            self.assertEqual(not list(join_validator.iter_errors(document)), remaining_uses in (0, 1))

        heartbeat_schema = load_json(SCHEMAS / "gateway-heartbeat.schema.json")
        heartbeat = load_json(FIXTURES / "valid/gateway-heartbeat.json")
        for field, unsafe_value in (("proxy_core", "sing-box"), ("applied_generation", 1)):
            candidate = deepcopy(heartbeat)
            candidate[field] = unsafe_value
            with self.subTest(field=field):
                self.assertTrue(list(Draft202012Validator(heartbeat_schema).iter_errors(candidate)))

        apply_heartbeat = load_json(FIXTURES / "valid/gateway-heartbeat-apply.json")
        for applied in range(38, 46):
            candidate = deepcopy(apply_heartbeat)
            candidate["applied_generation"] = applied
            valid = not list(Draft202012Validator(heartbeat_schema).iter_errors(candidate))
            valid = valid and not semantic_errors("gateway-heartbeat.schema.json", candidate)
            self.assertEqual(valid, applied <= candidate["observed_generation"])

    def test_gateway_apply_result_state_machine(self):
        vector = load_json(VECTORS / "gateway-apply-result-transitions.json")

        def allowed(previous, next_result):
            if previous is None:
                return True
            if previous == next_result:
                return True
            return previous in ("apply_rejected", "apply_failed_rolled_back") and next_result == "applied"

        for case in vector["transitions"]:
            with self.subTest(previous=case["previous"], next=case["next"]):
                self.assertEqual(case["allowed"], allowed(case["previous"], case["next"]))

    def test_device_credential_lifetime_scope_and_rotation_guards(self):
        exchange = load_json(FIXTURES / "valid/join-token-exchange-response.json")
        expired = deepcopy(exchange)
        expired["device_credential"]["expires_at"] = "2026-10-01T12:00:00Z"
        self.assertIn(
            "device credential lifetime must be positive and at most 31 days",
            semantic_errors("join-token-exchange-response.schema.json", expired),
        )
        mismatched_id = deepcopy(exchange)
        mismatched_id["device_credential"]["credential_id"] = "xdcid_ffffffffffffffffffffffffffffffff"
        self.assertIn(
            "device credential id must match the raw credential id",
            semantic_errors("join-token-exchange-response.schema.json", mismatched_id),
        )

        session = load_json(FIXTURES / "valid/device-session-mint-response.json")
        request = load_json(FIXTURES / "valid/device-session-mint-request.json")
        self.assertEqual(session["client_nonce"], request["client_nonce"])
        overlong = deepcopy(session)
        overlong["expires_at"] = "2026-08-28T12:16:00Z"
        self.assertIn(
            "device session lifetime must be positive and at most 15 minutes",
            semantic_errors("device-session-mint-response.schema.json", overlong),
        )

        rotation = load_json(FIXTURES / "valid/device-credential-rotate-response.json")
        same_id = deepcopy(rotation)
        same_id["replaces_credential_id"] = same_id["credential_id"]
        self.assertIn(
            "rotation must replace a different credential id",
            semantic_errors("device-credential-rotate-response.schema.json", same_id),
        )

    def test_device_credential_authorization_vector(self):
        vector = load_json(VECTORS / "device-credential-authorization.json")

        def authorize(case):
            if not case["verifier_match"]:
                return False, "unauthorized"
            if case["action"] == "revoke" and case["device_status"] == "revoked":
                return True, "terminal_receipt"
            if case["credential_status"] != "active" or case["device_status"] != "active":
                return False, "unauthorized"
            return True, "minted" if case["action"] == "session" else "rotated"

        for case in vector["cases"]:
            with self.subTest(case=case["name"]):
                allowed, result = authorize(case)
                self.assertEqual((allowed, result), (case["allowed"], case["result"]))

    def test_device_credential_wire_vector(self):
        vector = load_json(VECTORS / "device-credential-wire.json")
        exchange = load_json(FIXTURES / "valid/join-token-exchange-response.json")
        credential = exchange["device_credential"]
        self.assertEqual(vector["authorization_scheme"], credential["token_type"])
        self.assertRegex(credential["credential_id"], re.compile(vector["credential_id_pattern"]))
        self.assertRegex(credential["credential"], re.compile(vector["credential_pattern"]))
        raw_id, encoded = credential["credential"].removeprefix("xdc_").split(".", 1)
        self.assertEqual(credential["credential_id"], f"xdcid_{raw_id}")
        self.assertEqual(len(urlsafe_b64decode(encoded + "=")), vector["secret_bytes"])
        successor = vector["rotation_example_credential"]
        self.assertEqual(hashlib.sha256(successor.encode("utf-8")).hexdigest(), vector["rotation_example_sha256"])
        request = load_json(FIXTURES / "valid/device-credential-rotate-request.json")
        self.assertEqual(request["new_credential_sha256"], vector["rotation_example_sha256"])

    def test_policy_generation_reserves_bootstrap_floor(self):
        vector = load_json(VECTORS / "policy-generation-transitions.json")
        states = vector["states"]
        self.assertEqual(states[0], {"name": "bootstrap-default-deny", "generation": 1})
        self.assertEqual([state["generation"] for state in states], list(range(1, len(states) + 1)))

    def test_all_contract_json_is_strict(self):
        for path in sorted(ROOT.rglob("*.json")):
            with self.subTest(path=path.relative_to(ROOT)):
                load_json(path)
        with self.assertRaisesRegex(ValueError, "duplicate JSON member"):
            strict_json_bytes(b'{"schema_version":1,"schema_version":1}')
        with self.assertRaisesRegex(ValueError, "trailing JSON"):
            strict_json_bytes(b'{} {}')

    def test_secret_fields_are_rejected_semantically(self):
        document = deepcopy(load_json(FIXTURES / "valid/signed-config.json"))
        document["wireguard"]["private_key"] = "must-not-cross-the-control-plane"
        self.assertIn("forbidden secret field: private_key", semantic_errors("signed-config.schema.json", document))

    def test_raw_token_material_is_quarantined_to_redaction_case(self):
        raw_secret_files = []
        for path in sorted(ROOT.rglob("*.json")):
            if RAW_SECRET.search(path.read_text(encoding="utf-8")):
                raw_secret_files.append(str(path.relative_to(ROOT)))
        self.assertEqual(raw_secret_files, [
            "fixtures/invalid/join-token-exchange-raw-secret-redaction.json",
            "fixtures/valid/join-token-exchange-response.json",
            "vectors/device-credential-wire.json",
        ])

    def test_invalid_cidr_is_rejected_semantically(self):
        document = deepcopy(load_json(FIXTURES / "valid/gateway-snapshot.json"))
        document["wireguard"]["peers"][0]["allowed_ips"] = ["999.77.0.10/32"]
        self.assertIn("invalid allowed IP network: 999.77.0.10/32", semantic_errors("gateway-snapshot.schema.json", document))

    def test_static_import_canonical_hash_and_receipt(self):
        document = load_json(FIXTURES / "valid/static-client-import.json")
        canonical = json.dumps(document, separators=(",", ":"), ensure_ascii=False).encode()
        expected = "911905502b4aa02c4c82b16e200f5f13caebd534898566b8b87384d972ed1fd2"
        self.assertEqual(hashlib.sha256(canonical).hexdigest(), expected)
        receipt = load_json(FIXTURES / "valid/static-client-import-receipt.json")
        self.assertEqual(receipt["idempotency_key"], f"sha256-{expected}")
        tampered = deepcopy(document)
        tampered["devices"][0]["addresses"] = ["10.77.0.99/32"]
        self.assertIn("static import baseline_sha256 does not match canonical devices", semantic_errors("static-client-import.schema.json", tampered))
        for duplicate_field in ("device_id", "wireguard_public_key", "addresses"):
            duplicate = deepcopy(document)
            if duplicate_field == "addresses":
                duplicate["devices"][1]["addresses"] = duplicate["devices"][0]["addresses"]
            else:
                duplicate["devices"][1][duplicate_field] = duplicate["devices"][0][duplicate_field]
            self.assertTrue(
                any("must be unique" in error for error in semantic_errors("static-client-import.schema.json", duplicate)),
                msg=f"duplicate {duplicate_field} escaped semantic validation",
            )

    def _verify_vector(self, name: str, expected_order: list[str]):
        vector = load_json(VECTORS / name)
        payload = vector["signing_payload_utf8"].encode("utf-8")
        document = strict_json_bytes(payload)
        self.assertEqual(list(document), expected_order)
        public_key = Ed25519PublicKey.from_public_bytes(b64decode(vector["public_key_base64"], validate=True))
        public_key.verify(b64decode(vector["signature_base64"], validate=True), payload)

    def test_signed_config_ed25519_interoperability_vector(self):
        self._verify_vector("signed-config-ed25519.json", [
            "schema_version", "config_id", "network_id", "device_id", "generation",
            "issued_at", "expires_at", "proxy_core", "transport", "wireguard",
        ])

    def test_signed_config_v2_ed25519_interoperability_vector(self):
        expected_order = [
            "schema_version", "config_id", "network_id", "device_id", "generation",
            "issued_at", "expires_at", "proxy_core", "transport", "wireguard", "policy",
        ]
        self._verify_vector("signed-config-v2-ed25519.json", expected_order)
        vector = load_json(VECTORS / "signed-config-v2-ed25519.json")
        fixture = load_json(FIXTURES / "valid/signed-config-v2.json")
        self.assertEqual(fixture["signature"]["value"], vector["signature_base64"])
        payload = strict_json_bytes(vector["signing_payload_utf8"].encode())
        self.assertEqual(payload["policy"]["digest"], load_json(VECTORS / "compatibility-matrix.json")["policy_enforcement"]["canonical_sha256"])

    def test_gateway_snapshot_ed25519_interoperability_vector(self):
        expected_order = [
            "schema_version", "snapshot_id", "node_id", "generation", "expected_previous_generation",
            "issued_at", "expires_at", "proxy_core", "safety", "wireguard", "relay", "policy",
        ]
        self._verify_vector("gateway-snapshot-ed25519.json", expected_order)
        vector = load_json(VECTORS / "gateway-snapshot-ed25519.json")
        document = strict_json_bytes(vector["signing_payload_utf8"].encode())
        document["signature"] = {"algorithm": "Ed25519", "key_id": vector["key_id"], "value": vector["signature_base64"]}
        schema = load_json(SCHEMAS / "gateway-snapshot.schema.json")
        self.assertFalse(list(Draft202012Validator(schema, format_checker=FormatChecker()).iter_errors(document)))
        self.assertFalse(semantic_errors("gateway-snapshot.schema.json", document))

    def test_policy_enforcement_interoperability_golden(self):
        fixture = FIXTURES / "valid/policy-enforcement-artifact.json"
        expected = load_json(VECTORS / "compatibility-matrix.json")["policy_enforcement"]["canonical_sha256"]
        canonical = json.dumps(load_json(fixture), separators=(",", ":"), ensure_ascii=False).encode()
        self.assertEqual(hashlib.sha256(canonical).hexdigest(), expected)
        for variable in (
            "XCONNECT_ACCOUNTS_POLICY_ARTIFACT",
            "XCONNECT_PLAYBOOKS_POLICY_ARTIFACT",
        ):
            candidate = os.environ.get(variable)
            if candidate:
                with self.subTest(mirror=variable):
                    self.assertEqual(Path(candidate).read_bytes(), fixture.read_bytes())
                    mirrored = json.dumps(load_json(Path(candidate)), separators=(",", ":"), ensure_ascii=False).encode()
                    self.assertEqual(hashlib.sha256(mirrored).hexdigest(), expected)

    def test_signed_config_vector_compatibility_hash(self):
        matrix = load_json(VECTORS / "compatibility-matrix.json")
        expected = matrix["signed_config"]["sha256"]
        self.assertEqual(hashlib.sha256((VECTORS / "signed-config-ed25519.json").read_bytes()).hexdigest(), expected)
        for variable in ("XCONNECT_ACCOUNTS_SIGNED_CONFIG_VECTOR", "XCONNECT_CLIENT_SIGNED_CONFIG_VECTOR"):
            candidate = os.environ.get(variable)
            if candidate:
                with self.subTest(mirror=variable):
                    self.assertEqual(hashlib.sha256(Path(candidate).read_bytes()).hexdigest(), expected)

    def test_signed_config_v2_vector_compatibility_hash(self):
        matrix = load_json(VECTORS / "compatibility-matrix.json")
        expected = matrix["signed_config_v2"]["sha256"]
        vector = VECTORS / "signed-config-v2-ed25519.json"
        self.assertEqual(hashlib.sha256(vector.read_bytes()).hexdigest(), expected)
        for variable in ("XCONNECT_ACCOUNTS_SIGNED_CONFIG_V2_VECTOR", "XCONNECT_CLIENT_SIGNED_CONFIG_V2_VECTOR"):
            candidate = os.environ.get(variable)
            if candidate:
                with self.subTest(mirror=variable):
                    self.assertEqual(hashlib.sha256(Path(candidate).read_bytes()).hexdigest(), expected)

    def test_http_security_boundary(self):
        document = load_json(FIXTURES / "valid/control-plane-http-contracts.json")
        by_path = {item["path"]: item for item in document["endpoints"]}
        self.assertTrue(document["https_required"])
        self.assertEqual(by_path["/api/internal/overlay/v1/nodes/heartbeat"]["auth"], "gateway-node-bearer")
        self.assertEqual(by_path["/api/internal/overlay/v1/imports/static-clients"]["auth"], "x-service-token")
        self.assertEqual(by_path["/api/internal/overlay/v1/imports/static-clients"]["idempotency_key"], "sha256-canonical-body")
        self.assertEqual(by_path["/api/overlay/v1/device/session"]["auth"], "device-bearer")
        self.assertEqual(by_path["/api/overlay/v1/device/credential/rotate"]["idempotency_key"], "sha256-canonical-body")
        self.assertEqual(by_path["/api/overlay/v1/device/revoke"]["request"], "device-bound-revoke-request.schema.json")
        self.assertEqual(by_path["/api/overlay/v1/device/revoke"]["idempotency_key"], "sha256-canonical-body")
        for path in (
            "/api/overlay/v1/join-tokens", "/api/overlay/v1/join-tokens/exchange",
            "/api/overlay/v1/device/session", "/api/overlay/v1/device/credential/rotate",
            "/api/overlay/v1/device/revoke",
            "/api/overlay/v1/enrollment/policy-artifacts/{generation}/{digest}",
            "/api/internal/overlay/v1/nodes/heartbeat", "/api/internal/overlay/v1/nodes/{node_id}/snapshot",
            "/api/internal/overlay/v1/nodes/{node_id}/apply-result", "/api/internal/overlay/v1/imports/static-clients",
            "/api/internal/overlay/v1/nodes/{node_id}/policy-artifacts/{generation}/{digest}",
        ):
            self.assertIn("no-store", by_path[path]["cache_control"])
        policy = by_path["/api/internal/overlay/v1/nodes/{node_id}/policy-artifacts/{generation}/{digest}"]
        self.assertEqual(policy["auth"], "gateway-node-bearer")
        self.assertEqual(policy["response"], "policy-enforcement-artifact.schema.json")
        signed_config_representations = [
            item for item in document["endpoints"]
            if item["path"] == "/api/overlay/v1/enrollment/signed-config"
        ]
        self.assertEqual(len(signed_config_representations), 2)
        by_accept = {item.get("accept"): item for item in signed_config_representations}
        self.assertEqual(by_accept[None]["response"], "signed-config.schema.json")
        self.assertEqual(by_accept["application/vnd.xconnect.signed-config.v2+json"]["response"], "signed-config-v2.schema.json")
        self.assertTrue(all(item.get("vary") == "Accept" for item in signed_config_representations))
        client_policy = by_path["/api/overlay/v1/enrollment/policy-artifacts/{generation}/{digest}"]
        self.assertEqual(client_policy["auth"], "enrollment-bearer")
        self.assertEqual(client_policy["cache_control"], "private, no-store")


if __name__ == "__main__":
    unittest.main()
