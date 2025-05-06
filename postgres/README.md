# Immich Postgres

This folder contains the build for postgres images to be used by Immich. 
They include both the pgvecto.rs and vectorchord extensions, and are based on the cloudnative-pg images for 
compatibility with that operator.

## Building

To build the Dockerfile locally, you need to pass the `CNPG_TAG`, `VECTORCHORD_TAG`, and `PGVECTORS_TAG` args. For example:  
`docker build . --build-arg="CNPG_TAG=17.4" --build-arg="VECTORCHORD_TAG=0.3.0" --build-arg="PGVECTORS_TAG=0.3.0"`
