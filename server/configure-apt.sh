#!/usr/bin/env bash
export DEBIAN_RELEASE=${DEBIAN_RELEASE:=trixie}
set -e

sed -i -e's/ main/ main contrib non-free non-free-firmware/g' /etc/apt/sources.list.d/debian.sources

# Note: does not add `sid` since mixing it with trixie can cause package resolution conflicts
# due to the time64 migration. Trixie rebuilt all packages with a 64 bit time_t, but not all
# packages in unstable have migrated yet. The 64 bit time version has t64 suffix in the package name.
# More info: https://lwn.net/Articles/938149/ https://wiki.debian.org/ReleaseGoals/64bit-time
sed -i -e"s/ ${DEBIAN_RELEASE}-updates/ ${DEBIAN_RELEASE}-updates testing/g" /etc/apt/sources.list.d/debian.sources

# # default priority is 500, so we set unstable to 450 to prefer stable packages
cat > /etc/apt/preferences.d/preferences << EOL
Package: *
Pin: release a=unstable
Pin-Priority: 450

Package: *
Pin: release a=testing
Pin-Priority: 450
EOL
