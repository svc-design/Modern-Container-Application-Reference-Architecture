#!/usr/bin/env python3

import hvac
import os
import shutil
from datetime import datetime

# Set your Vault configurations
vault_url = "{{ vault_url }}"
vault_token = "{{ vault_token }}"
vault_secret_path = "{{ vault_secret_path }}"
domain = "{{ domain }}"

# Connect to Vault
client = hvac.Client(url=vault_url, token=vault_token)

# Fetch Certificate and Private Key from Vault
vault_result = client.read(vault_secret_path)

if vault_result and 'data' in vault_result:
    certificate = vault_result['data'].get('certificate', '')
    private_key = vault_result['data'].get('private_key', '')

    # Paths for certificate and private key files
    cert_path = f"/etc/ssl/{domain}.pem"
    key_path = f"/etc/ssl/{domain}.key"

    # Check if files already exist
    cert_exists = os.path.exists(cert_path)
    key_exists = os.path.exists(key_path)

    # Backup existing files with timestamp
    backup_dir = "/opt/bak/"
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")

    if cert_exists:
        backup_cert_path = f"{backup_dir}{domain}_{timestamp}.pem"
        shutil.move(cert_path, backup_cert_path)
        print(f"Backup created: {backup_cert_path}")

    if key_exists:
        backup_key_path = f"{backup_dir}{domain}_{timestamp}.key"
        shutil.move(key_path, backup_key_path)
        print(f"Backup created: {backup_key_path}")

    # Write Certificate to File (force overwrite)
    with open(cert_path, 'w') as cert_file:
        cert_file.write(certificate)

    # Write Private Key to File (force overwrite)
    with open(key_path, 'w') as key_file:
        key_file.write(private_key)

    # Set file permissions
    os.chmod(cert_path, 0o644)
    os.chown(cert_path, 0, 0)

    os.chmod(key_path, 0o600)
    os.chown(key_path, 0, 0)

    if cert_exists:
        print(f"Certificate updated: {cert_path}")
    else:
        print(f"Certificate written: {cert_path}")

    if key_exists:
        print(f"Private key updated: {key_path}")
    else:
        print(f"Private key written: {key_path}")
else:
    print("Failed to fetch certificate and private key from Vault.")
