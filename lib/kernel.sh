#!/usr/bin/env bash
#
# kernel.sh - Running-kernel detection and the predefined kernel catalog.

[ -n "${PKS_KERNEL_SOURCED:-}" ] && return 0
PKS_KERNEL_SOURCED=1

# kernel_current - print the running kernel release string (uname -r).
kernel_current() {
    uname -r
}

# kernel_catalog_field ID FIELD - print a scalar field for a catalog entry.
kernel_catalog_field() {
    local id="$1" field="$2"
    jq -r --arg id "$id" --arg f "$field" \
        '.kernels[] | select(.id==$id) | .[$f] // empty' "$PKS_KERNEL_DB"
}

# kernel_catalog_version ID - print the version string for a catalog entry.
kernel_catalog_version() {
    kernel_catalog_field "$1" "version"
}

# kernel_catalog_menu_args - emit "tag label" pairs for ui_menu, in catalog
# order, with the Custom option appended last.
kernel_catalog_menu_args() {
    jq -r '.kernels[] | "\(.id)\t\(.label)  (\(.version))"' "$PKS_KERNEL_DB" \
    | while IFS=$'\t' read -r id label; do
        printf '%s\n%s\n' "$id" "$label"
    done
    printf '%s\n%s\n' "custom" "Custom  (user-provided kernel source)"
}

# kernel_catalog_description ID - build the multi-line description block shown
# before installation. Works for catalog ids; "custom" is handled by the
# build module, so this returns the static custom blurb for that id.
kernel_catalog_description() {
    local id="$1"
    if [ "$id" = "custom" ]; then
        cat <<'EOF'
Custom

User compiles their own kernel source.

Advantages:
  * complete control

Disadvantages:
  * compilation time
  * advanced knowledge required
EOF
        return 0
    fi

    local label version summary
    label="$(kernel_catalog_field "$id" label)"
    version="$(kernel_catalog_field "$id" version)"
    summary="$(kernel_catalog_field "$id" summary)"

    printf '%s\n\n%s\n\n%s\n\n' "$label" "$version" "$summary"
    printf 'Advantages:\n'
    jq -r --arg id "$id" '.kernels[] | select(.id==$id) | .advantages[] | "  * \(.)"' "$PKS_KERNEL_DB"
    printf '\nDisadvantages:\n'
    jq -r --arg id "$id" '.kernels[] | select(.id==$id) | .disadvantages[] | "  * \(.)"' "$PKS_KERNEL_DB"
}
