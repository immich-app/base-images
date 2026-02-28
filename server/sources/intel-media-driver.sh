#!/usr/bin/env bash

set -e

: "${INTEL_MEDIA_DRIVER_REVISION:=$(jq -cr '.revision' intel-media-driver.json)}"

git clone https://github.com/intel/media-driver.git
cd media-driver && git reset --hard "${INTEL_MEDIA_DRIVER_REVISION}" && cd ..
mkdir build_media
cd build_media
cmake \
  -D INSTALL_DRIVER_SYSCONF=OFF \
  -D ENABLE_KERNELS=ON \
  -D ENABLE_NONFREE_KERNELS=ON \
  -D BUILD_CMRTLIB=OFF \
  -D MEDIA_BUILD_FATAL_WARNINGS=OFF \
  ../media-driver
make -j"$(nproc)"
make install
cd ..
rm -rf build_media media-driver
