#!/bin/bash

export server_public_key=$1
export server_ip=$2
export client_name=$3
export client_ip=$4

sudo rm -rvf /etc/wireguard/keys/$client_name
sudo mkdir -pv /etc/wireguard/keys/$client_name
cd  /etc/wireguard/keys/$client_name
wg genkey > ${client_name}.key
wg pubkey < ${client_name}.key > ${client_name}.pub

CLIENT_KEY=`cat ${client_name}.key`
CLIENT_PUBLIC_KEY=`cat ${client_name}.pub`

cat > ${client_name}-wg0.conf << EOF
[Interface]
PrivateKey = ${CLIENT_KEY}
ListenPort = 54321
Address = ${client_ip}/24
DNS = 114.114.114.114
MTU = 1420
EOF


# brew install wireguard-tools && sudo wg-quick up wg0
# apt install qrencode --assume-yes qrencode --read-from=client-wg0.conf --type=UTF8

cat >> /etc/wireguard/wg0.conf << EOF
[Peer]
   # ${client_name}
   PublicKey = ${CLIENT_PUBLIC_KEY}
   AllowedIPs = ${client_ip}/32
EOF
