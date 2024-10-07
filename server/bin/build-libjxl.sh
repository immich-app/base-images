#!/usr/bin/env bash

set -e

: "${LIBJXL_REVISION:=$(jq -cr '.sources[] | select(.name == "libjxl").revision' build-lock.json)}"

git clone https://github.com/libjxl/libjxl.git
cd libjxl
git reset --hard $LIBJXL_REVISION
git submodule update --init --recursive --depth 1 --recommend-shallow

mkdir build
cd build
cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_TESTING=OFF \
  -DJPEGXL_ENABLE_DOXYGEN=OFF \
  -DJPEGXL_ENABLE_MANPAGES=OFF \
  -DJPEGXL_ENABLE_PLUGIN_GIMP210=OFF \
  -DJPEGXL_ENABLE_BENCHMARK=OFF \
  -DJPEGXL_ENABLE_EXAMPLES=OFF \
  -DJPEGXL_FORCE_SYSTEM_BROTLI=ON \
  -DJPEGXL_FORCE_SYSTEM_HWY=ON \
  -DJPEGXL_ENABLE_JPEGLI=ON \
  -DJPEGXL_ENABLE_PLUGINS=ON \
  ..
cmake --build . -- -j$(nproc)
cmake --install .
cd ../.. && rm -rf libjxl
ldconfig /usr/local/lib
