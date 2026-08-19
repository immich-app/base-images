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

: "${JPEGLI_REVISION:=$(jq -cr '.revision' jpegli.json)}"

git clone https://github.com/google/jpegli.git
cd jpegli
git reset --hard "$JPEGLI_REVISION"
git submodule update --init --depth 1 --recommend-shallow third_party/libjpeg-turbo
git apply -3 ../jpegli-patches/jpegli-empty-dht-marker.patch # https://github.com/google/jpegli/pull/222
git apply -3 ../jpegli-patches/jpegli-icc-warning.patch # https://github.com/google/jpegli/pull/48

mkdir build
cd build
# Sizeless SVE is disabled as it corrupts chroma upsampling above 128-bit vector length
cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_TESTING=OFF \
  -DJPEGLI_ENABLE_DOXYGEN=OFF \
  -DJPEGLI_ENABLE_MANPAGES=OFF \
  -DJPEGLI_ENABLE_BENCHMARK=OFF \
  -DJPEGLI_ENABLE_TOOLS=OFF \
  -DJPEGLI_ENABLE_DEVTOOLS=OFF \
  -DJPEGLI_ENABLE_FUZZERS=OFF \
  -DJPEGLI_ENABLE_JNI=OFF \
  -DJPEGLI_ENABLE_OPENEXR=OFF \
  -DJPEGLI_ENABLE_SJPEG=OFF \
  -DJPEGLI_ENABLE_SKCMS=OFF \
  -DJPEGLI_FORCE_SYSTEM_HWY=ON \
  -DJPEGLI_FORCE_SYSTEM_LCMS2=ON \
  -DJPEGLI_ENABLE_JPEGLI_LIBJPEG=ON \
  -DJPEGLI_INSTALL_JPEGLI_LIBJPEG=ON \
  -DJPEGLI_ENABLE_HWY_AVX3=ON \
  -DJPEGLI_ENABLE_HWY_AVX3_ZEN4=ON \
  -DJPEGLI_ENABLE_HWY_SVE=OFF \
  -DJPEGLI_ENABLE_HWY_SVE2=OFF \
  -DJPEGLI_ENABLE_HWY_SVE2_128=ON \
  -DJPEGLI_LIBJPEG_LIBRARY_SOVERSION="${JPEGLI_LIBJPEG_LIBRARY_SOVERSION}" \
  -DJPEGLI_LIBJPEG_LIBRARY_VERSION="${JPEGLI_LIBJPEG_LIBRARY_VERSION}" \
  -DLIBJPEG_TURBO_VERSION_NUMBER=2001005 \
  ..
echo "Building jpegli using $(nproc) threads"
cmake --build . -- -j"$(nproc)"
cmake --install .

cd ../.. && rm -rf jpegli
ldconfig /usr/local/lib
