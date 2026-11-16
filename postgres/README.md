# Immich PostgreSQL

This folder contains the build for PostgresSQL images to be used by Immich. 
They include the VectorChord, pgvector, and (optionally) pgvecto.rs extensions.

## Building

To build the Dockerfile locally, you need to pass the `PG_MAJOR`, 'PGVECTOR_TAG', `VECTORCHORD_TAG`, and `PGVECTORS_TAG` args. For example:  
`docker build . --build-arg="PG_MAJOR=17" --build-arg="PGVECTOR_TAG=0.8.0" --build-arg="VECTORCHORD_TAG=0.3.0" --build-arg="PGVECTORS_TAG=0.3.0"`

## Major upgrade

The `-upgrade` variant of an image also ships the older PostgreSQL servers and upgrades an existing cluster to its own major when it starts.

1. Stop Immich and change the database image tag to the `-upgrade` variant.
2. Start it. The cluster is upgraded into `$PGDATA/<new major>` and the old one is kept as `$PGDATA/<old major>.bak`. Immich rebuilds its vector indexes on its next start.
3. Switch to the same tag without `-upgrade`.
4. Delete the `.bak` folder once everything looks good.

The upgrade copies the data, so the volume needs free space for a second copy unless the filesystem can clone files (e.g. btrfs, XFS). An interrupted upgrade is retried on the next start. To roll back, follow the instructions in the container log.

| Variable    | Default                    | Description                                                                                            |
| ----------- | -------------------------- | ------------------------------------------------------------------------------------------------------ |
| `PGDATA`    | `/var/lib/postgresql/data` | Where the volume is mounted. The upgraded cluster is created in `$PGDATA/<new major>`.                 |
| `PGDATAOLD` | `$PGDATA`                  | The cluster to upgrade. Only needed when it is not at `$PGDATA`, e.g. `/var/lib/postgresql/17/docker`. |
