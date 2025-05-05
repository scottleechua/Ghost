#!/bin/zsh

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

echo "Replacing icon with logo..."

# Replace SiteIcon with SiteLogo in SignupPage.js
sed -i '' 's/SiteIcon/SiteLogo/g' "$GHOST_ROOT/apps/portal/src/components/pages/SignupPage.js"
sed -i '' 's/siteIcon/siteLogo/g' "$GHOST_ROOT/apps/portal/src/components/pages/SignupPage.js"
sed -i '' 's/site.icon/site.logo/g' "$GHOST_ROOT/apps/portal/src/components/pages/SignupPage.js"

# Replace SiteIcon with SiteLogo in SigninPage.js
sed -i '' 's/SiteIcon/SiteLogo/g' "$GHOST_ROOT/apps/portal/src/components/pages/SigninPage.js"
sed -i '' 's/siteIcon/siteLogo/g' "$GHOST_ROOT/apps/portal/src/components/pages/SigninPage.js"
sed -i '' 's/site.icon/site.logo/g' "$GHOST_ROOT/apps/portal/src/components/pages/SigninPage.js"

# Delete width = 60px
sed -i '' '/width: 60px;/d' "$GHOST_ROOT/apps/portal/src/components/pages/SignupPage.js"

# Create a temporary file with the new media query block
TEMP_FILE=$(mktemp)
cat > "$TEMP_FILE" << 'EOL'
@media (max-width: 480px) {
    .gh-portal-signup-logo {
        height: 80px;
        margin: 48px auto;
    }
EOL

# Replace the media query block for .gh-portal-signup-logo using awk
awk '
    BEGIN { found = 0; in_block = 0 }
    /@media \(max-width: 480px\) {/ {
        if (found == 0) {
            # Store the current line
            current = $0
            # Get the next line
            getline next_line
            # Check if the next line contains the exact logo class
            if (next_line ~ /\.gh-portal-signup-logo {/) {
                # Found our target block, print the new content
                while ((getline < "'"$TEMP_FILE"'") > 0) {
                    print
                }
                # Skip the rest of the block
                in_block = 1
                found = 1
                next
            } else {
                # Not our target, print both lines
                print current
                print next_line
            }
            next
        }
    }
    in_block && /}/ {
        in_block = 0
        next
    }
    !in_block { print }
' "$GHOST_ROOT/apps/portal/src/components/pages/SignupPage.js" > "$GHOST_ROOT/apps/portal/src/components/pages/SignupPage.js.tmp" && mv "$GHOST_ROOT/apps/portal/src/components/pages/SignupPage.js.tmp" "$GHOST_ROOT/apps/portal/src/components/pages/SignupPage.js"

# Clean up temporary file
rm "$TEMP_FILE"
