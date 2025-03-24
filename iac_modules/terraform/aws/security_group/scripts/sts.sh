#!/bin/bash

iac_dir=$1

aws sts get-session-token > /tmp/tmp-token

cat > ${iac_dir}/tmp-env.sh << EOF
export AWS_ACCESS_KEY_ID=$(cat /tmp/tmp-token | jq '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(cat /tmp/tmp-token | jq '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(cat /tmp/tmp-token | jq '.Credentials.SessionToken')
EOF

chmod 755 ${iac_dir}/tmp-env.sh
