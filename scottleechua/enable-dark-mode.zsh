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

# Create a temporary file with the dark mode styles
DARK_STYLES_FILE=$(mktemp)
cat > "$DARK_STYLES_FILE" << 'EOL'
    html.dark {
        --black: #fff;
        --blackrgb: 255,255,255;
        --grey0: #fbfbfb;
        --grey1: #f9f9f9;
        --grey1rgb: 249,249,249;
        --grey2: #eaeaea;
        --grey3: #e1e1e1;
        --grey4: #dcdcdc;
        --grey5: #c5c5c5;
        --grey6: #aeaeae;
        --grey7: #979797;
        --grey8: #7f7f7f;
        --grey9: #686868;
        --grey10: #515151;
        --grey11: #474747;
        --grey12: #3d3d3d;
        --grey13: #333;
        --grey13rgb: 33,33,33;
        --grey14: #1d1d1d;
        --white: #000;
        --whitergb: 0,0,0;
    }
EOL

# Edit PopupModal.js to add dark mode detection
sed -i '' -e "/const isMobile = window.innerWidth < 480;/r $TEMP_FILE" "$GHOST_ROOT/apps/portal/src/components/PopupModal.js"
sed -i '' -e "s/dataDir={this.context.dir}/dataDir={this.context.dir}\n                    dataDark={isParentDark}/" "$GHOST_ROOT/apps/portal/src/components/PopupModal.js"

# Edit Notification.js to add dark mode detection
sed -i '' -e "/const {type, status, autoHide, duration} = this.state;/r $TEMP_FILE" "$GHOST_ROOT/apps/portal/src/components/Notification.js"
sed -i '' -e "s/testid=\"portal-notification-frame\"/testid=\"portal-notification-frame\"\n                    dataDark={isParentDark}/" "$GHOST_ROOT/apps/portal/src/components/Notification.js"

# Edit Frame.js to add dark/light class
sed -i '' -e "s/this.forceUpdate();/this.iframeHtml.classList.add(this.props.dataDark ? 'dark' : 'light');\n            this.forceUpdate();/" "$GHOST_ROOT/apps/portal/src/components/Frame.js"

# Edit Global.styles.js to add dark mode styles
GLOBAL_STYLES_PATH="$GHOST_ROOT/apps/portal/src/components/Global.styles.js"
TEMP_GLOBAL_STYLES=$(mktemp)
awk '/body {/ {system("cat '"$DARK_STYLES_FILE"'"); print; next} {print}' "$GLOBAL_STYLES_PATH" > "$TEMP_GLOBAL_STYLES"
mv "$TEMP_GLOBAL_STYLES" "$GLOBAL_STYLES_PATH"

# Clean up temporary files
rm "$TEMP_FILE"
rm "$DARK_STYLES_FILE"

echo "Dark mode changes applied successfully!" 