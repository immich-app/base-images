#!/usr/bin/env bash

set -e

: "${IMAGEMAGICK_REVISION:=$(jq -cr '.sources[] | select(.name == "imagemagick").revision' build-lock.json)}"

git clone https://github.com/ImageMagick/ImageMagick.git
git -C ImageMagick reset --hard $IMAGEMAGICK_REVISION

patch -u ImageMagick/coders/dng.c -i use-camera-wb.patch
cd ImageMagick
./configure --with-modules
make -j$(nproc)
make install
cd .. && rm -rf ImageMagick
ldconfig /usr/local/lib
