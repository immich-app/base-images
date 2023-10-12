FROM node:20.8-bookworm

WORKDIR /usr/src/app

COPY bin/install-ffmpeg.sh build-lock.json ./
RUN sed -i -e's/ main/ main contrib non-free non-free-firmware/g' /etc/apt/sources.list.d/debian.sources
RUN apt-get update && apt-get install -yqq build-essential ninja-build meson pkg-config jq zlib1g autoconf \
libglib2.0-dev libexpat1-dev librsvg2-dev libexif-dev libwebp-dev liborc-0.4-dev \
libjpeg62-turbo-dev libgsf-1-dev libspng-dev libjxl-dev libheif-dev liblcms2-2 \
mesa-va-drivers libmimalloc2.0 $(if [ $(arch) = "x86_64" ]; then echo "intel-media-va-driver-non-free"; fi) \
&& ./install-ffmpeg.sh && apt-get autoremove && apt-get clean && rm -rf /var/lib/apt/lists/*

# debian build for imagemagick has broken RAW support, so build manually
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
ENV LD_RUN_PATH=/usr/local/lib:$LD_RUN_PATH
COPY bin/build-libraw.sh bin/build-imagemagick.sh bin/build-libvips.sh bin/use-camera-wb.patch ./
RUN ./build-libraw.sh
RUN ./build-imagemagick.sh
RUN ./build-libvips.sh
