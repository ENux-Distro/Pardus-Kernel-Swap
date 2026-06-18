#!/usr/bin/env bash
#
# install.sh - Installation subsystem for predefined .deb kernel packages.
#
# Responsibilities: install a downloaded package, refresh the bootloader, and
# report (never perform) the required reboot. All steps log and fail safely.

[ -n "${PKS_INSTALL_SOURCED:-}" ] && return 0
PKS_INSTALL_SOURCED=1

# install_deb FILE... - install one or more .deb files together, resolving
# dependencies. Passing the image and headers in a single call lets apt sort
# out inter-package and external dependencies in one transaction regardless of
# order. Echoes errors to stdout (captured by the caller for display) and
# returns non-zero on failure.
install_deb() {
    local files=("$@")
    [ "${#files[@]}" -gt 0 ] || { echo "No packages to install"; return 1; }

    local f
    for f in "${files[@]}"; do
        [ -r "$f" ] || { echo "Package not readable: $f"; return 1; }
    done

    log_event "Installing packages" "${files[*]}"
    # Prefer apt for dependency resolution; fall back to dpkg + apt-fix.
    if command -v apt-get >/dev/null 2>&1; then
        if apt-get install -y --no-install-recommends "${files[@]}" 2>&1; then
            log_event "Kernel installed successfully" "${files[*]}"
            return 0
        fi
    fi

    if dpkg -i "${files[@]}" 2>&1; then
        log_event "Kernel installed successfully" "${files[*]}"
        return 0
    fi

    # dpkg may have left unmet deps; try to repair.
    if command -v apt-get >/dev/null 2>&1; then
        echo "Resolving dependencies..."
        if apt-get install -y -f 2>&1; then
            log_event "Kernel installed successfully (after dep fix)" "${files[*]}"
            return 0
        fi
    fi

    log_error "Package installation failed: ${files[*]}"
    return 1
}

# bootloader_update - regenerate bootloader config if a generator is present.
# Returns 0 even when nothing needs doing; only a real failure returns 1.
bootloader_update() {
    if command -v update-grub >/dev/null 2>&1; then
        log_event "Updating bootloader" "update-grub"
        update-grub 2>&1 && return 0
        log_error "update-grub failed"
        return 1
    fi
    if command -v grub-mkconfig >/dev/null 2>&1; then
        log_event "Updating bootloader" "grub-mkconfig"
        grub-mkconfig -o /boot/grub/grub.cfg 2>&1 && return 0
        log_error "grub-mkconfig failed"
        return 1
    fi
    log_warn "No bootloader generator found; skipping bootloader update"
    return 0
}
