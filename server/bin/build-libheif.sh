#!/usr/bin/env bash

set -e

: "${LIBHEIF_REVISION:=$(jq -cr '.sources[] | select(.name == "libheif").revision' build-lock.json)}"

git clone https://github.com/strukturag/libheif.git
cd libheif
git reset --hard "$LIBHEIF_REVISION"

mkdir build
cd build
cmake --preset=release-noplugins \
    -DWITH_DAV1D=ON \
    -DENABLE_PARALLEL_TILE_DECODING=ON \
    -DENABLE_LIBSHARPYUV=ON \
    -DENABLE_LIBDE265=ON \
    -DWITH_AOM_DECODER=OFF \
    -DWITH_AOM_ENCODER=OFF \
    -DWITH_X265=OFF \
    -DWITH_EXAMPLES=OFF \
    -DLIBJPEG_TURBO_VERSION_NUMBER=0 \
    ..
make install
cd ../.. && rm -rf libheif
ldconfig /usr/local/lib
