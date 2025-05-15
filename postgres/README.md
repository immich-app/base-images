# Immich PostgreSQL

This folder contains the build for PostgresSQL images to be used by Immich. 
They include the VectorChord, pgvector, and (optionally) pgvecto.rs extensions.

## Building

To build the Dockerfile locally, you need to pass the `PG_MAJOR`, 'PGVECTOR_TAG', `VECTORCHORD_TAG`, and `PGVECTORS_TAG` args. For example:  
`docker build . --build-arg="PG_MAJOR=17" --build-arg="PGVECTOR_TAG=0.8.0" --build-arg="VECTORCHORD_TAG=0.3.0" --build-arg="PGVECTORS_TAG=0.3.0"`
