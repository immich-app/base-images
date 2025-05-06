ARG CNPG_TAG

FROM ghcr.io/cloudnative-pg/postgresql:$CNPG_TAG-bookworm

ARG CNPG_TAG
ARG VECTORCHORD_TAG
ARG PGVECTORS_TAG
ARG TARGETARCH

# drop to root to install packages
USER root
ADD https://github.com/tensorchord/VectorChord/releases/download/$VECTORCHORD_TAG/postgresql-${CNPG_TAG%.*}-vchord_${VECTORCHORD_TAG#"v"}-1_${TARGETARCH}.deb /tmp/vchord.deb
RUN apt install -y /tmp/vchord.deb && rm -f /tmp/vchord.deb
ADD https://github.com/tensorchord/pgvecto.rs/releases/download/v$PGVECTORS_TAG/vectors-pg${CNPG_TAG%.*}_${PGVECTORS_TAG#"v"}_${TARGETARCH}_vectors.deb /tmp/pgvectors.deb
RUN apt install -y /tmp/pgvectors.deb && rm -f /tmp/pgvectors.deb

USER postgres

