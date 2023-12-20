#!/bin/bash

helm repo add bitnami https://charts.bitnami.com/bitnami || echo true
helm repo up
kubectl create ns database || echo true
helm upgrade --install mysql bitnami/mysql -n database
