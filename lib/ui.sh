#!/usr/bin/env bash
#
# ui.sh - Thin whiptail wrappers giving the application a consistent,
# classic UNIX administration look. All dialogs share a common title bar.

[ -n "${PKS_UI_SOURCED:-}" ] && return 0
PKS_UI_SOURCED=1

_ui_title() {
    printf '%s' "$PKS_NAME"
}

# ui_msg TEXT [HEIGHT] - informational message box with an [ OK ] button.
ui_msg() {
    local text="$1"
    local height="${2:-14}"
    whiptail --title "$(_ui_title)" --msgbox "$text" "$height" "$PKS_DLG_WIDTH"
}

# ui_yesno TEXT [YESLABEL] [NOLABEL] [HEIGHT] - returns 0 on confirm, 1 on
# cancel. Defaults match an install/cancel decision.
ui_yesno() {
    local text="$1"
    local yes="${2:-Install}"
    local no="${3:-Cancel}"
    local height="${4:-16}"
    whiptail --title "$(_ui_title)" \
        --yes-button "$yes" --no-button "$no" \
        --yesno "$text" "$height" "$PKS_DLG_WIDTH"
}

# ui_input TEXT [DEFAULT] - prompt for a single line. Echoes the value on
# stdout; returns non-zero if the user cancels.
ui_input() {
    local text="$1"
    local default="${2:-}"
    whiptail --title "$(_ui_title)" \
        --inputbox "$text" 12 "$PKS_DLG_WIDTH" "$default" 3>&1 1>&2 2>&3
}

# ui_menu TEXT TAG1 ITEM1 [TAG2 ITEM2 ...] - present a menu. Echoes the chosen
# tag on stdout; returns non-zero if the user cancels.
ui_menu() {
    local text="$1"
    shift
    local count=$(( $# / 2 ))
    whiptail --title "$(_ui_title)" \
        --ok-button "Select" --cancel-button "Quit" \
        --menu "$text" "$PKS_DLG_HEIGHT" "$PKS_DLG_WIDTH" "$count" \
        "$@" 3>&1 1>&2 2>&3
}

# ui_gauge_cmd TEXT CMD... - run CMD which is expected to emit integer
# percentages (0-100) on stdout, piping them into a whiptail progress gauge.
ui_gauge_cmd() {
    local text="$1"
    shift
    "$@" | whiptail --title "$(_ui_title)" --gauge "$text" 8 "$PKS_DLG_WIDTH" 0
}

# ui_textbox_file TITLE FILE - scrollable view of a file (e.g. build log).
ui_textbox_file() {
    local title="$1"
    local file="$2"
    whiptail --title "$title" --scrolltext \
        --textbox "$file" "$PKS_DLG_HEIGHT" "$PKS_DLG_WIDTH"
}
