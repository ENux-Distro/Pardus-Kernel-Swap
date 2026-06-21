#!/usr/bin/env bash
#
# cve.sh - CVE detection layer.
#
# The database lives in data/cve.json (see that file for the schema). The
# matching rule for a kernel base version V and an entry E is:
#
#     E.introduced <= V  AND  (E.fixed is null OR V < E.fixed)
#
# Version comparison uses dpkg --compare-versions, which understands the
# upstream numeric kernel versions we feed it. This layer is deliberately
# self-contained so an online updater can later just replace cve.json.

[ -n "${PKS_CVE_SOURCED:-}" ] && return 0
PKS_CVE_SOURCED=1

# _ver_lt A B  -> true if A < B
_ver_lt() { dpkg --compare-versions "$1" lt "$2"; }
# _ver_ge A B  -> true if A >= B
_ver_ge() { dpkg --compare-versions "$1" ge "$2"; }

# cve_db_date - print the 'updated' date of the loaded database.
cve_db_date() {
    jq -r '.updated // "unknown"' "$PKS_CVE_DB" 2>/dev/null
}

# cve_check VERSION
#
# Examines the given kernel version (full Pardus string is fine; the base
# version is extracted internally) against the database. Prints one matching
# CVE per line in the form:
#
#     ID<TAB>SEVERITY<TAB>DESCRIPTION<TAB>RECOMMENDATION
#
# Exit status:
#   0 - at least one matching CVE printed
#   1 - no matching CVEs
#   2 - database missing or unreadable
cve_check() {
    local version base
    version="$1"
    base="$(version_base "$version")"

    if [ ! -r "$PKS_CVE_DB" ]; then
        log_error "CVE database not readable: $PKS_CVE_DB"
        return 2
    fi

    # Pull candidate rows from JSON; do range maths in bash via dpkg so the
    # comparison semantics are identical to the rest of the tool.
    local found=1
    local id sev intro fixed desc rec
    while IFS=$'\t' read -r id sev intro fixed desc rec; do
        [ -n "$id" ] || continue
        # introduced bound
        _ver_ge "$base" "$intro" || continue
        # fixed bound (null/empty means never fixed)
        if [ -n "$fixed" ] && [ "$fixed" != "null" ]; then
            _ver_lt "$base" "$fixed" || continue
        fi
        printf '%s\t%s\t%s\t%s\n' "$id" "$sev" "$desc" "$rec"
        found=0
    done < <(jq -r --arg sfx "$([ "${PKS_LANG:-en}" = tr ] && echo _tr)" \
        '.cves[] | [.id, .severity, .introduced, (.fixed // "null"),
                    (.["description"+$sfx] // .description),
                    (.["recommendation"+$sfx] // .recommendation)] | @tsv' "$PKS_CVE_DB")

    return $found
}

# cve_report VERSION
#
# Convenience wrapper that returns a human-readable multi-line report on
# stdout. Returns 0 if vulnerabilities were found, 1 if clean, 2 on db error.
cve_report() {
    local version="$1"
    local out rc
    out="$(cve_check "$version")"
    rc=$?

    if [ "$rc" -eq 2 ]; then
        printf '%s\n' "$(t cve_db_unavail)"
        return 2
    fi
    if [ "$rc" -eq 1 ]; then
        printf '%s\n' "$(t cve_clean)"
        return 1
    fi

    local id sev desc rec rec_label
    rec_label="$(t cve_recommend_label)"
    while IFS=$'\t' read -r id sev desc rec; do
        printf '%s  [%s]\n  %s\n  %s: %s\n\n' "$id" "$sev" "$desc" "$rec_label" "$rec"
    done <<<"$out"
    return 0
}
