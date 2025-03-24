#!/bin/bash

terraform init -migrate-state
if [ "$STATE" == "create" ]; then
    terraform apply -auto-approve
elif [ "$STATE" == "destroy" ]; then
    terraform destroy -auto-approve
# Add handling for other states as needed
else
    echo "Invalid environment state"
    exit 1
fi
