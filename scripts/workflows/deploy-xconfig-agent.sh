#!/usr/bin/env bash
set -euo pipefail

: "${GITOPS_REPO:?GITOPS_REPO is required}"
: "${GITOPS_BRANCH:?GITOPS_BRANCH is required}"
: "${GITOPS_PLAYBOOK:?GitOps playbook path is required for vhosts matrix entry}"

ANSIBLE_HOST_KEY_CHECKING=${ANSIBLE_HOST_KEY_CHECKING:-False}
export ANSIBLE_HOST_KEY_CHECKING

ansible-playbook -i inventory.ini install-xconfig-agent.yml \
  --extra-vars "gitops_repo=${GITOPS_REPO} gitops_branch=${GITOPS_BRANCH} gitops_playbook=${GITOPS_PLAYBOOK}"
