#!/usr/bin/env bash

set -e

: "${IMAGEMAGICK_REVISION:=$(jq -cr '.revision' imagemagick.json)}"

git clone https://github.com/ImageMagick/ImageMagick.git
cd ImageMagick
git reset --hard "$IMAGEMAGICK_REVISION"

./configure --with-modules
echo "Building ImageMagick using $(nproc) threads"
make -j"$(nproc)"
make install
cd .. && rm -rf ImageMagick
ldconfig /usr/local/lib
