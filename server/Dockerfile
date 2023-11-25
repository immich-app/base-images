FROM node:20.9-bookworm as dev

WORKDIR /usr/src/app

ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH \
    LD_RUN_PATH=/usr/local/lib:$LD_RUN_PATH

RUN apt-get update && \
    apt-get install --no-install-recommends -yqq \
        autoconf \
        build-essential \
        jq \
        perl \
        libnet-ssleay-perl \
        libio-socket-ssl-perl \
        libcapture-tiny-perl \
        libfile-which-perl \
        libfile-chdir-perl \
        libpkgconfig-perl \
        libffi-checklib-perl \
        libtest-warnings-perl \
        libtest-fatal-perl \
        libtest-needs-perl \
        libtest2-suite-perl \
        libsort-versions-perl \
        libpath-tiny-perl \
        libtry-tiny-perl \
        libterm-table-perl \
        libany-uri-escape-perl \
        libmojolicious-perl \
        libfile-slurper-perl \
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
        pkg-config \
        wget \
        zlib1g \
        cpanminus

COPY bin/* ./
RUN ./build-libraw.sh
RUN ./build-imagemagick.sh
RUN ./build-libvips.sh
RUN ./build-perllib-compress-brotli.sh

RUN sed -i -e's/ main/ main contrib non-free non-free-firmware/g' /etc/apt/sources.list.d/debian.sources
COPY bin/install-ffmpeg.sh bin/build-lock.json ./
RUN ./install-ffmpeg.sh

ADD https://download.geonames.org/export/dump/cities500.zip /usr/src/resources/cities500.zip
ADD https://download.geonames.org/export/dump/admin1CodesASCII.txt /usr/src/resources/admin1CodesASCII.txt
ADD https://download.geonames.org/export/dump/admin2Codes.txt /usr/src/resources/admin2Codes.txt

RUN unzip /usr/src/resources/cities500.zip -d /usr/src/resources/ && \
    rm /usr/src/resources/cities500.zip && date --iso-8601=seconds | tr -d "\n" > /usr/src/resources/geodata-date.txt

FROM node:20.9-bookworm-slim as prod
WORKDIR /usr/src/app

RUN sed -i -e's/ main/ main contrib non-free non-free-firmware/g' /etc/apt/sources.list.d/debian.sources
COPY bin/install-ffmpeg.sh bin/build-lock.json ./

RUN apt-get update && \
    apt-get install --no-install-recommends -yqq \
        ca-certificates \
        $(if [ $(arch) = "x86_64" ]; then echo "intel-media-va-driver-non-free"; fi) \
        jq \
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
        librsvg2-2 \
        libspng0 \
        libwebp7 \
        libwebpdemux2 \
        libwebpmux3 \
        mesa-va-drivers \
        tini \
        wget \
        zlib1g && \
    ./install-ffmpeg.sh && \
    apt-get remove -yqq jq wget ca-certificates && \
    apt-get autoremove -yqq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm install-ffmpeg.sh && \
    rm build-lock.json

COPY --from=dev /usr/local/lib/ /usr/local/lib/
COPY --from=dev /usr/src/resources/ /usr/src/resources/
RUN ldconfig /usr/local/lib
