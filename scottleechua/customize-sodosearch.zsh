#!/bin/zsh

# Parse command line arguments
FONT_FAMILY=""
PLACEHOLDER_STRING=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --font-family) FONT_FAMILY="$2"; shift ;;
        --placeholder-string) PLACEHOLDER_STRING="$2"; shift ;;
        *) break ;;
    esac
    shift
done

# Check if all required arguments are provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 [--font-family <font-family>] [--placeholder-string <text>] <path_to_theme>"
    echo "  --font-family         Set font family (e.g., 'Arial, sans-serif')"
    echo "  --placeholder-string  Set placeholder text (e.g., 'Search...')"
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

# Get Sodosearch version
SODOSEARCH_VERSION=$(jq -r '.version' "$GHOST_ROOT/apps/sodo-search/package.json")
echo "=== Customize Sodosearch ==="
echo "Sodosearch version: $SODOSEARCH_VERSION"

# Edit styles if font-family is provided
if [ ! -z "$FONT_FAMILY" ]; then
    echo "Editing styles..."
    
    # Add font-family to the body block (avoids Tailwind v3.4+ :host,html specificity issue)
    sed -i '' '/^body {/a\
    font-family: '"$FONT_FAMILY"';\
' "$GHOST_ROOT/apps/sodo-search/src/index.css"
fi

# Temporarily slim sodo-search's i18n bundle to English only.
# As of sodo-search 1.8.3x, locales are loaded through a static ESM registry
# (@tryghost/i18n/registry/search) that globs every locale via import.meta.glob,
# instead of the old vite.config.mjs `dynamicRequireTargets` hack. Narrow that
# glob to `en` so only English is bundled. Restored via git at cleanup.
echo "Slimming sodo-search i18n registry to English-only translations..."
SODOSEARCH_I18N_REGISTRY="$GHOST_ROOT/packages/i18n/lib/registry/search.mjs"
sed -i '' "s|locales/\*/search.json|locales/en/search.json|" "$SODOSEARCH_I18N_REGISTRY"

echo "Build started..."

# Run pnpm build
(cd "$GHOST_ROOT/apps/sodo-search" && pnpm build)

echo "Build completed."

# Replace placeholder text in the built JS file if provided
if [ ! -z "$PLACEHOLDER_STRING" ]; then
    echo "Replacing placeholder text in built JS file..."
    # Create a temporary file for the replacement
    cp "$GHOST_ROOT/apps/sodo-search/umd/sodo-search.min.js" "${GHOST_ROOT/apps/sodo-search/umd/sodo-search.min.js}.tmp"
    # Replace the text in the temporary file
    sed -i '' "s/Search posts, tags and authors/$PLACEHOLDER_STRING/g" "${GHOST_ROOT/apps/sodo-search/umd/sodo-search.min.js}.tmp"
    # Move the temporary file back
    mv "${GHOST_ROOT/apps/sodo-search/umd/sodo-search.min.js}.tmp" "$GHOST_ROOT/apps/sodo-search/umd/sodo-search.min.js"
fi

# Copy sodosearch.min.js to specified theme directory
cp "$GHOST_ROOT/apps/sodo-search/umd/sodo-search.min.js" "$HOME/$THEME_PATH/"
echo "Copied JS to $THEME_PATH/sodo-search.min.js."

cp "$GHOST_ROOT/apps/sodo-search/umd/main.css" "$HOME/$THEME_PATH/sodo-search-main.css"
echo "Copied CSS to $THEME_PATH/sodo-search-main.css."

# Check if version needs to be updated
CURRENT_VERSION=$(cat "$HOME/$THEME_PATH/SODOSEARCH-VERSION" 2>/dev/null || echo "")
if [ "$CURRENT_VERSION" != "$SODOSEARCH_VERSION" ]; then
    echo "$SODOSEARCH_VERSION" > "$HOME/$THEME_PATH/SODOSEARCH-VERSION"
    echo "Bumped $THEME_PATH/SODOSEARCH-VERSION to v$SODOSEARCH_VERSION"
else
    echo "Sodosearch already up to date."
fi

echo "Cleaning up changes..."

# Restore all modified files to their original state using Git
(cd "$GHOST_ROOT/apps/sodo-search" && git restore .)
# The i18n registry lives outside apps/sodo-search, so restore it explicitly
(cd "$GHOST_ROOT" && git restore packages/i18n/lib/registry/search.mjs)

echo "Done!"
echo ""