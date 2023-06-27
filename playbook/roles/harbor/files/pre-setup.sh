#!/bin/bash
export namespace=$1
export POSTGRES_PASSWORD=$(kubectl get secret --namespace database postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)

kubectl run postgresql-client --rm --tty -i --restart='Never' --namespace database --image docker.io/bitnami/postgresql:15.2.0-debian-11-r11 --env="PGPASSWORD=$POSTGRES_PASSWORD" --command -- psql --host postgresql -U postgres -d postgres -p 5432 -w -c "CREATE DATABASE registry;" || echo true

kubectl run postgresql-client --rm --tty -i --restart='Never' --namespace database --image docker.io/bitnami/postgresql:15.2.0-debian-11-r11 --env="PGPASSWORD=$POSTGRES_PASSWORD" --command -- psql --host postgresql -U postgres -d postgres -p 5432 -w -c "CREATE DATABASE harbor_core; CREATE DATABASE harbor_clair; CREATE DATABASE harbor_notary_server; CREATE DATABASE harbor_notary_signer;" || echo true
