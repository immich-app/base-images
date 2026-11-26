#!/usr/bin/env bash

set -e

: "${LIBVIPS_REVISION:=$(jq -cr '.revision' libvips.json)}"

git clone https://github.com/libvips/libvips.git
cd libvips
git reset --hard "$LIBVIPS_REVISION"

meson setup build --buildtype=release --libdir=lib -Dintrospection=disabled -Dtiff=disabled
cd build
ninja install
cd .. && rm -rf libvips
ldconfig /usr/local/lib
