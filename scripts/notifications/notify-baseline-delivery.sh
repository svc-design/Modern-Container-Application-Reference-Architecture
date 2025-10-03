#!/usr/bin/env bash
set -euo pipefail

run_url="https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
channels=${DELIVERY_CHANNELS:-"email,im,webhook"}
summary="Baseline rollout completed for multi-cloud landing zones."

printf 'Delivery Summary: %s\n' "$summary"
printf 'Notifying channels: %s\n' "$channels"
printf 'Workflow run: %s\n' "$run_url"
