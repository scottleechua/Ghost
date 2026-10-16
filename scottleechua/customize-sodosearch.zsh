#!/bin/zsh

# Parse command line arguments
FONT_FAMILY=""
PLACEHOLDER_STRING=""
CHECK=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --font-family) FONT_FAMILY="$2"; shift ;;
        --placeholder-string) PLACEHOLDER_STRING="$2"; shift ;;
        --check) CHECK=true ;;
        *) break ;;
    esac
    shift
done

# Check if all required arguments are provided. With --check, there is no theme path.
if { [ "$CHECK" = true ] && [ "$#" -ne 0 ]; } || { [ "$CHECK" != true ] && [ "$#" -ne 1 ]; }; then
    echo "Usage: $0 [--font-family <font-family>] [--placeholder-string <text>] (<path_to_theme> | --check)"
    echo "  --font-family         Set font family (e.g., 'Arial, sans-serif')"
    echo "  --placeholder-string  Set placeholder text (e.g., 'Search...')"
    echo "  --check               Apply the patches and build, but do not copy to a theme"
    exit 1
fi

THEME_PATH=$1

# Get the absolute path of the Ghost root directory
if [ -f "$0" ]; then
    # If script is called directly
    GHOST_ROOT="$(cd "$(dirname "$(dirname "$0")")" && pwd)"
else
    # If script is sourced
    GHOST_ROOT="$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)"
fi

# Verify we're in the correct directory
if [ ! -d "$GHOST_ROOT/apps/sodo-search" ]; then
    echo "Error: Could not find Ghost root directory. Please run this script from the Ghost repository."
    exit 1
fi

source "$GHOST_ROOT/scottleechua/patch-helpers.zsh" || exit 1

SODOSEARCH="$GHOST_ROOT/apps/sodo-search"
SODOSEARCH_I18N_REGISTRY="$GHOST_ROOT/packages/i18n/src/registry/search.ts"
SODOSEARCH_JS="$SODOSEARCH/umd/sodo-search.min.js"

# Restore all modified source files to their original state using Git.
# Runs on every exit, so a failed patch or build does not leave the source modified.
restore_sources() {
    echo "Cleaning up changes..."
    (cd "$SODOSEARCH" && git restore .)
    # The i18n registry lives outside apps/sodo-search, so restore it explicitly
    (cd "$GHOST_ROOT" && git restore "$SODOSEARCH_I18N_REGISTRY")
}
trap restore_sources EXIT

# Get Sodosearch version
SODOSEARCH_VERSION=$(jq -r '.version' "$SODOSEARCH/package.json")
echo "=== Customize Sodosearch ==="
echo "Sodosearch version: $SODOSEARCH_VERSION"

# Edit styles if font-family is provided
if [ ! -z "$FONT_FAMILY" ]; then
    echo "Editing styles..."

    # Add font-family to the body block (avoids Tailwind v3.4+ :host,html specificity issue)
    FONT_FAMILY="$FONT_FAMILY" apply_patch "Add font family to body" "$SODOSEARCH/src/index.css" \
        perl -pi -e 's/^(body \{)$/$1\n    font-family: $ENV{FONT_FAMILY};/'
fi

# Temporarily slim sodo-search's i18n bundle to English only.
# Locales are loaded through a static registry (@tryghost/i18n/registry/search)
# that globs every locale via import.meta.glob. Narrow that glob to `en` so only
# English is bundled. Restored via git at cleanup.
echo "Slimming sodo-search i18n registry to English-only translations..."
apply_patch "Slim i18n registry to English only" "$SODOSEARCH_I18N_REGISTRY" \
    sed -i '' "s|locales/\*/search.json|locales/en/search.json|"

# In check mode, keep the patched source as a diff, to review where each patch landed
if [ "$CHECK" = true ] && [ -n "$PATCH_DIFF" ]; then
    (cd "$GHOST_ROOT" && git diff -- apps/sodo-search "$SODOSEARCH_I18N_REGISTRY") > "$PATCH_DIFF"
fi

echo "Build started..."

# Run pnpm build
if ! (cd "$SODOSEARCH" && pnpm build); then
    echo "Error: SodoSearch build failed"
    exit 1
fi

echo "Build completed."

# Replace placeholder text in the built JS file if provided.
# The build output is git-ignored, so this is not restored; the next build replaces it.
if [ ! -z "$PLACEHOLDER_STRING" ]; then
    echo "Replacing placeholder text in built JS file..."
    PLACEHOLDER_STRING="$PLACEHOLDER_STRING" apply_patch "Replace search placeholder" "$SODOSEARCH_JS" \
        perl -pi -e 's/Search posts, tags and authors/$ENV{PLACEHOLDER_STRING}/g'
fi

if [ "$CHECK" = true ]; then
    echo "Check passed: every patch applied and SodoSearch built."
    exit 0
fi

# Copy sodosearch.min.js to specified theme directory
cp "$SODOSEARCH_JS" "$HOME/$THEME_PATH/"
echo "Copied JS to $THEME_PATH/sodo-search.min.js."

cp "$SODOSEARCH/umd/main.css" "$HOME/$THEME_PATH/sodo-search-main.css"
echo "Copied CSS to $THEME_PATH/sodo-search-main.css."

# Check if version needs to be updated
CURRENT_VERSION=$(cat "$HOME/$THEME_PATH/SODOSEARCH-VERSION" 2>/dev/null || echo "")
if [ "$CURRENT_VERSION" != "$SODOSEARCH_VERSION" ]; then
    echo "$SODOSEARCH_VERSION" > "$HOME/$THEME_PATH/SODOSEARCH-VERSION"
    echo "Bumped $THEME_PATH/SODOSEARCH-VERSION to v$SODOSEARCH_VERSION"
else
    echo "Sodosearch already up to date."
fi

echo "Done!"
echo ""
