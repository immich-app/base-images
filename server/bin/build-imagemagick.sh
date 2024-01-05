#!/usr/bin/env bash

set -e

: "${IMAGEMAGICK_REVISION:=$(jq -cr '.sources[] | select(.name == "imagemagick").revision' build-lock.json)}"

git clone https://github.com/ImageMagick/ImageMagick.git
cd ImageMagick
git reset --hard $IMAGEMAGICK_REVISION

./configure --with-modules
make -j$(nproc)
make install
cd .. && rm -rf ImageMagick
ldconfig /usr/local/lib
