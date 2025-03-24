#!/bin/bash

export config=$1 
# Get the directory of the script
script_dir="$(dirname "$(readlink -f "$0")")"

# Read config.yaml and set environment variables
project_id=$(yq eval '.project_id' "$script_dir/../../envs/${config}")
key_pairs_name=$(yq eval '.key_pairs[0].name' "$script_dir/../../envs/${config}")

if [ -z "$project_id" ]; then
  echo "Error: Project ID not set in config.yaml"
  exit 1
fi

if [ -z "$key_pairs_name" ]; then
  echo "Error: Key pairs name not set in config.yaml"
  exit 1
fi

# Check SSH Metadata
SSH_METADATA_EXISTS=$(gcloud compute project-info describe --project=${project_id} --format="value(commonInstanceMetadata.items['${key_pairs_name}'])")

if [ -n "$SSH_METADATA_EXISTS" ]; then
   echo "::set-output name=ssh_metadata_exists::true"
else
   echo "::set-output name=ssh_metadata_exists::false"
fi
