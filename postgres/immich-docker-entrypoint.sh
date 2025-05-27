#!/usr/bin/env bash

set -eo pipefail

: "${DB_STORAGE_TYPE:=SSD}"

case "${DB_STORAGE_TYPE^^}" in
  SSD|HDD)
    echo "Using ${DB_STORAGE_TYPE^^} storage"
    cp -n --preserve=mode "/var/postgresql-conf-tpl/postgresql.${DB_STORAGE_TYPE,,}.conf" /etc/postgresql/postgresql.conf
    sed -i "s@##PGDATA@$PGDATA@" /etc/postgresql/postgresql.conf; \
    ;;
  *)
    echo "Error: DB_STORAGE_TYPE must be set to 'SSD' or 'HDD'" >&2
    exit 1
    ;;
esac

: "${POSTGRES_USER:=${DB_USERNAME}}"
: "${POSTGRES_PASSWORD:=${DB_PASSWORD}}"
: "${POSTGRES_DB:=${DB_DATABASE_NAME}}"

export POSTGRES_USER POSTGRES_PASSWORD POSTGRES_DB

exec /usr/local/bin/docker-entrypoint.sh "$@"
