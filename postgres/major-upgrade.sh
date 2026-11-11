#!/usr/bin/env bash
# Upgrades the cluster in $PGDATAOLD (default $PGDATA) to this image's major, in $PGDATA/<major>.
# It keeps no state files: every run reads the volume and converges on the same end state.
set -euo pipefail

readonly VOLUME="${PGDATA:?}"
readonly NEW_MAJOR="${PG_MAJOR:?}"
readonly NEW_CLUSTER="$VOLUME/$NEW_MAJOR"
readonly OLD_CLUSTER="${PGDATAOLD:-$VOLUME}"
# shellcheck disable=SC2155
readonly OLD_MAJOR="$(cat "$OLD_CLUSTER/PG_VERSION" 2>/dev/null || true)" # empty: no cluster there
readonly STAGED_CLUSTER="$NEW_CLUSTER.tmp"
readonly OLD_CLUSTER_BACKUP="$VOLUME/$OLD_MAJOR.bak"
readonly OLD_BIN="/usr/lib/postgresql/$OLD_MAJOR/bin"
readonly NEW_BIN="/usr/lib/postgresql/$NEW_MAJOR/bin"
readonly WORK=/tmp/major-upgrade # sockets and logs
readonly CONFIG_FILES=(postgresql.conf postgresql.auto.conf postgresql.override.conf pg_hba.conf pg_ident.conf)
readonly ROOT_CLUSTER_ENTRIES=(base global pg_commit_ts pg_dynshmem pg_logical pg_multixact
  pg_notify pg_replslot pg_serial pg_snapshots pg_stat pg_stat_tmp
  pg_subtrans pg_tblspc pg_twophase pg_wal pg_xact "${CONFIG_FILES[@]}"
  postmaster.opts postmaster.pid current_logfiles log pg_log
  backup_label.old tablespace_map.old
  pg_vectors pgsql_tmp_vchord_sampling) # the last two belong to pgvecto.rs and vchord

main() {
  if [[ -z $OLD_MAJOR || $OLD_MAJOR == "$NEW_MAJOR" ]]; then return; fi

  resolve_credentials # while still root: secret files may be readable by root only
  if [[ $(id -u) == 0 ]]; then
    # postgres creates and renames clusters in these folders; upstream's entrypoint leaves them to root
    mkdir -p "$VOLUME"
    chown postgres "$VOLUME"
    if ! old_cluster_is_volume_root; then chown postgres "$(dirname "$OLD_CLUSTER")"; fi
    exec gosu postgres "$0" "$@" # postgres's tools refuse to run as root
  fi

  if [[ -f $NEW_CLUSTER/PG_VERSION ]]; then
    log "completing the move of the old cluster"
    archive_old_cluster
    return
  fi

  [[ -x $OLD_BIN/postgres ]] || die "this image cannot upgrade PostgreSQL $OLD_MAJOR"
  [[ -z $(ls -A "$OLD_CLUSTER_BACKUP" 2>/dev/null) ]] ||
    die "$OLD_CLUSTER_BACKUP already holds the backup of an earlier upgrade: move it elsewhere or delete it, then start this image again"

  log "upgrading PostgreSQL $OLD_MAJOR -> $NEW_MAJOR; the old cluster is kept as $OLD_CLUSTER_BACKUP"
  rm -rf "$STAGED_CLUSTER" "$WORK" # left by an interrupted attempt
  rm -f "$OLD_CLUSTER/postmaster.pid" # left behind when this container was killed
  mkdir "$WORK"
  if ! getent passwd "$(id -u)" >/dev/null; then fake_passwd_entry; fi # a rootless container may run as any uid
  init_staged_cluster
  drop_vchord_from_old_cluster
  transfer_with_pg_upgrade
  copy_config_files # after the transfer: the old pg_hba.conf could lock pg_upgrade out of the new cluster
  log "committing the new cluster"
  mv -T "$STAGED_CLUSTER" "$NEW_CLUSTER"
  archive_old_cluster
  log "major upgrade $OLD_MAJOR -> $NEW_MAJOR complete; PostgreSQL $NEW_MAJOR will start from $NEW_CLUSTER"
}

# shellcheck source=postgres/set-env.sh
resolve_credentials() {
  set +u; . /usr/local/bin/set-env.sh; set -u
  unset DB_USERNAME_FILE DB_PASSWORD_FILE DB_DATABASE_NAME_FILE
  : "${POSTGRES_USER:=postgres}" "${POSTGRES_DB:=$POSTGRES_USER}"
  export POSTGRES_USER POSTGRES_DB PGPASSWORD="${POSTGRES_PASSWORD:-}"
}

old_cluster_is_volume_root() { [[ $OLD_CLUSTER -ef $VOLUME ]]; }

fake_passwd_entry() { # initdb refuses to run without one
  local nss=(/usr/lib/*/libnss_wrapper.so)
  printf 'postgres:x:%s:%s::%s:/bin/false\n' "$(id -u)" "$(id -g)" "$VOLUME" >"$WORK/passwd"
  printf 'postgres:x:%s:\n' "$(id -g)" >"$WORK/group"
  export LD_PRELOAD="${nss[0]}" NSS_WRAPPER_PASSWD="$WORK/passwd" NSS_WRAPPER_GROUP="$WORK/group"
}

init_staged_cluster() {
  log "initializing the new cluster"
  local control checksums=--data-checksums # pg_upgrade requires them to match the old cluster's
  control="$(LC_ALL=C "$OLD_BIN/pg_controldata" "$OLD_CLUSTER")"
  if grep -q '^Data page checksum version: *0$' <<<"$control"; then checksums=--no-data-checksums; fi
  "$NEW_BIN/initdb" --no-sync -D "$STAGED_CLUSTER" -U "$POSTGRES_USER" -A trust "$checksums" >/dev/null # pg_upgrade syncs
}

drop_vchord_from_old_cluster() { # pg_upgrade cannot transfer it across vchord versions
  log "dropping the vchord extension (its indexes cascade; immich rebuilds them when its server next starts)"
  local dropped=
  "$OLD_BIN/pg_ctl" -D "$OLD_CLUSTER" -w -l "$WORK/old.log" \
    -o "-k $WORK -c listen_addresses= -c shared_preload_libraries=vchord.so" start >/dev/null ||
    { cat "$WORK/old.log"; die "the old cluster failed to start"; }
  if "$NEW_BIN/psql" -X -q -h "$WORK" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "DROP EXTENSION IF EXISTS vchord CASCADE"; then dropped=1; fi
  "$OLD_BIN/pg_ctl" -D "$OLD_CLUSTER" -m fast -w stop >/dev/null # also when the drop failed
  [[ -n $dropped ]] || die "could not drop vchord from the old cluster"
}

transfer_with_pg_upgrade() {
  log "transferring $OLD_MAJOR -> $NEW_MAJOR with pg_upgrade --copy-file-range"
  (cd "$WORK" && PGUSER="$POSTGRES_USER" "$NEW_BIN/pg_upgrade" --copy-file-range \
    --old-bindir="$OLD_BIN" --new-bindir="$NEW_BIN" \
    --old-datadir="$OLD_CLUSTER" --new-datadir="$STAGED_CLUSTER" \
    --socketdir="$WORK" >"$WORK/pg_upgrade.log" 2>&1) || {
    cat "$WORK/pg_upgrade.log"
    find "$STAGED_CLUSTER/pg_upgrade_output.d" -type f \( -name '*.log' -o -name '*.txt' \) -exec tail -n 20 -v {} + || true
    rm -rf "$STAGED_CLUSTER"
    die "pg_upgrade failed; the next start of this image retries from scratch"
  }
}

copy_config_files() {
  local file
  for file in "${CONFIG_FILES[@]}"; do
    if [[ -f $OLD_CLUSTER/$file ]]; then cp "$OLD_CLUSTER/$file" "$STAGED_CLUSTER/"; fi
  done
}

archive_old_cluster() {
  local entry restore="rename $OLD_CLUSTER_BACKUP back to $OLD_CLUSTER"
  if ! old_cluster_is_volume_root; then
    mv -T "$OLD_CLUSTER" "$OLD_CLUSTER_BACKUP"
  else # the volume root cannot be renamed; PG_VERSION goes last, marking the move unfinished until then
    restore="move the contents of $OLD_CLUSTER_BACKUP back into $VOLUME"
    [[ -d $OLD_CLUSTER_BACKUP ]] || mkdir -m 700 "$OLD_CLUSTER_BACKUP"
    for entry in "${ROOT_CLUSTER_ENTRIES[@]}" PG_VERSION; do
      [[ -e $VOLUME/$entry || -L $VOLUME/$entry ]] || continue
      mv -T "$VOLUME/$entry" "$OLD_CLUSTER_BACKUP/$entry"
    done
  fi
  log "the old cluster is in $OLD_CLUSTER_BACKUP: delete that folder once everything looks good. To roll back, delete $NEW_CLUSTER, $restore and switch to the previous image"
}

log() { echo "[major-upgrade] $*"; }
die() { echo "[major-upgrade] ERROR: $*" >&2; exit 1; }

main "$@"
