#!/usr/bin/env bash

set -e

: "${RESTIC_REVISION:=$(jq -cr '.revision' restic.json)}"

git clone https://github.com/restic/restic.git
cd restic
git reset --hard "$RESTIC_REVISION"

go run build.go
install -m 0755 restic /usr/local/bin/restic

restic version
