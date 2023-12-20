#!/bin/bash

# Function to check if a variable is empty
check_empty() {
    if [ -z "${!1}" ]; then
        echo "$1 is empty. Aborting."
        exit 1
    fi
}

# List of variables to check
variables=("DNS_AK" "DNS_SK" "OSS_AK" "OSS_SK" "ROOT_PASSWORD" "SMTP_PASSWORD" "GITLAB_OIDC_CLIENT_TOKEN" "HARBOR_OIDC_CLIENT_TOKEN" "SSH_USER" "SSH_HOST_IP" "SSH_HOST_DOMAIN" "SSH_PRIVATE_KEY")

# Loop through variables and check if each one is empty
for var in "${variables[@]}"; do
    check_empty "$var"
done

sudo apt install jq ansible -y

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
dns_ak=$DNS_AK
dns_sk=$DNS_SK
oss_ak=$OSS_AK
oss_sk=$OSS_SK
admin_password=$ROOT_PASSWORD
smtp_password=$SMTP_PASSWORD
gitlab_oidc_client_token=$GITLAB_OIDC_CLIENT_TOKEN
harbor_oidc_client_token=$HARBOR_OIDC_CLIENT_TOKEN
EOF
