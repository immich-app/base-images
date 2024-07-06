#!/usr/bin/env bash

set -e

mkdir geodata
cd geodata

curl -o cities500.zip https://download.geonames.org/export/dump/cities500.zip
curl -o admin1CodesASCII.txt https://download.geonames.org/export/dump/admin1CodesASCII.txt
curl -o admin2Codes.txt https://download.geonames.org/export/dump/admin2Codes.txt
curl -o LICENSE https://creativecommons.org/licenses/by/4.0/legalcode.txt

unzip cities500.zip
rm -f cities500.zip

date --iso-8601=seconds | tr -d "\n" > geodata-date.txt

cd ..
