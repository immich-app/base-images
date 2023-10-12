FROM node:20-bookworm-slim

WORKDIR /usr/src/app

ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH \
    LD_RUN_PATH=/usr/local/lib:$LD_RUN_PATH

COPY bin/* .

RUN sed -i -e's/ main/ main contrib non-free non-free-firmware/g' /etc/apt/sources.list.d/debian.sources && \
    apt-get update && \
    echo "**** install build packages ****" && \
    apt-get install --no-install-recommends -yqq \
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
        meson \
        ninja-build \
        pkg-config && \
    echo "**** install runtime packages ****" && \
    apt-get install --no-install-recommends -yqq \
        $(if [ $(arch) = "x86_64" ]; then echo "intel-media-va-driver-non-free"; fi) \
        libexif12 \
        libexpat1 \
        libgcc-s1 \
        libglib2.0-0 \
        libgomp1 \
        libgsf-1-114 \
        libheif1 \
        libjpeg62-turbo \
        libjxl0.7 \
        liblcms2-2 \
        liblqr-1-0 \
        libltdl7 \
        libmimalloc2.0 \
        libopenexr-3-1-30 \
        libopenjp2-7 \
        liborc-0.4-0 \
        libpng16-16 \
        librsvg2-2 \
        libspng0 \
        libwebp7 \
        libwebpdemux2 \
        libwebpmux3 \
        mesa-va-drivers \
        tini \
        wget \
        zlib1g && \
    echo "**** build dependencies ****" && \
    ./install-ffmpeg.sh && \
    ./build-libraw.sh && \
    ./build-imagemagick.sh && \
    ./build-libvips.sh && \
    echo "**** cleanup ****" && \
    rm -f \
        build-* \
        install-ffmpeg.sh \
        use-camera-web.patch && \
    apt-get remove -y --purge \
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
        liborc-0.4-dev \
        librsvg2-dev \
        libspng-dev \
        libwebp-dev \
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
