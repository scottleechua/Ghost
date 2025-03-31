#!/bin/zsh

# Check if all required arguments are provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path_to_theme>"
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
if [ ! -d "$GHOST_ROOT/apps/portal" ]; then
    echo "Error: Could not find Ghost root directory. Please run this script from the Ghost repository."
    exit 1
fi

# Get Sodosearch version
SODOSEARCH_VERSION=$(jq -r '.version' "$GHOST_ROOT/apps/sodo-search/package.json")
echo "Sodosearch version: $SODOSEARCH_VERSION"

echo "Build started..."

# Run yarn build
(cd "$GHOST_ROOT/apps/sodo-search" && yarn build)

echo "Build completed."

# Copy sodosearch.min.js to specified theme directory
cp "$GHOST_ROOT/apps/sodo-search/umd/sodo-search.min.js" "$HOME/$THEME_PATH/"
echo "Copied JS to $THEME_PATH/sodo-search.min.js."

cp "$GHOST_ROOT/apps/sodo-search/umd/main.css" "$HOME/$THEME_PATH/sodo-search-main.css"
echo "Copied CSS to $THEME_PATH/sodo-search-main.css."

echo "$SODOSEARCH_VERSION" > "$HOME/$THEME_PATH/SODOSEARCH-VERSION"

echo "Done!"
