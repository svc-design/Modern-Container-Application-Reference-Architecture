#!/bin/bash


#!/bin/bash
set -x
export domain=$1
export Ali_Key=$2
export Ali_Secret=$3

rm -rvf ${Domain}.* -f
rm -rvf /etc/ssl/${Domain}.* -f

# Try to issue a certificate from ZeroSSL. If it fails, try Let's Encrypt.
  
curl https://get.acme.sh | sh -s email=156405189@qq.com
sh ~/.acme.sh/acme.sh --set-default-ca --server zerossl --issue --force --dns dns_ali -d ${domain} -d "*.${domain}"; 
if [ $? -eq 0 ]; then
    echo "Certificate from zerossl successfully issued"
else
  sh ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt --issue --force --dns dns_ali -d ${domain} -d "*.${domain}"
  if [ $? -eq 0 ]; then
      echo "Certificate from letsencrypt successfully issued"
  else
      echo "Command failed"
      exit 1
  fi   
fi

cat ~/.acme.sh/${domain}_ecc/${domain}.cer > ${domain}.pem
cat ~/.acme.sh/${domain}_ecc/ca.cer >> ${domain}.pem
cat ~/.acme.sh/${domain}_ecc/${domain}.key > ${domain}.key
sudo cp ${domain}.pem /etc/ssl/ -f && sudo cp ${domain}.key /etc/ssl/ -f
