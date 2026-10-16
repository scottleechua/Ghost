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

source "$GHOST_ROOT/scottleechua/patch-helpers.zsh" || exit 1

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

COMPONENTS="$GHOST_ROOT/apps/portal/src/components"

# Edit global.styles.js to add custom accent variables
apply_patch "Add light accent variables" "$COMPONENTS/global.styles.js" \
    sed -i '' -e "/:root {/r $LIGHT_ACCENTS_FILE"
apply_patch "Add dark accent variables" "$COMPONENTS/global.styles.js" \
    sed -i '' -e "/html.dark {/r $DARK_ACCENTS_FILE"

# Delete the brand color from the link buttons ('Sign in' / 'Sign up') on every page that has one
for page in signup-page.jsx signin-page.jsx offer-page.jsx support-success.jsx; do
    apply_patch "Remove brand color from link button" "$COMPONENTS/pages/$page" \
        perl -0pi -e 's/(className="gh-portal-btn gh-portal-btn-link")\s*style=\{\{ color: brandColor \}\}/$1/g'
done

# Add link style to .gh-portal-signup-terms-content p in signup-page.jsx
apply_patch "Color terms links with primary accent" "$COMPONENTS/pages/signup-page.jsx" \
    sed -i '' -e "/\.gh-portal-signup-terms-content p {/r $LINK_STYLE_FILE"

# Use the accents for primary buttons in action-button.jsx: primary accent as
# background, secondary accent as text color.
apply_patch "Use primary accent as button background" "$COMPONENTS/common/action-button.jsx" \
    perl -pi -e "s/const backgroundColor = brandColor \|\| '#3eb0ef';/const backgroundColor = 'var(--portal-primary-accent)';/"
apply_patch "Use secondary accent as button text color" "$COMPONENTS/common/action-button.jsx" \
    perl -pi -e "s/\.\.\.\(isPrimary \? \{ backgroundColor \} : \{\}\),/...(isPrimary ? { backgroundColor, color: 'var(--portal-secondary-accent)' } : {}),/"

# Modify background in switch.jsx
apply_patch "Use primary accent for switches" "$COMPONENTS/common/switch.jsx" \
    sed -i '' '/\.gh-portal-for-switch input:checked \+ .input-toggle-component {/,+1 s/background:.*;/background: var(--portal-primary-accent);/'

# Clean up temporary files
rm "$LIGHT_ACCENTS_FILE"
rm "$DARK_ACCENTS_FILE"
rm "$LINK_STYLE_FILE"