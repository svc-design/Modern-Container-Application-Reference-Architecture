#!/bin/bash

export secret=$1
export key_file=$2
export cert_file=$3
export namespace=$4

kubectl create namespace $namespace || echo true
kubectl delete secret tls $secret -n $namespace || echo true
kubectl create secret tls $secret --cert=$cert_file --key=$key_file -n $namespace
