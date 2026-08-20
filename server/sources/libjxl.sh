#!/usr/bin/env bash

set -e

: "${LIBJXL_REVISION:=$(jq -cr '.revision' libjxl.json)}"

git clone https://github.com/libjxl/libjxl.git
cd libjxl
git reset --hard "$LIBJXL_REVISION"
git submodule update --init --recursive --depth 1 --recommend-shallow

mkdir build
cd build
# Sizeless SVE is disabled as it corrupts chroma upsampling above 128-bit vector length
cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_TESTING=OFF \
  -DJPEGXL_ENABLE_DOXYGEN=OFF \
  -DJPEGXL_ENABLE_MANPAGES=OFF \
  -DJPEGXL_ENABLE_BENCHMARK=OFF \
  -DJPEGXL_ENABLE_EXAMPLES=OFF \
  -DJPEGXL_FORCE_SYSTEM_BROTLI=ON \
  -DJPEGXL_FORCE_SYSTEM_HWY=ON \
  -DJPEGXL_ENABLE_HWY_AVX3=ON \
  -DJPEGXL_ENABLE_HWY_AVX3_ZEN4=ON \
  -DJPEGXL_ENABLE_HWY_SVE=OFF \
  -DJPEGXL_ENABLE_HWY_SVE2=OFF \
  -DJPEGXL_ENABLE_HWY_SVE2_128=ON \
  -DJPEGXL_ENABLE_PLUGINS=ON \
  ..
echo "Building libjxl using $(nproc) threads"
cmake --build . -- -j"$(nproc)"
cmake --install .
cd ../.. && rm -rf libjxl
ldconfig /usr/local/lib
