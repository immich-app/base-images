#!/usr/bin/env bash
_log() {
  local level=$1 tag=${0##*/} line
  shift
  for line; do printf '[%s] %s:  %s\n' "${tag%.sh}" "$level" "$line"; done
}
log() { _log LOG "$@"; }
warn() { _log WARNING "$@" >&2; }
die() { _log FATAL "$@" >&2; exit 1; }
