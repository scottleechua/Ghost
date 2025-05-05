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

echo "Applying dark mode changes..."

# Create a temporary file with the dark mode code
TEMP_FILE=$(mktemp)
cat > "$TEMP_FILE" << 'EOL'
        let isParentDark = false;
        const pageBody = window.parent.document.body;
        if (pageBody && pageBody.classList) {
            isParentDark = pageBody.classList.contains('dark');
        }
EOL

# Edit PopupModal.js to add dark mode detection
sed -i '' -e "/const isMobile = window.innerWidth < 480;/r $TEMP_FILE" "$GHOST_ROOT/apps/portal/src/components/PopupModal.js"
sed -i '' -e "s/dataDir={this.context.dir}/dataDir={this.context.dir}\n                    dataDark={isParentDark}/" "$GHOST_ROOT/apps/portal/src/components/PopupModal.js"

# Edit Notification.js to add dark mode detection
sed -i '' -e "/const {type, status, autoHide, duration} = this.state;/r $TEMP_FILE" "$GHOST_ROOT/apps/portal/src/components/Notification.js"
sed -i '' -e "s/testid=\"portal-notification-frame\"/testid=\"portal-notification-frame\"\n                    dataDark={isParentDark}/" "$GHOST_ROOT/apps/portal/src/components/Notification.js"

# Clean up temporary file
rm "$TEMP_FILE"

echo "Dark mode changes applied successfully!" 