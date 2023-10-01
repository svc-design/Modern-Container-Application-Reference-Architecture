#!/bin/bash
export namespace=$1

export MYSQL_ROOT_PASSWORD=$(kubectl get secret --namespace $namespace mysql -o jsonpath="{.data.mysql-root-password}" | base64 -d)

kubectl run mysql-client --rm --tty -i --restart='Never' --image  docker.io/bitnami/mysql:8.0.32-debian-11-r14 --namespace $namespace --env MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD --command -- bash -c "mysql -h mysql.database.svc.cluster.local -uroot -p$MYSQL_ROOT_PASSWORD -e 'create database IF NOT EXISTS jenkins;'"
