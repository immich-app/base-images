ARG PG_MAJOR
ARG PGVECTOR_TAG=0.8.0

FROM pgvector/pgvector:${PGVECTOR_TAG}-pg${PG_MAJOR}

ARG PG_MAJOR
ARG VECTORCHORD_TAG
ARG PGVECTORS_TAG
ARG TARGETARCH

# drop to root to install packages
USER root
RUN apt-get update && \
    apt-get install -y wget && \
    wget -O /tmp/vchord.deb https://github.com/tensorchord/VectorChord/releases/download/$VECTORCHORD_TAG/postgresql-${PG_MAJOR%.*}-vchord_${VECTORCHORD_TAG#"v"}-1_${TARGETARCH}.deb && \
    if [ -n "$PGVECTORS_TAG" ]; then \
        wget -O /tmp/pgvectors.deb https://github.com/tensorchord/pgvecto.rs/releases/download/v$PGVECTORS_TAG/vectors-pg${PG_MAJOR%.*}_${PGVECTORS_TAG#"v"}_${TARGETARCH}$(if [ "$PGVECTORS_TAG" = '0.3.0']; then echo "_vectors"; fi).deb; \
        apt-get install -y /tmp/pgvectors.deb; \
        rm -f /tmp/pgvectors.deb; \
    fi && \
    apt-get install -y /tmp/vchord.deb && \
    rm -f /tmp/vchord.deb && \
    apt-get remove -y wget && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*
USER postgres

COPY postgresql.hdd.conf postgresql.ssd.conf /etc/postgresql/

HEALTHCHECK --interval=5m --start-interval=30s --start-period=5m CMD pg_isready --dbname="$${POSTGRES_DB}" --username="$${POSTGRES_USER}" || exit 1; Chksum="$$(psql --dbname="$${POSTGRES_DB}" --username="$${POSTGRES_USER}" --tuples-only --no-align --command='SELECT COALESCE(SUM(checksum_failures), 0) FROM pg_stat_database')"; echo "checksum failure count is $$Chksum"; [ "$$Chksum" = '0' ] || exit 1

CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.ssd.conf"]
