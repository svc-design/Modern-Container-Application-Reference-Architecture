#!/bin/bash


#!/bin/bash
set -x
export Domain=$1
export Ali_Key=$2
export Ali_Secret=$3

curl https://get.acme.sh | sh -s email=156405189@qq.com

rm -rvf ${Domain}.* -f
rm -rvf /etc/ssl/${Domain}.* -f

# Try to issue a certificate from ZeroSSL. If it fails, try Let's Encrypt.
  
sh ~/.acme.sh/acme.sh --set-default-ca --server zerossl --issue --force --dns dns_ali -d ${Domain} -d "*.${Domain}"; 

if [[ ! -s "~/.acme.sh/${Domain}_ecc/ca.cer" ]] || [[ ! -s "~/.acme.sh/${Domain}_ecc/${domain}.cer" ]] || [[ ! -s "~/.acme.sh/${Domain}_ecc/${domain}.key" ]]
; then
  echo "${Domain}.pem and ${Domain}.key is empty , Let's Try to issue a certificate with Let's Encrypt"
  sh ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt --issue --force --dns dns_ali -d ${Domain} -d "*.${Domain}"
else
  cat ~/.acme.sh/${Domain}_ecc/${domain}.cer > ${Domain}.pem
  cat ~/.acme.sh/${Domain}_ecc/ca.cer >> ${Domain}.pem
  cat ~/.acme.sh/${Domain}_ecc/${Domain}.key > ${Domain}.key
  sudo cp ${Domain}.pem /etc/ssl/ -f && sudo cp ${Domain}.key /etc/ssl/ -f
fi

if [[ ! -s "~/.acme.sh/${Domain}_ecc/ca.cer" ]] || [[ ! -s "~/.acme.sh/${Domain}_ecc/${domain}.cer" ]] || [[ ! -s "~/.acme.sh/${Domain}_ecc/${domain}.key" ]]; then
  echo "${Domain}.pem and ${Domain}.key must not be empty"
  exit 1
else
  cat ~/.acme.sh/${Domain}_ecc/${domain}.cer > ${Domain}.pem
  cat ~/.acme.sh/${Domain}_ecc/ca.cer >> ${Domain}.pem
  cat ~/.acme.sh/${Domain}_ecc/${Domain}.key > ${Domain}.key
  sudo cp ${Domain}.pem /etc/ssl/ -f && sudo cp ${Domain}.key /etc/ssl/ -f
  sh ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt --issue --force --dns dns_ali -d ${Domain} -d "*.${Domain}"
fi
