#!/usr/bin/env bash

# shellcheck source=postgres/set-env.sh
. /usr/local/bin/set-env.sh

pg_isready --dbname="${POSTGRES_DB}" --username="${POSTGRES_USER}" || exit $?;

CHKSUM_ERROR_COUNT="$(psql --dbname="${POSTGRES_DB}" --username="${POSTGRES_USER}" --tuples-only --no-align --command='SELECT COALESCE(SUM(checksum_failures), 0) FROM pg_stat_database')";

if [ "$CHKSUM_ERROR_COUNT" != '0' ]; then
  echo "checksum failure count is $CHKSUM_ERROR_COUNT";
  exit 1
fi
