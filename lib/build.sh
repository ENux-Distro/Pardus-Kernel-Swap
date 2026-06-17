#!/usr/bin/env bash
#
# build.sh - Custom kernel build subsystem.
#
# Downloads an upstream kernel source tarball, extracts it, builds Debian
# packages with `make bindeb-pkg`, and hands the resulting .deb files back to
# the installer. The full build log is preserved for inspection on failure.

[ -n "${PKS_BUILD_SOURCED:-}" ] && return 0
PKS_BUILD_SOURCED=1

PKS_BUILD_LOCALVERSION="+pardus25-amd64"

# build_log_path - location of the most recent build log.
build_log_path() {
    printf '%s/build.log' "$PKS_WORK_DIR"
}

# build_custom URL
#
# Runs the full custom-kernel pipeline. All heavy output goes to the build log
# (build_log_path). Returns:
#   0 - .deb packages built; their directory is printed on stdout
#   1 - failure at some stage (download/extract/build); log holds details
build_custom() {
    local url="$1"
    ensure_work_dir
    local log; log="$(build_log_path)"
    : >"$log"

    local srcdir="$PKS_WORK_DIR/custom-src"
    rm -rf "$srcdir"
    mkdir -p "$srcdir"

    # --- 1. Download ---------------------------------------------------------
    local tarball="$PKS_WORK_DIR/custom-source.tar.xz"
    log_event "Custom build: downloading source" "$url"
    if ! dl_fetch "$url" "$tarball"; then
        echo "ERROR: failed to download source archive." | tee -a "$log" >&2
        return 1
    fi

    # --- 2. Extract ----------------------------------------------------------
    log_event "Custom build: extracting source"
    {
        echo ">>> Extracting $tarball"
        tar --extract --file "$tarball" --directory "$srcdir" --strip-components=1
    } >>"$log" 2>&1
    if [ "${PIPESTATUS[0]:-0}" -ne 0 ] && ! [ -f "$srcdir/Makefile" ]; then
        # Re-check explicitly: a stripped extract should yield a Makefile.
        if [ ! -f "$srcdir/Makefile" ]; then
            echo "ERROR: extraction failed or archive layout unexpected." | tee -a "$log" >&2
            return 1
        fi
    fi

    # --- 3. Configure --------------------------------------------------------
    # Seed configuration from the running kernel when possible, otherwise a
    # sane default config. This keeps the build non-interactive.
    log_event "Custom build: preparing .config"
    {
        if [ -r "/boot/config-$(uname -r)" ]; then
            echo ">>> Seeding .config from /boot/config-$(uname -r)"
            cp "/boot/config-$(uname -r)" "$srcdir/.config"
            make -C "$srcdir" olddefconfig
        else
            echo ">>> No running config found; using defconfig"
            make -C "$srcdir" defconfig
        fi
    } >>"$log" 2>&1 || {
        echo "ERROR: kernel configuration step failed." | tee -a "$log" >&2
        return 1
    }

    # --- 4. Build ------------------------------------------------------------
    log_event "Custom build: compiling (make bindeb-pkg)"
    {
        echo ">>> make bindeb-pkg -j$(nproc) LOCALVERSION=$PKS_BUILD_LOCALVERSION"
        make -C "$srcdir" bindeb-pkg -j"$(nproc)" LOCALVERSION="$PKS_BUILD_LOCALVERSION"
    } >>"$log" 2>&1
    if [ "$?" -ne 0 ]; then
        echo "ERROR: kernel build failed. See build log for details." | tee -a "$log" >&2
        return 1
    fi

    # --- 5. Locate .deb packages --------------------------------------------
    # bindeb-pkg drops packages in the parent of the source tree.
    local debdir="$PKS_WORK_DIR"
    if ! ls "$debdir"/linux-image-*.deb >/dev/null 2>&1; then
        echo "ERROR: build reported success but no linux-image .deb found." | tee -a "$log" >&2
        return 1
    fi

    log_event "Custom build: packages ready" "$debdir"
    printf '%s\n' "$debdir"
    return 0
}

# build_list_debs DIR - print the freshly built image/header .deb paths.
build_list_debs() {
    local dir="$1"
    ls "$dir"/linux-image-*.deb "$dir"/linux-headers-*.deb 2>/dev/null
}
