#!/bin/bash
set +x

export namespace=$1
export POSTGRES_PASSWORD=$(kubectl get secret --namespace $namespace postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)

kubectl run postgresql-client --rm --tty -i --restart='Never' --namespace $namespace --image docker.io/bitnami/postgresql:15.2.0-debian-11-r11 --env="PGPASSWORD=$POSTGRES_PASSWORD" --command -- psql --host postgresql -U postgres -d postgres -p 5432 -w -c "CREATE DATABASE gitlabhq_production OWNER postgres;" || echo true

kubectl run postgresql-client --rm --tty -i --restart='Never' --namespace $namespace --image docker.io/bitnami/postgresql:15.2.0-debian-11-r11 --env="PGPASSWORD=$POSTGRES_PASSWORD" --command -- psql --host postgresql -U postgres -d gitlabhq_production -p 5432 -w -c "CREATE EXTENSION IF NOT EXISTS plpgsql; CREATE EXTENSION IF NOT EXISTS pg_trgm; CREATE EXTENSION IF NOT EXISTS btree_gist;" || echo true
