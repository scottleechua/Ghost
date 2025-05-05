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

# Change to portal directory
cd "$GHOST_ROOT/apps/portal"

echo "Applying custom accents..."

# Check if we have the required arguments
if [ $# -ne 4 ]; then
    echo "Error: This script requires 4 color arguments: primary_light secondary_light primary_dark secondary_dark"
    exit 1
fi

PRIMARY_LIGHT=$1
SECONDARY_LIGHT=$2
PRIMARY_DARK=$3
SECONDARY_DARK=$4

# Create a temporary file with the light mode custom accent variables
LIGHT_ACCENTS_FILE=$(mktemp)
cat > "$LIGHT_ACCENTS_FILE" << EOL
        --portal-primary-accent: ${PRIMARY_LIGHT};
        --portal-secondary-accent: ${SECONDARY_LIGHT};
EOL

# Create a temporary file with the dark mode custom accent variables
DARK_ACCENTS_FILE=$(mktemp)
cat > "$DARK_ACCENTS_FILE" << EOL
        --portal-primary-accent: ${PRIMARY_DARK};
        --portal-secondary-accent: ${SECONDARY_DARK};
EOL

# Create a temporary file with the link style
LINK_STYLE_FILE=$(mktemp)
cat > "$LINK_STYLE_FILE" << EOL
    a {
        color: var(--portal-primary-accent);
    }
EOL

# Edit Global.styles.js to add custom accent variables
sed -i '' -e "/:root {/r $LIGHT_ACCENTS_FILE" "$GHOST_ROOT/apps/portal/src/components/Global.styles.js"
sed -i '' -e "/html.dark {/r $DARK_ACCENTS_FILE" "$GHOST_ROOT/apps/portal/src/components/Global.styles.js"

# Delete style={{color: brandColor}} line in SignupPage.js if it appears within 10 lines after the button with className='gh-portal-btn gh-portal-btn-link'
if grep -A 10 "className='gh-portal-btn gh-portal-btn-link'" "$GHOST_ROOT/apps/portal/src/components/pages/SignupPage.js" | grep -q "style={{color: brandColor}}"; then
    sed -i '' -e "/className='gh-portal-btn gh-portal-btn-link'/,+10 {
        /style={{color: brandColor}}/d
    }" "$GHOST_ROOT/apps/portal/src/components/pages/SignupPage.js"
fi

# Delete style={{color: brandColor}} line in SigninPage.js if it appears within 10 lines after the button with className='gh-portal-btn gh-portal-btn-link'
if grep -A 10 "className='gh-portal-btn gh-portal-btn-link'" "$GHOST_ROOT/apps/portal/src/components/pages/SigninPage.js" | grep -q "style={{color: brandColor}}"; then
    sed -i '' -e "/className='gh-portal-btn gh-portal-btn-link'/,+10 {
        /style={{color: brandColor}}/d
    }" "$GHOST_ROOT/apps/portal/src/components/pages/SigninPage.js"
fi

# Add link style to .gh-portal-signup-terms-content p in SignupPage.js
sed -i '' -e "/\.gh-portal-signup-terms-content p {/r $LINK_STYLE_FILE" "$GHOST_ROOT/apps/portal/src/components/pages/SignupPage.js"

# Replace backgroundColor line in ActionButton.js
if grep -A 10 "const Styles = ({brandColor, disabled, style = {}, isPrimary}) => {" "$GHOST_ROOT/apps/portal/src/components/common/ActionButton.js" | grep -q "let backgroundColor ="; then
    sed -i '' -e "/const Styles = ({brandColor, disabled, style = {}, isPrimary}) => {/,+10 {
        /let backgroundColor =/s/let backgroundColor = .*/let backgroundColor = 'var(--portal-primary-accent)';/
    }" "$GHOST_ROOT/apps/portal/src/components/common/ActionButton.js"
fi

# Replace textColor line in ActionButton.js
if grep -A 10 "const Styles = ({brandColor, disabled, style = {}, isPrimary}) => {" "$GHOST_ROOT/apps/portal/src/components/common/ActionButton.js" | grep -q "const textColor ="; then
    sed -i '' -e "/const Styles = ({brandColor, disabled, style = {}, isPrimary}) => {/,+10 {
        /const textColor =/s/const textColor = .*/const textColor = 'var(--portal-secondary-accent)';/
    }" "$GHOST_ROOT/apps/portal/src/components/common/ActionButton.js"
fi

# Clean up temporary files
rm "$LIGHT_ACCENTS_FILE"
rm "$DARK_ACCENTS_FILE"
rm "$LINK_STYLE_FILE"

echo "Custom accents applied successfully!"