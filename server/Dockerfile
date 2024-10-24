FROM node:20.18.0-bookworm@sha256:a5e0ed56f2c20b9689e0f7dd498cac7e08d2a3a283e92d9304e7b9b83e3c6ff3 AS dev

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
        cpanminus && \
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

FROM node:20.18.0-bookworm-slim@sha256:5bba9bfa8c663a8bb5f014d39ea97550946b355b49308c2d1305d706489e8e14 AS prod

WORKDIR /build

COPY bin/build-lock.json bin/configure-apt.sh bin/install-ffmpeg.sh  ./

RUN ./configure-apt.sh && \
    apt-get update && \
    apt-get install --no-install-recommends -yqq \
        ca-certificates \
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
        ocl-icd-libopencl1 && \
    ./install-ffmpeg.sh && \
    apt-get install -t testing --no-install-recommends -yqq \
        libio-compress-brotli-perl \
        libwebp7 \
        libwebpdemux2 \
        libwebpmux3 \
        libhwy1t64 \
        postgresql-client-17 && \
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
    dpkg -r --force-depends libjpeg62-turbo && \
    rm -rf \
        configure-apt.sh \
        install-ffmpeg.sh \
        *.deb \
        /var/lib/apt/lists

COPY --from=dev /usr/local/lib/ /usr/local/lib/
COPY --from=dev /build/geodata/ /build/geodata/

WORKDIR /usr/src/app

ENV LD_LIBRARY_PATH=/usr/lib/jellyfin-ffmpeg/lib:/usr/lib/wsl/lib:$LD_LIBRARY_PATH

RUN ldconfig /usr/local/lib
