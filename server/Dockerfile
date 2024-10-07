FROM node:20.18.0-bookworm@sha256:fffa89e023a3351904c04284029105d9e2ac7020886d683775a298569591e5bb AS dev

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
        libjpeg62-turbo-dev \
        liblcms2-2 \
        liborc-0.4-dev \
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

FROM node:20.18.0-bookworm-slim@sha256:967bab29ecde5d59a6dd781054bf9021eee8116068e1f5cb139750b6bc6a75e9 AS prod

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
        # libjpeg62-turbo-dev is just for building libvips; the final image uses jpegli (/usr/local/lib/libjpeg.so.62) built alongside libjxl
        libjpeg62-turbo \
        liblcms2-2 \
        liblqr-1-0 \
        libltdl7 \
        libmimalloc2.0 \
        libopenexr-3-1-30 \
        libopenjp2-7 \
        liborc-0.4-0 \
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
