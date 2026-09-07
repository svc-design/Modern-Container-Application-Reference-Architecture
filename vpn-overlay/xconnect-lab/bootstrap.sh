#!/usr/bin/env bash
set -euo pipefail

install -d -m 0755 /etc/xconnect-lab
printf '%s\n' '${role}' > /etc/xconnect-lab/node-role
printf '%s\n' '${run_id}' > /etc/xconnect-lab/lab-run
chmod 0644 /etc/xconnect-lab/node-role /etc/xconnect-lab/lab-run

# Scope the generated SSH credential to this instance instead of creating a
# persistent EC2 key-pair resource in the reused UAT account.
install -d -o ubuntu -g ubuntu -m 0700 /home/ubuntu/.ssh
printf '%s\n' '${ssh_public_key}' > /home/ubuntu/.ssh/authorized_keys
chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys
chmod 0600 /home/ubuntu/.ssh/authorized_keys

if [[ '${role}' == 'relay' ]]; then
  cat > /etc/sysctl.d/99-xconnect-relay.conf <<'SYSCTL'
net.ipv4.ip_forward=1
net.ipv4.conf.all.src_valid_mark=1
SYSCTL
  sysctl --system >/dev/null
fi

touch /etc/xconnect-lab/bootstrap.ready
