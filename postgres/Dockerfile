ARG PG_MAJOR
ARG PGVECTOR_TAG

FROM pgvector/pgvector:${PGVECTOR_TAG}-pg${PG_MAJOR}

ARG PG_MAJOR
ARG PGVECTOR_TAG
ARG VECTORCHORD_TAG
ARG PGVECTORS_TAG
ARG TARGETARCH
# only set for the "-upgrade" variant, e.g. "14 15 16 17"
ARG UPGRADABLE_MAJORS=""

ENV DB_STORAGE_TYPE=SSD
# the mount point for every major; the entrypoint picks the cluster's folder inside it
ENV PGDATA=/var/lib/postgresql/data

RUN apt-get update && \
    apt-get install -y wget && \
    wget -nv -O /tmp/vchord.deb https://github.com/tensorchord/VectorChord/releases/download/$VECTORCHORD_TAG/postgresql-${PG_MAJOR%.*}-vchord_${VECTORCHORD_TAG#"v"}-1_${TARGETARCH}.deb && \
    if [ -n "$PGVECTORS_TAG" ]; then \
        wget -nv -O /tmp/pgvectors.deb https://github.com/tensorchord/pgvecto.rs/releases/download/v$PGVECTORS_TAG/vectors-pg${PG_MAJOR%.*}_${PGVECTORS_TAG#"v"}_${TARGETARCH}$(if [ "$PGVECTORS_TAG" = '0.3.0' ]; then echo "_vectors"; fi).deb; \
        apt-get install -y /tmp/pgvectors.deb; \
        rm -f /tmp/pgvectors.deb; \
    fi && \
    apt-get install -y /tmp/vchord.deb && \
    rm -f /tmp/vchord.deb && \
    apt-get remove -y wget && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

RUN chmod 1777 /etc/postgresql

# the old servers are unpacked instead of installed, so they bring no dependencies
# or JIT along and run on the libraries PostgreSQL ${PG_MAJOR} already needs
RUN if [ -n "$UPGRADABLE_MAJORS" ]; then \
        . /etc/os-release && \
        echo "deb [signed-by=/usr/local/share/keyrings/postgres.gpg.asc] http://apt-archive.postgresql.org/pub/repos/apt ${VERSION_CODENAME}-pgdg-archive main" \
            > /etc/apt/sources.list.d/pgdg-archive.list && \
        apt-get update && \
        apt-get install -y --no-install-recommends wget ca-certificates && \
        mkdir /tmp/debs /tmp/unpacked && cd /tmp/debs && \
        for major in $UPGRADABLE_MAJORS; do \
            apt-get download postgresql-$major "postgresql-$major-pgvector=${PGVECTOR_TAG}-1.pgdg*" && \
            wget -nv "https://github.com/tensorchord/VectorChord/releases/download/${VECTORCHORD_TAG}/postgresql-$major-vchord_${VECTORCHORD_TAG#v}-1_${TARGETARCH}.deb" || exit 1; \
        done && \
        for deb in *.deb; do dpkg-deb -x "$deb" /tmp/unpacked || exit 1; done && \
        cd /tmp/unpacked/usr && \
        for major in $UPGRADABLE_MAJORS; do \
            rm -rf lib/postgresql/$major/lib/bitcode lib/postgresql/$major/lib/llvmjit* lib/postgresql/$major/lib/pgxs share/postgresql/$major/man && \
            mv lib/postgresql/$major /usr/lib/postgresql/ && \
            mv share/postgresql/$major /usr/share/postgresql/ && \
            ! ldd /usr/lib/postgresql/$major/bin/postgres /usr/lib/postgresql/$major/lib/*.so | grep "not found" || exit 1; \
        done && \
        cd / && rm -rf /tmp/debs /tmp/unpacked /etc/apt/sources.list.d/pgdg-archive.list && \
        apt-get remove -y wget && \
        apt-get autoremove -y && \
        apt-get clean -y && \
        rm -rf /var/lib/apt/lists/*; \
    fi

# bound in rather than COPY'd so regular tags never contain the script in a lower layer
RUN --mount=type=bind,source=major-upgrade.sh,target=/tmp/major-upgrade.sh \
    if [ -n "$UPGRADABLE_MAJORS" ]; then \
        cp /tmp/major-upgrade.sh /usr/local/bin/major-upgrade.sh; \
    fi

COPY postgresql.hdd.conf postgresql.ssd.conf /var/postgresql-conf-tpl/
COPY immich-docker-entrypoint.sh healthcheck.sh set-env.sh /usr/local/bin/

HEALTHCHECK --interval=5m --start-interval=5s --start-period=5m CMD /usr/local/bin/healthcheck.sh

RUN if [ -n "$PGVECTORS_TAG" ]; then \
        sed -i "s/vchord.so/vchord.so, vectors.so/" /var/postgresql-conf-tpl/postgresql.*.conf; \
        sed -i "s/, public/, public, vectors/" /var/postgresql-conf-tpl/postgresql.*.conf; \
    fi

ENTRYPOINT ["/usr/local/bin/immich-docker-entrypoint.sh"]

CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]
