#!/usr/bin/env bash

set -e

JPEGLI_LIBJPEG_LIBRARY_SOVERSION="62"
JPEGLI_LIBJPEG_LIBRARY_VERSION="62.3.0"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --JPEGLI_LIBJPEG_LIBRARY_SOVERSION) JPEGLI_LIBJPEG_LIBRARY_SOVERSION="$2"; shift ;;
        --JPEGLI_LIBJPEG_LIBRARY_VERSION) JPEGLI_LIBJPEG_LIBRARY_VERSION="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

: "${LIBJXL_REVISION:=$(jq -cr '.sources[] | select(.name == "libjxl").revision' build-lock.json)}"

git clone https://github.com/libjxl/libjxl.git
cd libjxl
git reset --hard "$LIBJXL_REVISION"
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
  -DJPEGXL_ENABLE_JPEGLI_LIBJPEG=ON \
  -DJPEGXL_INSTALL_JPEGLI_LIBJPEG=ON \
  -DJPEGXL_ENABLE_AVX512=ON \
  -DJPEGXL_ENABLE_AVX512_ZEN4=ON \
  -DJPEGXL_ENABLE_PLUGINS=ON \
  -DJPEGLI_LIBJPEG_LIBRARY_SOVERSION="${JPEGLI_LIBJPEG_LIBRARY_SOVERSION}" \
  -DJPEGLI_LIBJPEG_LIBRARY_VERSION="${JPEGLI_LIBJPEG_LIBRARY_VERSION}" \
  ..
cmake --build . -- -j"$(nproc)"
cmake --install .
cd ../.. && rm -rf libjxl
ldconfig /usr/local/lib
