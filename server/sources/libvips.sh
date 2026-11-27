#!/usr/bin/env bash

set -e

: "${LIBVIPS_REVISION:=$(jq -cr '.revision' libvips.json)}"

git clone https://github.com/libvips/libvips.git
cd libvips
git reset --hard "$LIBVIPS_REVISION"
git apply -3 ../libvips-patches/libvips-uhdr2scrgb-gamut.patch # https://github.com/libvips/libvips/pull/5350
git apply -3 ../libvips-patches/libvips-uhdrsave-gainmap-keep.patch # https://github.com/libvips/libvips/pull/5351
git apply -3 ../libvips-patches/libvips-uhdrload-base-options.patch # https://github.com/libvips/libvips/pull/5354
git apply -3 ../libvips-patches/libvips-dcrawload-preview-unpack.patch # https://github.com/libvips/libvips/pull/5352

meson setup build --buildtype=release --libdir=lib -Dintrospection=disabled -Dtiff=disabled
cd build
ninja install
cd .. && rm -rf libvips
ldconfig /usr/local/lib
