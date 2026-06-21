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
    printf '%s\n%s\n' "custom" "$(t custom_menu_label)"
}

# kernel_catalog_description ID - build the multi-line description block shown
# before installation. Works for catalog ids; "custom" is handled by the
# build module, so this returns the static custom blurb for that id.
kernel_catalog_description() {
    local id="$1"
    if [ "$id" = "custom" ]; then
        t custom_desc
        return 0
    fi

    # Localized fields fall back to the base field when no translation exists.
    local sfx=""
    [ "$PKS_LANG" = "tr" ] && sfx="_tr"

    local label version summary
    label="$(kernel_catalog_field "$id" label)"
    version="$(kernel_catalog_field "$id" version)"
    summary="$(jq -r --arg id "$id" --arg f "summary$sfx" \
        '.kernels[] | select(.id==$id) | (.[$f] // .summary)' "$PKS_KERNEL_DB")"

    printf '%s\n\n%s\n\n%s\n\n' "$label" "$version" "$summary"
    printf '%s\n' "$(t adv_label)"
    jq -r --arg id "$id" --arg f "advantages$sfx" \
        '.kernels[] | select(.id==$id) | ((.[$f] // .advantages)[]) | "  * \(.)"' "$PKS_KERNEL_DB"
    printf '\n%s\n' "$(t disadv_label)"
    jq -r --arg id "$id" --arg f "disadvantages$sfx" \
        '.kernels[] | select(.id==$id) | ((.[$f] // .disadvantages)[]) | "  * \(.)"' "$PKS_KERNEL_DB"
}
