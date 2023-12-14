#!/usr/bin/env bash

set -e

: "${LIBRAW_REVISION:=$(jq -cr '.sources[] | select(.name == "libraw").revision' build-lock.json)}"

git clone https://github.com/libraw/libraw.git
cd libraw
git reset --hard $LIBVIPS_REVISION

autoreconf --install
./configure
make -j$(nproc)
make install
cd .. && rm -rf libraw
ldconfig /usr/local/lib
