#!/usr/bin/env bash

set -eo pipefail

# shellcheck source=postgres/log.sh
. /usr/local/bin/log.sh

ROOT="$PGDATA"

fsdir="$ROOT"
until [[ -d "$fsdir" ]]; do fsdir=$(dirname "$fsdir"); done
fstype=$(stat -f -c %T "$fsdir")

case "$fstype" in
  ext2/ext3|ext4|xfs|btrfs|zfs|f2fs|tmpfs) ;;
  *)
    if [[ "${IGNORE_DATABASE_FSTYPE,,}" != "true" ]]; then
      die "PGDATA is on '$fstype', which is not safe for a PostgreSQL database." \
        "Network shares (NFS/SMB), Windows drives, and VM shared folders will corrupt your data." \
        "Point PGDATA at local Linux storage or use a named container volume." \
        "To bypass at your own risk, set IGNORE_DATABASE_FSTYPE=true."
    fi
    warn "proceeding on unsafe filesystem '$fstype'"
    ;;
esac

# only the -upgrade image ships this; as in upstream's entrypoint, only the server command runs it
if [[ "${1:-}" == postgres && -x /usr/local/bin/major-upgrade.sh ]]; then
  /usr/local/bin/major-upgrade.sh
fi

# a cluster a stock postgres image left, or one at $ROOT, keeps running in place; otherwise $ROOT/$PG_MAJOR
stock=(/var/lib/postgresql/*/docker/PG_VERSION)
if [[ -s "${stock[0]}" ]]; then
  export PGDATA="${stock[0]%/PG_VERSION}"
elif [[ -f "$ROOT/$PG_MAJOR/PG_VERSION" || ! -f "$ROOT/PG_VERSION" ]]; then
  export PGDATA="$ROOT/$PG_MAJOR"
fi

# upstream would initdb the new, empty $PGDATA even next to existing data
if [[ "${1:-}" == postgres && ! -s "$PGDATA/PG_VERSION" ]]; then
  leftovers="$(find "$ROOT" -mindepth 1 -maxdepth 1 ! -name lost+found ! -name "$PG_MAJOR" -printf ' %f' 2>/dev/null || true)"
  if [[ -n "$leftovers" ]]; then
    message=("$ROOT holds no PostgreSQL $PG_MAJOR cluster, but it is not empty:$leftovers"
      "A new cluster is only created in an empty location. If this is the wrong location, fix the volume mapping.")
    if [[ -x /usr/local/bin/major-upgrade.sh ]]; then message+=("If one of these is an older cluster to upgrade, set PGDATAOLD to its path."); fi
    die "${message[@]}"
  fi
fi

: "${DB_STORAGE_TYPE:=SSD}"

case "${DB_STORAGE_TYPE^^}" in
  SSD|HDD)
    log "Using ${DB_STORAGE_TYPE^^} storage"
    cp -n --preserve=mode "/var/postgresql-conf-tpl/postgresql.${DB_STORAGE_TYPE,,}.conf" /etc/postgresql/postgresql.conf
    sed -i "s@##PGDATA@$PGDATA@" /etc/postgresql/postgresql.conf; \
    ;;
  *)
    die "DB_STORAGE_TYPE must be set to 'SSD' or 'HDD'"
    ;;
esac

# shellcheck source=postgres/set-env.sh
. /usr/local/bin/set-env.sh

exec /usr/local/bin/docker-entrypoint.sh "$@"
