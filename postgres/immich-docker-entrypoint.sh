#!/usr/bin/env bash

set -eo pipefail

DATA_DIR="${PGDATA:-/var/lib/postgresql/data}"

if [ -d "$DATA_DIR" ]; then
  # 1. Disk Space Guard (Prevent crash loops on full disks)
  available_space=$(df -P "$DATA_DIR" | awk 'NR==2 {print $4}')
  if [ "$available_space" -lt 102400 ]; then
    echo "*****************************************************"
    echo "CRITICAL ERROR: Disk Space Exhaustion Detected"
    echo "Available space: $((available_space / 1024)) MB"
    echo "PostgreSQL requires at least 100MB to safely manage lock files and WAL."
    echo "Startup aborted to prevent crash loop and corruption."
    echo "*****************************************************"
    exit 1
  fi

  # 2. Filesystem Permission Warning (Detect non-POSIX mounts)
  fs_type=$(df -T "$DATA_DIR" | awk 'NR==2 {print $2}')
  if [[ "$fs_type" == "fuseblk" || "$fs_type" == "exfat" || "$fs_type" == "vfat" ]]; then
    echo "-----------------------------------------------------"
    echo "WARNING: Non-POSIX Filesystem Detected ($fs_type)"
    echo "PostgreSQL requires strict 0700 permissions on its data directory."
    echo "If this container fails to start with 'Permission denied',"
    echo "ensure you mounted the volume with 'uid=999,gid=999,fmask=0077,dmask=0077'."
    echo "-----------------------------------------------------"
  fi
fi

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
