FROM node:22.16.0-bookworm@sha256:0b5b940c21ab03353de9042f9166c75bcfc53c4cd0508c7fd88576646adbf875 AS base

WORKDIR /usr/src/app

ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH \
    LD_RUN_PATH=/usr/local/lib:$LD_RUN_PATH

COPY configure-apt.sh ./

# when trixie is released, move libio-compress-brotli-perl from testing to stable
RUN ./configure-apt.sh && \
    apt-get update && \
    apt-get install --no-install-recommends -yqq \
        autoconf \
        build-essential \
        cmake \
        jq \
        libbrotli-dev \
        libde265-dev \
        libexif-dev \
        libexpat1-dev \
        libglib2.0-dev \
        libgsf-1-dev \
        # libjpeg62-turbo-dev is just for building libvips; the final image uses jpegli (/usr/local/lib/libjpeg.so.62) built alongside libjxl
        libjpeg62-turbo-dev \
        liblcms2-2 \
        librsvg2-dev \
        libspng-dev \
        meson \
        ninja-build \
        pkg-config \
        wget \
        zlib1g \
        cpanminus \
        wget \
        postgresql-client-14 \
        postgresql-client-15 \
        postgresql-client-16 \
        postgresql-client-17 && \
    apt-get install -t testing --no-install-recommends -yqq \
        libdav1d-dev \
        libhwy-dev \
        libwebp-dev \
        libio-compress-brotli-perl \
        libaom-dev \
        libaom3

FROM base AS ffmpeg

COPY packages/ffmpeg.json packages/ffmpeg.sh ./
RUN ./ffmpeg.sh

FROM base AS geodata

ADD https://download.geonames.org/export/dump/cities500.zip /build/geodata/cities500.zip
ADD --chmod=444 https://download.geonames.org/export/dump/admin1CodesASCII.txt /build/geodata/admin1CodesASCII.txt
ADD --chmod=444 https://download.geonames.org/export/dump/admin2Codes.txt /build/geodata/admin2Codes.txt
ADD --chmod=444 https://raw.githubusercontent.com/nvkelso/natural-earth-vector/v5.1.2/geojson/ne_10m_admin_0_countries.geojson /build/geodata/ne_10m_admin_0_countries.geojson

RUN umask 0333 && unzip /build/geodata/cities500.zip -d /build/geodata/ && \
    rm /build/geodata/cities500.zip && date --iso-8601=seconds | tr -d "\n" > /build/geodata/geodata-date.txt

FROM base AS libheif

COPY sources/libheif.json sources/libheif.sh ./
RUN ./libheif.sh

FROM base AS libjxl

COPY sources/libjxl.json sources/libjxl.sh ./
COPY sources/libjxl-patches/ ./libjxl-patches/
RUN ./libjxl.sh

FROM base AS libraw

COPY sources/libraw.json sources/libraw.sh ./
RUN ./libraw.sh

FROM libraw AS imagemagick

COPY --from=libheif /usr/local/lib/ /usr/local/lib/libheif/
COPY --from=libheif /usr/local/include/libheif/ /usr/local/include/libheif/

COPY --from=libjxl /usr/local/lib/ /usr/local/lib/libjxl/
COPY --from=libjxl /usr/local/include/jxl/ /usr/local/include/jxl/
COPY --from=libjxl /usr/local/include/jconfig.h /usr/local/include/jmorecfg.h /usr/local/include/jpeglib.h /usr/local/include/

# COPY resolves symlinks unless copying the enclosing folder, so this is a workaround to get the correct result
RUN cp -r /usr/local/lib/libheif/libheif* /usr/local/lib/libjxl/libjxl* /usr/local/lib/libjxl/libjpeg* /usr/local/lib && \
    mv /usr/local/lib/libheif/pkgconfig/* /usr/local/lib/libjxl/pkgconfig/* /usr/local/lib/pkgconfig && \
    rm -r /usr/local/lib/libheif /usr/local/lib/libjxl

COPY sources/imagemagick.json sources/imagemagick.sh ./
RUN ./imagemagick.sh

FROM imagemagick AS libvips

COPY sources/libvips.json sources/libvips.sh ./
RUN ./libvips.sh

FROM base AS dev

COPY --from=ffmpeg /usr/lib/jellyfin-ffmpeg /usr/lib/jellyfin-ffmpeg
COPY --from=libvips /usr/local/lib/ /usr/local/lib/
COPY --from=libvips /usr/local/bin/vips* /usr/local/bin/
COPY --from=libvips /usr/local/include/vips/ /usr/local/include/vips/
COPY --from=geodata /build/geodata /build/geodata

COPY packages/ ./packages/
RUN jq -s '.' packages/*.json > /tmp/packages.json
COPY sources/ ./sources/
RUN jq -s '.' sources/*.json > /tmp/sources.json
RUN jq -n \
    --slurpfile sources /tmp/sources.json \
    --slurpfile packages /tmp/packages.json \
    '{sources: $sources[0], packages: $packages[0]}' \
    > /build/build-lock.json

FROM node:22.16.0-bookworm-slim@sha256:2f3571619daafc6b53232ebf2fcc0817c1e64795e92de317c1684a915d13f1a5 AS prod

WORKDIR /build

COPY configure-apt.sh packages/ffmpeg.json packages/ffmpeg.sh ./

RUN apt-get update && \
    apt-get install curl ca-certificates --no-install-recommends -yqq && \
    ./configure-apt.sh && \
    apt-get update && \
    apt-get install --no-install-recommends -yqq \
        jq \
        libde265-0 \
        libexif12 \
        libexpat1 \
        libgcc-s1 \
        libglib2.0-0 \
        libgomp1 \
        libgsf-1-114 \
        liblcms2-2 \
        liblqr-1-0 \
        libltdl7 \
        libmimalloc2.0 \
        libopenexr-3-1-30 \
        libopenjp2-7 \
        librsvg2-2 \
        libspng0 \
        mesa-utils \
        mesa-va-drivers \
        mesa-vulkan-drivers \
        tini \
        wget \
        zlib1g \
        ocl-icd-libopencl1 \
        postgresql-client-14 \
        postgresql-client-15 \
        postgresql-client-16 \
        postgresql-client-17 && \
        ./ffmpeg.sh && \
    apt-get install -t testing --no-install-recommends -yqq \
        libio-compress-brotli-perl \
        libwebp7 \
        libwebpdemux2 \
        libwebpmux3 \
        libhwy1t64 \
        libaom3 && \
    if [ $(arch) = "x86_64" ]; then \
        wget https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.17193.4/intel-igc-core_1.0.17193.4_amd64.deb && \
        wget https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.17193.4/intel-igc-opencl_1.0.17193.4_amd64.deb && \
        wget https://github.com/intel/compute-runtime/releases/download/24.26.30049.6/intel-opencl-icd_24.26.30049.6_amd64.deb && \
        wget https://github.com/intel/compute-runtime/releases/download/24.26.30049.6/libigdgmm12_22.3.20_amd64.deb && \
        dpkg -i *.deb && \
        apt-get install -t testing --no-install-recommends -yqq intel-media-va-driver-non-free; \
    fi && \
    apt-get remove -yqq jq wget ca-certificates && \
    apt-get autoremove -yqq && \
    apt-get clean && \
    rm -rf \
        configure-apt.sh \
        ffmpeg* \
        *.deb \
        /var/lib/apt/lists \
        /usr/lib/$(arch)-linux-gnu/libjpeg.so* \
        /usr/share/doc/libjpeg62-turbo \
        /usr/share/lintian/overrides/libjpeg62-turbo

COPY --from=dev /usr/local/lib/ /usr/local/lib/
COPY --from=dev /build/ /build/

WORKDIR /usr/src/app

ENV LD_LIBRARY_PATH=/usr/lib/jellyfin-ffmpeg/lib:/usr/lib/wsl/lib:$LD_LIBRARY_PATH

RUN ldconfig /usr/local/lib
