#!/bin/bash

check_empty() {
  if [ -z "$1" ]; then
    echo "$2"
    exit 1
  fi
}

check_empty "$1" "Please provide DOMAIN" && export DOMAIN=$1
check_empty "$2" "Please provide VAULT_ADDR" && export VAULT_ADDR=$2
check_empty "$3" "Please provide VAULT_TOKEN" && export VAULT_TOKEN=$3

SECRET_PATH="certs/$DOMAIN"

# Output paths
CERTIFICATE_PATH="/etc/ssl/${DOMAIN}.pem"
PRIVATE_KEY_PATH="/etc/ssl/${DOMAIN}.key"

vault login -address=$VAULT_ADDR $VAULT_TOKEN
# Read certificate from Vault
vault kv get -field=certificate certs/${DOMAIN} > "$CERTIFICATE_PATH"
# Read private key from Vault
vault kv get -field=private_key certs/${DOMAIN} > "$PRIVATE_KEY_PATH"

# Set permissions for the private key (modify as needed)
chmod 600 "$PRIVATE_KEY_PATH"

# Check if certificate and private key files are non-empty
if [ ! -s "$CERTIFICATE_PATH" ] || [ ! -s "$PRIVATE_KEY_PATH" ]; then
    echo "Certificate or private key is empty. Exiting..."
    exit 1
else
    echo "Certificate and private key have been written to $CERTIFICATE_PATH and $PRIVATE_KEY_PATH"
fi
