#!/bin/bash
set -x

helm repo add flagger https://flagger.app
kubectl create ns loadtester || true
helm upgrade -i flagger-loadtester flagger/loadtester --namespace=loadtester

