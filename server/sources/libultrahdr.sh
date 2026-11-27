#!/usr/bin/env bash

set -e

: "${LIBULTRAHDR_REVISION:=$(jq -cr '.revision' libultrahdr.json)}"

git clone https://github.com/google/libultrahdr.git
cd libultrahdr
git reset --hard "$LIBULTRAHDR_REVISION"

mkdir build
cd build
cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DUHDR_BUILD_EXAMPLES=OFF \
  -DUHDR_BUILD_TESTS=OFF \
  -DUHDR_BUILD_BENCHMARK=OFF \
  -DUHDR_BUILD_FUZZERS=OFF \
  -DUHDR_BUILD_JAVA=OFF \
  -DUHDR_ENABLE_HEIF=OFF \
  ..
echo "Building libultrahdr using $(nproc) threads"
cmake --build . -- -j"$(nproc)"
cmake --install .
rm /usr/local/lib/libuhdr.a
cd ../.. && rm -rf libultrahdr
ldconfig /usr/local/lib
