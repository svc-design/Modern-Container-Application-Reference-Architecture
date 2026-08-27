import json
import unittest
from copy import deepcopy
from datetime import datetime
from ipaddress import ip_interface, ip_network
from pathlib import Path

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[1]
SCHEMAS = ROOT / "schemas"
FIXTURES = ROOT / "fixtures"


CASES = (
    ("product-plugin-manifest.schema.json", "valid/product-plugin-manifest.json", True),
    (
        "product-plugin-manifest.schema.json",
        "invalid/product-plugin-manifest-sing-box.json",
        False,
    ),
    ("signed-config.schema.json", "valid/signed-config.json", True),
    ("signed-config.schema.json", "invalid/signed-config-expired.json", False),
    ("gateway-snapshot.schema.json", "valid/gateway-snapshot.json", True),
    (
        "gateway-snapshot.schema.json",
        "invalid/gateway-snapshot-empty-peers.json",
        False,
    ),
)


def load_json(path: Path):
    with path.open(encoding="utf-8") as stream:
        return json.load(stream)


def parse_time(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def semantic_errors(schema_name: str, document: dict) -> list[str]:
    errors: list[str] = []

    if "issued_at" in document and "expires_at" in document:
        if parse_time(document["expires_at"]) <= parse_time(document["issued_at"]):
            errors.append("expires_at must be later than issued_at")

    if document.get("proxy_core") != "xray":
        errors.append("v1 proxy_core must be xray")

    if schema_name == "product-plugin-manifest.schema.json":
        if document.get("distribution") != "built_in":
            errors.append("v1 plugins must be built_in")

    if schema_name == "gateway-snapshot.schema.json":
        if document["generation"] <= document["expected_previous_generation"]:
            errors.append("generation must advance expected_previous_generation")
        peers = document["wireguard"]["peers"]
        if not peers and not document["safety"]["allow_empty_peers"]:
            errors.append("empty peers require an explicit safety override")
        device_ids = [peer["device_id"] for peer in peers]
        if len(device_ids) != len(set(device_ids)):
            errors.append("gateway peer device_id values must be unique")

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

    forbidden = {"private_key", "refresh_token", "vault_token"}

    def walk(value):
        if isinstance(value, dict):
            for key, child in value.items():
                if key.lower() in forbidden:
                    errors.append(f"forbidden secret field: {key}")
                walk(child)
        elif isinstance(value, list):
            for child in value:
                walk(child)

    walk(document)
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
                validator = Draft202012Validator(
                    schema,
                    format_checker=FormatChecker(),
                )
                errors = [error.message for error in validator.iter_errors(document)]
                errors.extend(semantic_errors(schema_name, document))
                self.assertEqual(
                    expected_valid,
                    not errors,
                    msg="; ".join(errors),
                )

    def test_every_fixture_is_registered(self):
        registered = {fixture for _, fixture, _ in CASES}
        discovered = {
            str(path.relative_to(FIXTURES))
            for path in FIXTURES.glob("*/*.json")
        }
        self.assertEqual(discovered, registered)

    def test_secret_fields_are_rejected_semantically(self):
        document = load_json(FIXTURES / "valid/signed-config.json")
        document = deepcopy(document)
        document["wireguard"]["private_key"] = "must-not-cross-the-control-plane"
        errors = semantic_errors("signed-config.schema.json", document)
        self.assertIn("forbidden secret field: private_key", errors)

    def test_invalid_cidr_is_rejected_semantically(self):
        document = load_json(FIXTURES / "valid/gateway-snapshot.json")
        document = deepcopy(document)
        document["wireguard"]["peers"][0]["allowed_ips"] = ["999.77.0.10/32"]
        errors = semantic_errors("gateway-snapshot.schema.json", document)
        self.assertIn("invalid allowed IP network: 999.77.0.10/32", errors)


if __name__ == "__main__":
    unittest.main()
