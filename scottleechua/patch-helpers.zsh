#!/bin/zsh

# Shared helpers for the Portal and SodoSearch customization scripts. Source this file; do not run it.

# Run a command that edits a file in place, and fail if the file comes out unchanged.
# Upstream reformats Portal's source from time to time, and a patch whose anchor
# no longer matches would otherwise be skipped silently.
#
# Usage: apply_patch <description> <file> <command> [args...]
# The file path is appended as the last argument of the command.
apply_patch() {
    local description="$1"
    local file="$2"
    shift 2

    if [ ! -f "$file" ]; then
        echo "Error: patch target not found: $description"
        echo "       $file"
        exit 1
    fi

    local before="$(cksum < "$file")"
    "$@" "$file"

    if [ "$(cksum < "$file")" = "$before" ]; then
        echo "Error: patch did not apply: $description"
        echo "       $file"
        exit 1
    fi
}
