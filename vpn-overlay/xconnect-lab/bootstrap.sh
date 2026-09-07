#!/usr/bin/env bash
set -euo pipefail

install -d -m 0755 /etc/xconnect-lab
printf '%s\n' '${role}' > /etc/xconnect-lab/node-role
printf '%s\n' '${run_id}' > /etc/xconnect-lab/lab-run
chmod 0644 /etc/xconnect-lab/node-role /etc/xconnect-lab/lab-run

if [[ '${role}' == 'relay' ]]; then
  cat > /etc/sysctl.d/99-xconnect-relay.conf <<'SYSCTL'
net.ipv4.ip_forward=1
net.ipv4.conf.all.src_valid_mark=1
SYSCTL
  sysctl --system >/dev/null
fi

touch /etc/xconnect-lab/bootstrap.ready
