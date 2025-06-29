#!/usr/bin/env bash

set -e

: "${LIBHEIF_REVISION:=$(jq -cr '.revision' libheif.json)}"

git clone https://github.com/strukturag/libheif.git
cd libheif
git reset --hard "$LIBHEIF_REVISION"

mkdir build
cd build
cmake --preset=release-noplugins \
    -DWITH_DAV1D=ON \
    -DENABLE_PARALLEL_TILE_DECODING=ON \
    -DWITH_LIBSHARPYUV=ON \
    -DWITH_LIBDE265=ON \
    -DWITH_AOM_DECODER=OFF \
    -DWITH_AOM_ENCODER=ON \
    -DWITH_X265=OFF \
    -DWITH_EXAMPLES=OFF \
    ..
make -j$(nproc) install
cd ../.. && rm -rf libheif
ldconfig /usr/local/lib
