#!/bin/bash

helm repo add kedacore https://kedacore.github.io/charts
helm repo update
kubectl create namespace kube-system || true
helm upgrade --install keda kedacore/keda --namespace kube-system
