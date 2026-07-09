#!/usr/bin/env bash

set -eo pipefail

fsdir="$PGDATA"
until [[ -d "$fsdir" ]]; do fsdir=$(dirname "$fsdir"); done
fstype=$(stat -f -c %T "$fsdir")

case "$fstype" in
  ext2/ext3|ext4|xfs|btrfs|zfs|f2fs|tmpfs) ;;
  *)
    if [[ "${IGNORE_DATABASE_FSTYPE,,}" != "true" ]]; then
      cat >&2 <<EOF
ERROR: PGDATA is on '$fstype', which is not safe for a PostgreSQL database.
Network shares (NFS/SMB), Windows drives, and VM shared folders will corrupt your data.
Point PGDATA at local Linux storage or use a named container volume.
To bypass at your own risk, set IGNORE_DATABASE_FSTYPE=true.
EOF
      exit 1
    fi
    echo "WARNING: proceeding on unsafe filesystem '$fstype'" >&2
    ;;
esac

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

# shellcheck source=postgres/set-env.sh
. /usr/local/bin/set-env.sh

exec /usr/local/bin/docker-entrypoint.sh "$@"
