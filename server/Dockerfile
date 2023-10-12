FROM node:20.8-bookworm

WORKDIR /usr/src/app

ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH \
    LD_RUN_PATH=/usr/local/lib:$LD_RUN_PATH

COPY bin/* build-lock.json .

RUN sed -i -e's/ main/ main contrib non-free non-free-firmware/g' /etc/apt/sources.list.d/debian.sources && \
    apt-get update && \
    apt-get install -yqq \
        autoconf \
        build-essential \
        jq \
        libexif-dev \
        libexpat1-dev \
        libglib2.0-dev \
        libgsf-1-dev \
        libheif-dev \
        libjpeg62-turbo-dev \
        libjxl-dev \
        liblcms2-2 \
        liborc-0.4-dev \
        librsvg2-dev \
        libspng-dev \
        libwebp-dev \
        mesa-va-drivers \
        meson \
        ninja-build \
        libmimalloc2.0 \
        pkg-config \
        zlib1g \
        $(if [ $(arch) = "x86_64" ]; then echo "intel-media-va-driver-non-free"; fi) && \
    ./install-ffmpeg.sh && \
    ./build-libraw.sh && \
    ./build-imagemagick.sh && \
    ./build-libvips.sh && \
    apt-get remove -y --purge \
        autoconf \
        build-essential \
        meson \
        ninja-build \
        pkg-config && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf \
        /var/tmp/* \
        /var/lib/apt/lists/* \
        /root/.cache \
        /var/lib/apt/lists/*
