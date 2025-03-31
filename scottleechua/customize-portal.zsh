#!/bin/zsh

# Check if all required arguments are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <full_name> <email> <path_to_theme>"
    exit 1
fi

FULL_NAME=$1
EMAIL=$2
THEME_PATH=$3

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
echo "Portal version: $PORTAL_VERSION"

# Replace placeholders in AccountProfilePage.js
sed -i '' "s/Jamie Larson/$FULL_NAME/g" "$GHOST_ROOT/apps/portal/src/components/pages/AccountProfilePage.js"
sed -i '' "s/jamie@example.com/$EMAIL/g" "$GHOST_ROOT/apps/portal/src/components/pages/AccountProfilePage.js"

# Replace placeholders in OfferPage.js
sed -i '' "s/Jamie Larson/$FULL_NAME/g" "$GHOST_ROOT/apps/portal/src/components/pages/OfferPage.js"
sed -i '' "s/jamie@example.com/$EMAIL/g" "$GHOST_ROOT/apps/portal/src/components/pages/OfferPage.js"

# Replace placeholders in SignupPage.js
sed -i '' "s/Jamie Larson/$FULL_NAME/g" "$GHOST_ROOT/apps/portal/src/components/pages/SignupPage.js"
sed -i '' "s/jamie@example.com/$EMAIL/g" "$GHOST_ROOT/apps/portal/src/components/pages/SignupPage.js"

# Replace placeholders in SigninPage.js
sed -i '' "s/jamie@example.com/$EMAIL/g" "$GHOST_ROOT/apps/portal/src/components/pages/SigninPage.js"

echo "Build started..."

# Run yarn build
(cd "$GHOST_ROOT/apps/portal" && yarn build)

echo "Build completed."

# Copy portal.min.js to specified repo directory
cp "$GHOST_ROOT/apps/portal/umd/portal.min.js" "$HOME/$THEME_PATH/"
echo "$PORTAL_VERSION" > "$HOME/$THEME_PATH/PORTAL-VERSION"

echo "Copied to $THEME_PATH/portal.min.js."

echo "Cleaning up changes..."

# Restore original placeholders in AccountProfilePage.js
sed -i '' "s/$FULL_NAME/Jamie Larson/g" "$GHOST_ROOT/apps/portal/src/components/pages/AccountProfilePage.js"
sed -i '' "s/$EMAIL/jamie@example.com/g" "$GHOST_ROOT/apps/portal/src/components/pages/AccountProfilePage.js"

# Restore original placeholders in OfferPage.js
sed -i '' "s/$FULL_NAME/Jamie Larson/g" "$GHOST_ROOT/apps/portal/src/components/pages/OfferPage.js"
sed -i '' "s/$EMAIL/jamie@example.com/g" "$GHOST_ROOT/apps/portal/src/components/pages/OfferPage.js"

# Restore original placeholders in SignupPage.js
sed -i '' "s/$FULL_NAME/Jamie Larson/g" "$GHOST_ROOT/apps/portal/src/components/pages/SignupPage.js"
sed -i '' "s/$EMAIL/jamie@example.com/g" "$GHOST_ROOT/apps/portal/src/components/pages/SignupPage.js"

# Restore original placeholders in SigninPage.js
sed -i '' "s/$EMAIL/jamie@example.com/g" "$GHOST_ROOT/apps/portal/src/components/pages/SigninPage.js"

echo "Done!"