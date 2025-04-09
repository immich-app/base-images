FROM node:22.14.0-bookworm@sha256:e5ddf893cc6aeab0e5126e4edae35aa43893e2836d1d246140167ccc2616f5d7 AS dev

WORKDIR /usr/src/app

ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH \
    LD_RUN_PATH=/usr/local/lib:$LD_RUN_PATH

COPY bin/configure-apt.sh ./

# when trixie is released, remove build-perllib-compress-brotli.sh and move libio-compress-brotli-perl from testing to stable
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
        libio-compress-brotli-perl

COPY bin/* ./

RUN ./build-libjxl.sh
RUN ./build-libheif.sh
RUN ./build-libraw.sh
RUN ./build-imagemagick.sh
RUN ./build-libvips.sh
RUN ./install-ffmpeg.sh

ADD https://download.geonames.org/export/dump/cities500.zip /build/geodata/cities500.zip
ADD --chmod=444 https://download.geonames.org/export/dump/admin1CodesASCII.txt /build/geodata/admin1CodesASCII.txt
ADD --chmod=444 https://download.geonames.org/export/dump/admin2Codes.txt /build/geodata/admin2Codes.txt
ADD --chmod=444 https://raw.githubusercontent.com/nvkelso/natural-earth-vector/v5.1.2/geojson/ne_10m_admin_0_countries.geojson /build/geodata/ne_10m_admin_0_countries.geojson

RUN umask 0333 && unzip /build/geodata/cities500.zip -d /build/geodata/ && \
    rm /build/geodata/cities500.zip && date --iso-8601=seconds | tr -d "\n" > /build/geodata/geodata-date.txt

FROM node:22.14.0-bookworm-slim@sha256:1c18d9ab3af4585870b92e4dbc5cac5a0dc77dd13df1a5905cea89fc720eb05b AS prod

WORKDIR /build

COPY bin/build-lock.json bin/configure-apt.sh bin/install-ffmpeg.sh  ./

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
    ./install-ffmpeg.sh && \
    apt-get install -t testing --no-install-recommends -yqq \
        libio-compress-brotli-perl \
        libwebp7 \
        libwebpdemux2 \
        libwebpmux3 \
        libhwy1t64 && \
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
        install-ffmpeg.sh \
        *.deb \
        /var/lib/apt/lists \
        /usr/lib/$(arch)-linux-gnu/libjpeg.so* \
        /usr/share/doc/libjpeg62-turbo \
        /usr/share/lintian/overrides/libjpeg62-turbo

COPY --from=dev /usr/local/lib/ /usr/local/lib/
COPY --from=dev /build/geodata/ /build/geodata/

WORKDIR /usr/src/app

ENV LD_LIBRARY_PATH=/usr/lib/jellyfin-ffmpeg/lib:/usr/lib/wsl/lib:$LD_LIBRARY_PATH

RUN ldconfig /usr/local/lib
