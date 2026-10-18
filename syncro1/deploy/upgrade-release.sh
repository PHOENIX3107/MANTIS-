#!/bin/sh
set -eu

release_root=${1:-/opt/syncro1/current}
if [ ! -x "$release_root/syncro1/scripts/install-headless" ]; then
	echo "Invalid release root: $release_root" >&2
	exit 1
fi

cd "$release_root"
"$release_root/syncro1/scripts/install-headless"
"$release_root/syncro1/scripts/post-install-lockdown" "$release_root"
echo "Schema upgrade and installer lockdown complete for $release_root"
