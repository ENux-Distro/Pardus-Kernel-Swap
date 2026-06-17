#!/usr/bin/env bash
#
# install.sh - Installation subsystem for predefined .deb kernel packages.
#
# Responsibilities: install a downloaded package, refresh the bootloader, and
# report (never perform) the required reboot. All steps log and fail safely.

[ -n "${PKS_INSTALL_SOURCED:-}" ] && return 0
PKS_INSTALL_SOURCED=1

# install_deb FILE - install a .deb, resolving dependencies. Echoes errors to
# stdout (captured by the caller for display) and returns non-zero on failure.
install_deb() {
    local file="$1"
    [ -r "$file" ] || { echo "Package not readable: $file"; return 1; }

    log_event "Installing package" "$file"
    # Prefer apt for dependency resolution; fall back to dpkg + apt-fix.
    if command -v apt-get >/dev/null 2>&1; then
        if apt-get install -y --no-install-recommends "$file" 2>&1; then
            log_event "Kernel installed successfully" "$file"
            return 0
        fi
    fi

    if dpkg -i "$file" 2>&1; then
        log_event "Kernel installed successfully" "$file"
        return 0
    fi

    # dpkg may have left unmet deps; try to repair.
    if command -v apt-get >/dev/null 2>&1; then
        echo "Resolving dependencies..."
        if apt-get install -y -f 2>&1; then
            log_event "Kernel installed successfully (after dep fix)" "$file"
            return 0
        fi
    fi

    log_error "Package installation failed: $file"
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
