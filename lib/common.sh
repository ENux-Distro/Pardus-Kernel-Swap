#!/usr/bin/env bash
#
# common.sh - Shared globals, paths and small helpers for Pardus Kernel Swap.
#
# This file is sourced by every other module. It must not produce output on
# its own and must be safe to source more than once.

# Guard against double-sourcing.
[ -n "${PKS_COMMON_SOURCED:-}" ] && return 0
PKS_COMMON_SOURCED=1

# ----------------------------------------------------------------------------
# Application metadata
# ----------------------------------------------------------------------------
PKS_NAME="Pardus Kernel Swap"
PKS_VERSION="1.0.0"

# ----------------------------------------------------------------------------
# Paths
# ----------------------------------------------------------------------------
# PKS_ROOT is the project root (parent of lib/). bin/pardus-kernel-swap sets
# PKS_ROOT before sourcing; we fall back to deriving it from this file's path
# so the modules can also be sourced directly during testing.
if [ -z "${PKS_ROOT:-}" ]; then
    PKS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

PKS_LIB_DIR="$PKS_ROOT/lib"
PKS_DATA_DIR="$PKS_ROOT/data"

PKS_CVE_DB="$PKS_DATA_DIR/cve.json"
PKS_KERNEL_DB="$PKS_DATA_DIR/kernels.json"

PKS_LOG_FILE="${PKS_LOG_FILE:-/var/log/pardus-kernel-swap.log}"

# Working area for downloads and builds. Created lazily.
PKS_WORK_DIR="${PKS_WORK_DIR:-/var/tmp/pardus-kernel-swap}"

# Base URL for predefined kernel packages. The kernel version is appended.
PKS_RELEASE_BASE_URL="https://github.com/ENux-Distro/Pardus-Kernel-Swap/releases/download/Kernels"

# Predefined kernel assets are published as one image package and one headers
# package per version, named:
#   linux-image-<version>.deb
#   linux-headers-<version>.deb
# e.g. linux-image-7.0.12+pardus25-amd64.deb
PKS_PACKAGE_SUFFIX=".deb"
PKS_IMAGE_PREFIX="linux-image-"
PKS_HEADERS_PREFIX="linux-headers-"

# Whiptail dialog dimensions (classic 80x24-friendly sizing).
PKS_DLG_HEIGHT=20
PKS_DLG_WIDTH=72

# ----------------------------------------------------------------------------
# Classic FreeBSD sysinstall-style colour scheme: blue background, white text.
# ----------------------------------------------------------------------------
export NEWT_COLORS='
root=white,blue
window=white,lightgray
border=black,lightgray
shadow=black,gray
title=blue,lightgray
button=white,blue
actbutton=white,red
checkbox=black,lightgray
actcheckbox=white,blue
entry=black,lightgray
label=black,lightgray
listbox=black,lightgray
actlistbox=white,blue
textbox=black,lightgray
acttextbox=white,blue
helpline=white,blue
roottext=white,blue
'

# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------

# die MESSAGE - log an error, show it (if a terminal is available) and exit 1.
die() {
    local msg="$1"
    log_error "$msg" 2>/dev/null || true
    if command -v whiptail >/dev/null 2>&1 && [ -t 0 ]; then
        whiptail --title "$PKS_NAME - Fatal Error" --msgbox "$msg" 12 "$PKS_DLG_WIDTH" 2>/dev/null
    fi
    printf '%s: %s\n' "$PKS_NAME" "$msg" >&2
    exit 1
}

# require_root - abort unless running as uid 0.
require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        die "Root privileges are required. Re-run it as root."
    fi
}

# need_cmd CMD... - verify each command exists, otherwise abort.
need_cmd() {
    local missing=()
    local c
    for c in "$@"; do
        command -v "$c" >/dev/null 2>&1 || missing+=("$c")
    done
    if [ "${#missing[@]}" -gt 0 ]; then
        die "Missing required command(s): ${missing[*]}"
    fi
}

# ensure_work_dir - create the scratch directory used for downloads/builds.
ensure_work_dir() {
    mkdir -p "$PKS_WORK_DIR" || die "Cannot create work directory: $PKS_WORK_DIR"
    chmod 700 "$PKS_WORK_DIR" 2>/dev/null || true
}

# version_base VERSION - strip the Pardus/arch suffix, leaving the upstream
# numeric version. "7.0.12+pardus25-amd64" -> "7.0.12".
version_base() {
    printf '%s\n' "${1%%+*}"
}
