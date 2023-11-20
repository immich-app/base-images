#!/usr/bin/env bash

set -e

mkdir -p perllib-compress-brotli
cd perllib-compress-brotli
cpanm IO::Compress::Brotli
cd .. && rm -rf perllib-compress-brotli
rm -rf /usr/local/lib/*-linux-gnu/perl/*/auto/Alien
rm -rf /usr/local/lib/*-linux-gnu/perl/*/auto/share/
rm -rf /usr/local/lib/*-linux-gnu/perl/*/Alien/
ldconfig /usr/local/lib
