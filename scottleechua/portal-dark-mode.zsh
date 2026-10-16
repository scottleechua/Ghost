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

echo "Applying dark mode changes..."

# Create a temporary file with the dark mode code
TOGGLE_DARK_FILE=$(mktemp)
cat > "$TOGGLE_DARK_FILE" << 'EOL'
        const isParentDark = window.parent.document.documentElement.getAttribute('data-theme') === 'dark';
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
    /* The backdrop tints with --blackrgb, which is white above; keep it a dark tint */
    html.dark .gh-portal-popup-background {
        background: linear-gradient(315deg, rgba(0,0,0,0.4) 0%, rgba(0,0,0,0.3) 100%);
    }
EOL

COMPONENTS="$GHOST_ROOT/apps/portal/src/components"

# Edit popup-modal.jsx to add dark mode detection
apply_patch "Detect dark mode in popup" "$COMPONENTS/popup-modal.jsx" \
    sed -i '' -e "/const isMobile = window.innerWidth < 480;/r $TOGGLE_DARK_FILE"
apply_patch "Pass dark mode to popup frame" "$COMPONENTS/popup-modal.jsx" \
    sed -i '' -e "s/dataDir={this.context.dir}/dataDir={this.context.dir}\n          dataDark={isParentDark}/"

# Edit notification.jsx to add dark mode detection
apply_patch "Detect dark mode in notification" "$COMPONENTS/notification.jsx" \
    sed -i '' -e "/const { type, status, message, autoHide, duration, notificationCount } = this.state;/r $TOGGLE_DARK_FILE"
apply_patch "Pass dark mode to notification frame" "$COMPONENTS/notification.jsx" \
    sed -i '' -e "s/testid=\"portal-notification-frame\"/testid=\"portal-notification-frame\"\n          dataDark={isParentDark}/"

# Edit frame.jsx to add dark/light class
apply_patch "Add dark/light class to frame" "$COMPONENTS/frame.jsx" \
    sed -i '' -e "s/this.forceUpdate();/this.iframeHtml.classList.add(this.props.dataDark ? 'dark' : 'light');\n      this.forceUpdate();/"

# Edit global.styles.js to add dark mode styles before the body rule
DARK_STYLES_FILE="$DARK_STYLES_FILE" apply_patch "Add dark mode palette" "$COMPONENTS/global.styles.js" \
    perl -0pi -e 'BEGIN { local $/; open(my $fh, "<", $ENV{DARK_STYLES_FILE}) or die; $css = <$fh>; } s/^([ \t]*body \{)$/$css$1/m'

# Clean up temporary files
rm "$TOGGLE_DARK_FILE"
rm "$DARK_STYLES_FILE"