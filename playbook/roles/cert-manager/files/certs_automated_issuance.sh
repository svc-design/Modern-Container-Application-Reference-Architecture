#!/bin/bash


#!/bin/bash
set -x
export Domain=$1
export Ali_Key=$2
export Ali_Secret=$3

# Non-empty check for Ali_Key and Ali_Secret
if [ -z "$Ali_Key" ] || [ -z "$Ali_Secret" ] || [ -z "$domain" ]; then
    echo "Domain, Ali_Key and Ali_Secret must not be empty"
    exit 1
fi

curl https://get.acme.sh | sh -s email=156405189@qq.com

rm -rvf ${Domain}.* -f
rm -rvf /etc/ssl/${Domain}.* -f

# Try to issue a certificate from ZeroSSL. If it fails, try Let's Encrypt.
if ! sh ~/.acme.sh/acme.sh --set-default-ca --server zerossl --issue --force --dns dns_ali -d ${Domain} -d "*.${Domain}"; 
then
    sh ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt --issue --force --dns dns_ali -d ${Domain} -d "*.${Domain}"
fi

cat ~/.acme.sh/${Domain}_ecc/${domain}.cer > ${Domain}.pem
cat ~/.acme.sh/${Domain}_ecc/ca.cer >> ${Domain}.pem
cat ~/.acme.sh/${Domain}_ecc/${Domain}.key > ${Domain}.key
sudo cp ${Domain}.pem /etc/ssl/
sudo cp ${Domain}.key /etc/ssl/

# Non-empty check for ${domain}.pem and ${Domain}.key
if [ ! -s "${Domain}.pem" ] || [ ! -s "${Domain}.key" ]; then
    echo "${Domain}.pem and ${Domain}.key must not be empty"
    exit 1
fi
