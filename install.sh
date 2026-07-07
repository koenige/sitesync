#!/bin/sh

# Install sitesync into PATH via symlink.
# Copyright © 2025-2026 Gustaf Mossakowski
# SPDX-License-Identifier: MIT

set -e

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source="$script_dir/sitesync"
bindir="${BINDIR:-/usr/local/bin}"
link="$bindir/sitesync"

if [ ! -f "$source" ]; then
	echo "Missing $source" >&2
	exit 1
fi

chmod +x "$source"

if [ -e "$link" ] && [ ! -L "$link" ]; then
	echo "$link exists and is not a symlink; refusing to overwrite." >&2
	exit 1
fi

if [ ! -d "$bindir" ]; then
	echo "Creating $bindir (sudo may prompt for your password)..."
	sudo mkdir -p "$bindir"
fi

if ln -sf "$source" "$link" 2>/dev/null; then
	:
else
	echo "Could not write $link; trying with sudo..."
	sudo ln -sf "$source" "$link"
fi

echo "Installed: $link -> $source"
