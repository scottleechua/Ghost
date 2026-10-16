#!/bin/zsh

# Check that every Portal and SodoSearch customization still applies to the
# current upstream source and still builds. Runs both customize scripts with
# every option in --check mode, which copies nothing to a theme. Each script
# restores the source files when it exits.
#
# Usage: ./check-patches.zsh [<output_dir>]
# If <output_dir> is given, the patched source of each app is saved there as
# portal-patched.diff and sodo-search-patched.diff, and the build logs as *.log.
#
# Run it after syncing the fork. .github/workflows/portal-contract-check.yml
# also runs it against upstream Ghost.

SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
OUT="${1:-}"
[ -n "$OUT" ] && mkdir -p "$OUT" && OUT="$(cd "$OUT" && pwd)"

FAILED=()

# Run one customize script. Without an output directory, show its log here.
run_check() {
    local name="$1"
    shift
    echo "=== Check $name ==="
    if [ -n "$OUT" ]; then
        PATCH_DIFF="$OUT/$name-patched.diff" "$@" > "$OUT/$name.log" 2>&1
    else
        "$@"
    fi
    local result=$?
    if [ $result -eq 0 ]; then
        echo "PASS: $name"
    else
        echo "FAIL: $name"
        [ -n "$OUT" ] && grep -A1 '^Error' "$OUT/$name.log"
        FAILED+=("$name")
    fi
}

run_check portal "$SCRIPTS/customize-portal.zsh" \
    --placeholder-name "Contract Check" \
    --placeholder-email "check@example.com" \
    --hide-already-member \
    --hide-site-title \
    --hide-powered-by-ghost \
    --replace-icon-with-logo \
    --enable-dark-mode \
    --custom-accents "#ff0000" "#ffffff" "#cc0000" "#ffffff" \
    --check

run_check sodo-search "$SCRIPTS/customize-sodosearch.zsh" \
    --font-family "Arial, sans-serif" \
    --placeholder-string "Search..." \
    --check

if [ ${#FAILED[@]} -gt 0 ]; then
    echo "Failed: ${FAILED[*]}"
    exit 1
fi
echo "All patches applied and built."
