#!/usr/bin/env bash

set -e

sed -i -e's/ main/ main contrib non-free non-free-firmware/g' /etc/apt/sources.list.d/debian.sources
sed -i -e's/ bookworm-updates/ bookworm-updates testing sid/g' /etc/apt/sources.list.d/debian.sources

# default priority is 500, so we set unstable to 450 to prefer stable packages
cat > /etc/apt/preferences.d/preferences << EOL
Package: *
Pin: release a=unstable
Pin-Priority: 450

Package: *
Pin: release a=testing
Pin-Priority: 450
EOL

# Setup postgresql repository
install -d /usr/share/postgresql-common/pgdg
curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" > /etc/apt/sources.list.d/pgdg.list
