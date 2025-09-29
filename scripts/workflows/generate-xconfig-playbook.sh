#!/usr/bin/env bash
set -euo pipefail

: "${GITOPS_PLAYBOOK:?GitOps playbook path is required for vhosts matrix entry}"

cat <<'PLAYBOOK' > install-xconfig-agent.yml
- hosts: all
  become: yes
  tasks:
    - name: Ensure build dependencies are installed
      ansible.builtin.apt:
        name:
          - build-essential
          - curl
          - git
          - pkg-config
          - libssl-dev
        state: present
        update_cache: true

    - name: Install Rust toolchain when missing
      ansible.builtin.shell: |
        set -euo pipefail
        if ! command -v rustup >/dev/null 2>&1; then
          curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        fi
      args:
        creates: "{{ ansible_env.HOME }}/.cargo/bin/rustup"

    - name: Build cw-agent binary
      # noqa command-instead-of-shell
      ansible.builtin.shell: |
        set -euo pipefail
        work_dir=$(mktemp -d)
        trap 'rm -rf "${work_dir}"' EXIT
        git clone --depth 1 https://github.com/svc-design/XConfig "${work_dir}/XConfig"
        cd "${work_dir}/XConfig/CraftWeaveAgent"
        . "{{ ansible_env.HOME }}/.cargo/env"
        cargo build --release
        install -D -m 0755 target/release/cw-agent /usr/local/bin/cw-agent
      args:
        creates: /usr/local/bin/cw-agent

    - name: Ensure agent working directories exist
      ansible.builtin.file:
        path: "{{ item }}"
        state: directory
        owner: root
        group: root
        mode: '0755'
      loop:
        - /etc
        - /var/lib/cw-agent

    - name: Configure cw-agent
      ansible.builtin.copy:
        dest: /etc/cw-agent.conf
        owner: root
        group: root
        mode: '0644'
        content: |
          repo: "{{ gitops_repo }}"
          branch: {{ gitops_branch }}
          interval: 60
          playbook:
            - {{ gitops_playbook }}

    - name: Install cw-agent systemd service
      ansible.builtin.copy:
        dest: /etc/systemd/system/cw-agent.service
        owner: root
        group: root
        mode: '0644'
        content: |
          [Unit]
          Description=Xconfig Agent Service
          After=network-online.target
          Wants=network-online.target

          [Service]
          Type=simple
          ExecStart=/usr/local/bin/cw-agent daemon --config /etc/cw-agent.conf
          Restart=on-failure
          RestartSec=5
          User=root
          Environment=RUST_LOG=info
          WorkingDirectory=/var/lib/cw-agent

          [Install]
          WantedBy=multi-user.target

    - name: Reload systemd manager configuration
      ansible.builtin.systemd:
        daemon_reload: true

    - name: Enable and restart cw-agent
      ansible.builtin.systemd:
        name: cw-agent.service
        enabled: true
        state: restarted
PLAYBOOK
