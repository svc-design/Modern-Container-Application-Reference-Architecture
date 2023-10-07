#!/bin/bash


#!/bin/bash
set -x
export domain=$1
export Ali_Key=$2
export Ali_Secret=$3

curl https://get.acme.sh | sh -s email=156405189@qq.com

rm -rvf ${Domain}.* -f
rm -rvf /etc/ssl/${Domain}.* -f

# Try to issue a certificate from ZeroSSL. If it fails, try Let's Encrypt.
  
sh ~/.acme.sh/acme.sh --set-default-ca --server zerossl --issue --force --dns dns_ali -d ${domain} -d "*.${domain}"; 

if [[ ! -s "~/.acme.sh/${domain}_ecc/ca.cer" ]] || [[ ! -s "~/.acme.sh/${domain}_ecc/${domain}.cer" ]] || [[ ! -s "~/.acme.sh/${domain}_ecc/${domain}.key" ]]
; then
  echo "${domain}.pem and ${domain}.key is empty , Let's Try to issue a certificate with Let's Encrypt"
  sh ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt --issue --force --dns dns_ali -d ${domain} -d "*.${domain}"
else
  cat ~/.acme.sh/${domain}_ecc/${domain}.cer > ${domain}.pem
  cat ~/.acme.sh/${domain}_ecc/ca.cer >> ${domain}.pem
  cat ~/.acme.sh/${domain}_ecc/${domain}.key > ${domain}.key
  sudo cp ${domain}.pem /etc/ssl/ -f && sudo cp ${domain}.key /etc/ssl/ -f
fi

if [[ ! -s "~/.acme.sh/${domain}_ecc/ca.cer" ]] || [[ ! -s "~/.acme.sh/${domain}_ecc/${domain}.cer" ]] || [[ ! -s "~/.acme.sh/${domain}_ecc/${domain}.key" ]]; then
  echo "${domain}.pem and ${domain}.key must not be empty"
  exit 1
else
  cat ~/.acme.sh/${domain}_ecc/${domain}.cer > ${domain}.pem
  cat ~/.acme.sh/${domain}_ecc/ca.cer >> ${domain}.pem
  cat ~/.acme.sh/${domain}_ecc/${domain}.key > ${domain}.key
  sudo cp ${domain}.pem /etc/ssl/ -f && sudo cp ${domain}.key /etc/ssl/ -f
  sh ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt --issue --force --dns dns_ali -d ${domain} -d "*.${domain}"
fi
