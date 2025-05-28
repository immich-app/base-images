ARG PG_MAJOR
ARG PGVECTOR_TAG

FROM pgvector/pgvector:${PGVECTOR_TAG}-pg${PG_MAJOR}

ARG PG_MAJOR
ARG VECTORCHORD_TAG
ARG PGVECTORS_TAG
ARG TARGETARCH

ENV DB_STORAGE_TYPE=SSD

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

COPY postgresql.hdd.conf postgresql.ssd.conf /var/postgresql-conf-tpl/
COPY immich-docker-entrypoint.sh healthcheck.sh set-env.sh /usr/local/bin/

HEALTHCHECK --interval=5m --start-interval=5s --start-period=5m CMD /usr/local/bin/healthcheck.sh

RUN if [ -n "$PGVECTORS_TAG" ]; then \
        sed -i "s/vchord.so/vchord.so, vectors.so/" /var/postgresql-conf-tpl/postgresql.*.conf; \
        sed -i "s/, public/, public, vectors/" /var/postgresql-conf-tpl/postgresql.*.conf; \
    fi

ENTRYPOINT ["/usr/local/bin/immich-docker-entrypoint.sh"]

CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]
