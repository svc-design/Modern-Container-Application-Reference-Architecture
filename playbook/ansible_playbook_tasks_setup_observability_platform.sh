#!/bin/bash

# Function to check if a variable is empty
check_empty() {
    if [ -z "${!1}" ]; then
        echo "$1 is empty. Aborting."
        exit 1
    fi
}

# List of variables to check
variables=("DOMAIN")

# Loop through variables and check if each one is empty
for var in "${variables[@]}"; do
    check_empty "$var"
done

cat > init_observability-server << EOF
- name: setup observability server
  hosts: all
  user: root
  become: yes
  gather_facts: yes
  tasks:
    - include_role:
        name: observability-server
      vars:
        group: master
        update_secret: true
        auto_issuance: false
        namespace: monitoring
        db_namespace: database
        tls:
          - secret_name: obs-tls
            keyfile: /etc/ssl/${DOMAIN}.key
            certfile: /etc/ssl/${DOMAIN}.pem
    - include_role:
        name: flagger-loadtester
      vars:
        group: master
        update_secret: true
        auto_issuance: false
        namespace: loadtester
        tls:
          - secret_name: obs-tls
            keyfile: /etc/ssl/${DOMAIN}.key
            certfile: /etc/ssl/${DOMAIN}.pem
EOF
