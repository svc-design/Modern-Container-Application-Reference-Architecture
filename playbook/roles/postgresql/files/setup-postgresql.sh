#!/bin/bash

export namespace=$1

helm repo add bitnami https://charts.bitnami.com/bitnami || echo true
helm repo up
kubectl create ns $namespace || echo true
helm upgrade --install postgresql bitnami/postgresql --version 12.2.3 -n $namespace
