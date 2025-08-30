#!/usr/bin/env bash

set -e

export TARGETARCH=${TARGETARCH:=$(dpkg --print-architecture)}
export DEBIAN_RELEASE=${DEBIAN_RELEASE:=trixie}
: "${FFMPEG_VERSION:=$(jq -cr '.version' ffmpeg.json)}"
: "${FFMPEG_SHA256:=$(jq -cr '.sha256[$ENV.TARGETARCH]' ffmpeg.json)}"
echo "$FFMPEG_SHA256  jellyfin-ffmpeg7_${FFMPEG_VERSION}-${DEBIAN_RELEASE}_${TARGETARCH}.deb" > ffmpeg.sha256

wget -nv "https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v${FFMPEG_VERSION}/jellyfin-ffmpeg7_${FFMPEG_VERSION}-${DEBIAN_RELEASE}_${TARGETARCH}.deb"
sha256sum -c ffmpeg.sha256
apt-get -yqq -f install "./jellyfin-ffmpeg7_${FFMPEG_VERSION}-${DEBIAN_RELEASE}_${TARGETARCH}.deb"
rm "jellyfin-ffmpeg7_${FFMPEG_VERSION}-${DEBIAN_RELEASE}_${TARGETARCH}.deb"
rm ffmpeg.sha256
ldconfig /usr/lib/jellyfin-ffmpeg/lib

ln -s /usr/lib/jellyfin-ffmpeg/ffmpeg /usr/bin
ln -s /usr/lib/jellyfin-ffmpeg/ffprobe /usr/bin
