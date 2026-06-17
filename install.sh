#!/usr/bin/env bash
#
# install.sh - Optional system-wide installer for Pardus Kernel Swap.
#
# Symlinks the launcher into a directory on root's PATH so the tool can be run
# as `pardus-kernel-swap`. The repository remains the source of truth; this
# only creates a pointer to it.
set -euo pipefail

PREFIX="${PREFIX:-/usr/local/sbin}"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAUNCHER="$SRC_DIR/bin/pardus-kernel-swap"
TARGET="$PREFIX/pardus-kernel-swap"

if [ "$(id -u)" -ne 0 ]; then
    echo "install.sh: must be run as root (try: sudo ./install.sh)" >&2
    exit 1
fi

if [ ! -x "$LAUNCHER" ]; then
    echo "install.sh: launcher not found or not executable: $LAUNCHER" >&2
    exit 1
fi

install -d "$PREFIX"
ln -sf "$LAUNCHER" "$TARGET"
echo "Installed: $TARGET -> $LAUNCHER"
echo "Run with:  sudo pardus-kernel-swap"
