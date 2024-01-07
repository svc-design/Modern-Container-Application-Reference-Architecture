#!/bin/bash

# Function to check if a variable is empty
check_empty() {
    if [ -z "${!1}" ]; then
        echo "$1 is empty. Aborting."
        exit 1
    fi
}

# List of variables to check
variables=("SSH_USER" "SSH_HOST_IP" "SSH_HOST_DOMAIN" "SSH_PRIVATE_KEY")

# Loop through variables and check if each one is empty
for var in "${variables[@]}"; do
    check_empty "$var"
done

mkdir -pv ~/.ssh/
cat > ~/.ssh/id_rsa << EOF
$SSH_PRIVATE_KEY
EOF
sudo chmod 0400 ~/.ssh/id_rsa
md5sum ~/.ssh/id_rsa

mkdir -pv hosts/

cat > hosts/inventory << EOF
[master]
$SSH_HOST_DOMAIN               ansible_host=$SSH_HOST_IP

[all:vars]
ansible_port=22
ansible_ssh_user=$SSH_USER
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_host_key_checking=False
ingress_ip=$SSH_HOST_IP
EOF

cat hosts/inventory
