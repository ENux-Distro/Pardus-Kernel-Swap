#!/usr/bin/env bash
#
# log.sh - Logging subsystem for Pardus Kernel Swap.
#
# All log lines are timestamped and appended to $PKS_LOG_FILE. Logging never
# aborts the program: if the log file cannot be written we fall back to stderr
# so the application keeps working even on a read-only or unusual system.

[ -n "${PKS_LOG_SOURCED:-}" ] && return 0
PKS_LOG_SOURCED=1

# log_init - prepare the log file. Called once at startup.
log_init() {
    local dir
    dir="$(dirname "$PKS_LOG_FILE")"
    if ! mkdir -p "$dir" 2>/dev/null; then
        return 0
    fi
    # Touch the file; ignore failure (handled per-write in _log_write).
    touch "$PKS_LOG_FILE" 2>/dev/null || true
    chmod 600 "$PKS_LOG_FILE" 2>/dev/null || true
}

# _log_write LEVEL MESSAGE - internal; format and append one record.
_log_write() {
    local level="$1"
    shift
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    local line="[$ts] [$level] $*"
    if ! printf '%s\n' "$line" >>"$PKS_LOG_FILE" 2>/dev/null; then
        printf '%s\n' "$line" >&2
    fi
}

log_info()    { _log_write "INFO"  "$@"; }
log_warn()    { _log_write "WARN"  "$@"; }
log_error()   { _log_write "ERROR" "$@"; }

# log_event TITLE [DETAIL...] - convenience for the multi-line style shown in
# the spec, e.g.  log_event "Detected kernel" "7.0.12+pardus25-amd64".
log_event() {
    local title="$1"
    shift
    if [ "$#" -gt 0 ]; then
        _log_write "INFO" "$title: $*"
    else
        _log_write "INFO" "$title"
    fi
}
