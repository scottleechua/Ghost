#!/bin/zsh

# Parse command line arguments
PLACEHOLDER_NAME=""
PLACEHOLDER_EMAIL=""
HIDE_ALREADY_MEMBER=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --placeholder-name) PLACEHOLDER_NAME="$2"; shift ;;
        --placeholder-email) PLACEHOLDER_EMAIL="$2"; shift ;;
        --hide-already-member) HIDE_ALREADY_MEMBER=true ;;
        *) break ;;
    esac
    shift
done

# Check if all required arguments are provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 [--placeholder-name <name>] [--placeholder-email <email>] [--hide-already-member] <path_to_theme>"
    echo "  --placeholder-name    Set placeholder name (e.g., 'John Doe')"
    echo "  --placeholder-email   Set placeholder email (e.g., 'john@example.com')"
    echo "  --hide-already-member  Hide the 'Already a member?' message"
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

# Get Portal version
PORTAL_VERSION=$(jq -r '.version' "$GHOST_ROOT/apps/portal/package.json")
echo "=== Customize Portal ==="
echo "Portal version: $PORTAL_VERSION"

# Replace name placeholder in all files
if [ ! -z "$PLACEHOLDER_NAME" ]; then
    sed -i '' "s/Jamie Larson/$PLACEHOLDER_NAME/g" "$GHOST_ROOT/apps/portal/src/components/pages/AccountProfilePage.js"
    sed -i '' "s/Jamie Larson/$PLACEHOLDER_NAME/g" "$GHOST_ROOT/apps/portal/src/components/pages/OfferPage.js"
    sed -i '' "s/Jamie Larson/$PLACEHOLDER_NAME/g" "$GHOST_ROOT/apps/portal/src/components/pages/SignupPage.js"
fi

# Replace email placeholder in all files
if [ ! -z "$PLACEHOLDER_EMAIL" ]; then
    sed -i '' "s/jamie@example.com/$PLACEHOLDER_EMAIL/g" "$GHOST_ROOT/apps/portal/src/components/pages/AccountProfilePage.js"
    sed -i '' "s/jamie@example.com/$PLACEHOLDER_EMAIL/g" "$GHOST_ROOT/apps/portal/src/components/pages/OfferPage.js"
    sed -i '' "s/jamie@example.com/$PLACEHOLDER_EMAIL/g" "$GHOST_ROOT/apps/portal/src/components/pages/SignupPage.js"
    sed -i '' "s/jamie@example.com/$PLACEHOLDER_EMAIL/g" "$GHOST_ROOT/apps/portal/src/components/pages/SigninPage.js"
fi

# Hide already a member message if flag is set
if [ "$HIDE_ALREADY_MEMBER" = true ]; then
    # Capture the original display rule
    ORIGINAL_DISPLAY=$(grep -A 1 '\.gh-portal-signup-message {' "$GHOST_ROOT/apps/portal/src/components/pages/SignupPage.js" | grep 'display:' | sed 's/.*display: \([^;]*\);.*/\1/')
    
    # Modify the CSS rule in SignupPage.js
    sed -i '' "/\.gh-portal-signup-message {/,/}/s/display: $ORIGINAL_DISPLAY;/display: none !important;/g" "$GHOST_ROOT/apps/portal/src/components/pages/SignupPage.js"
fi

# Temporarily modify portal's vite.config.js to only include English translations
echo "Modifying portal's vite.config.js to use English-only translations..."
PORTAL_VITE_CONFIG="$GHOST_ROOT/apps/portal/vite.config.js"
# Create a backup of the original config
cp "$PORTAL_VITE_CONFIG" "${PORTAL_VITE_CONFIG}.backup"
# Modify the config to only include English translations
sed -i '' 's|dynamicRequireTargets: SUPPORTED_LOCALES.map(locale => `../../ghost/i18n/locales/${locale}/portal.json`)|dynamicRequireTargets: ['\''../../ghost/i18n/locales/en/portal.json'\'']|' "$PORTAL_VITE_CONFIG"

echo "Build started..."

# Run yarn build
(cd "$GHOST_ROOT/apps/portal" && yarn build)

echo "Build completed."

# Copy portal.min.js to specified repo directory
cp "$GHOST_ROOT/apps/portal/umd/portal.min.js" "$HOME/$THEME_PATH/"
echo "Copied to $THEME_PATH/portal.min.js."

# Check if version needs to be updated
CURRENT_VERSION=$(cat "$HOME/$THEME_PATH/PORTAL-VERSION" 2>/dev/null || echo "")
if [ "$CURRENT_VERSION" != "$PORTAL_VERSION" ]; then
    echo "$PORTAL_VERSION" > "$HOME/$THEME_PATH/PORTAL-VERSION"
    echo "Bumped $THEME_PATH/PORTAL-VERSION to v$PORTAL_VERSION"
else
    echo "Portal already up to date."
fi

echo "Cleaning up changes..."

# Restore name placeholder in all files
if [ ! -z "$PLACEHOLDER_NAME" ]; then
    sed -i '' "s/$PLACEHOLDER_NAME/Jamie Larson/g" "$GHOST_ROOT/apps/portal/src/components/pages/AccountProfilePage.js"
    sed -i '' "s/$PLACEHOLDER_NAME/Jamie Larson/g" "$GHOST_ROOT/apps/portal/src/components/pages/OfferPage.js"
    sed -i '' "s/$PLACEHOLDER_NAME/Jamie Larson/g" "$GHOST_ROOT/apps/portal/src/components/pages/SignupPage.js"
fi

# Restore email placeholder in all files
if [ ! -z "$PLACEHOLDER_EMAIL" ]; then
    sed -i '' "s/$PLACEHOLDER_EMAIL/jamie@example.com/g" "$GHOST_ROOT/apps/portal/src/components/pages/AccountProfilePage.js"
    sed -i '' "s/$PLACEHOLDER_EMAIL/jamie@example.com/g" "$GHOST_ROOT/apps/portal/src/components/pages/OfferPage.js"
    sed -i '' "s/$PLACEHOLDER_EMAIL/jamie@example.com/g" "$GHOST_ROOT/apps/portal/src/components/pages/SignupPage.js"
    sed -i '' "s/$PLACEHOLDER_EMAIL/jamie@example.com/g" "$GHOST_ROOT/apps/portal/src/components/pages/SigninPage.js"
fi

# Restore CSS rule if flag was set
if [ "$HIDE_ALREADY_MEMBER" = true ]; then
    sed -i '' "/\.gh-portal-signup-message {/,/}/s/display: none !important;/display: $ORIGINAL_DISPLAY;/g" "$GHOST_ROOT/apps/portal/src/components/pages/SignupPage.js"
fi

# Restore original portal vite.config.js
mv "${PORTAL_VITE_CONFIG}.backup" "$PORTAL_VITE_CONFIG"
echo "Restored portal's vite.config.js"

echo "Done!"
echo ""