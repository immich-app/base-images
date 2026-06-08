#!/usr/bin/env bash

set -e

export TARGETARCH=${TARGETARCH:=$(dpkg --print-architecture)}
: "${RESTIC_REVISION:=$(jq -cr '.revision' restic.json)}"
: "${GO_VERSION:=$(jq -cr '.go.version' restic.json)}"
: "${GO_SHA256:=$(jq -cr '.go.sha256[$ENV.TARGETARCH]' restic.json)}"

GO_TARBALL="go${GO_VERSION}.linux-${TARGETARCH}.tar.gz"
wget -nv "https://go.dev/dl/${GO_TARBALL}"
echo "${GO_SHA256}  ${GO_TARBALL}" | sha256sum -c -
tar -C /usr/local -xzf "${GO_TARBALL}"
rm "${GO_TARBALL}"
export PATH="/usr/local/go/bin:${PATH}"
export GOTOOLCHAIN=local CGO_ENABLED=0

git clone https://github.com/restic/restic.git
cd restic
git reset --hard "$RESTIC_REVISION"

go run build.go
install -m 0755 restic /usr/local/bin/restic

restic version
