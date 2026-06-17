#!/usr/bin/env bash
#
# download.sh - Download subsystem.
#
# Wraps curl/wget so the rest of the application has one place to fetch URLs,
# with progress reporting suitable for a whiptail gauge and graceful failure.

[ -n "${PKS_DOWNLOAD_SOURCED:-}" ] && return 0
PKS_DOWNLOAD_SOURCED=1

# dl_url_for_kernel VERSION - compose the release download URL for a
# predefined kernel version.
dl_url_for_kernel() {
    printf '%s/%s%s' "$PKS_RELEASE_BASE_URL" "$1" "$PKS_PACKAGE_SUFFIX"
}

# _dl_have - pick an available downloader; echoes "curl" or "wget".
_dl_have() {
    if command -v curl >/dev/null 2>&1; then
        printf 'curl'
    elif command -v wget >/dev/null 2>&1; then
        printf 'wget'
    else
        return 1
    fi
}

# dl_fetch URL DEST - download URL to DEST quietly. Returns non-zero on any
# failure (network, HTTP error, write error). Logs the outcome.
dl_fetch() {
    local url="$1" dest="$2" tool rc
    tool="$(_dl_have)" || { log_error "No downloader (curl/wget) available"; return 1; }

    log_event "Download started" "$url"
    if [ "$tool" = "curl" ]; then
        curl --fail --location --silent --show-error --output "$dest" "$url"
        rc=$?
    else
        wget --quiet --output-document="$dest" "$url"
        rc=$?
    fi

    if [ "$rc" -ne 0 ] || [ ! -s "$dest" ]; then
        rm -f "$dest" 2>/dev/null
        log_error "Download failed ($tool rc=$rc): $url"
        return 1
    fi
    log_event "Download complete" "$dest"
    return 0
}

# dl_fetch_gauge URL DEST - emits percentage lines on stdout for ui_gauge_cmd.
# Falls back to indeterminate 0/100 markers when curl progress is unavailable.
dl_fetch_gauge() {
    local url="$1" dest="$2"
    if command -v curl >/dev/null 2>&1; then
        # curl writes a progress bar to stderr; we parse the percentage.
        log_event "Download started" "$url"
        # shellcheck disable=SC2094
        stdbuf -oL curl --fail --location --output "$dest" "$url" 2>&1 \
            | stdbuf -oL tr '\r' '\n' \
            | grep --line-buffered -oE '[0-9]+\.[0-9]+%' \
            | sed -u 's/\..*//' \
            || true
        # Ensure the gauge closes at 100 on success.
        if [ -s "$dest" ]; then
            echo 100
            log_event "Download complete" "$dest"
        else
            log_error "Download failed: $url"
        fi
        return 0
    fi
    # No curl: just bracket a blocking wget call.
    echo 0
    dl_fetch "$url" "$dest" >/dev/null 2>&1
    echo 100
}
