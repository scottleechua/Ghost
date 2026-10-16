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

source "$GHOST_ROOT/scottleechua/patch-helpers.zsh" || exit 1

PAGES="$GHOST_ROOT/apps/portal/src/components/pages"

echo "Replacing icon with logo..."

# Replace SiteIcon with SiteLogo in signup-page.jsx and signin-page.jsx
for page in signup-page.jsx signin-page.jsx; do
    apply_patch "Rename SiteIcon to SiteLogo" "$PAGES/$page" sed -i '' 's/SiteIcon/SiteLogo/g'
    apply_patch "Rename siteIcon to siteLogo" "$PAGES/$page" sed -i '' 's/siteIcon/siteLogo/g'
    apply_patch "Use site.logo instead of site.icon" "$PAGES/$page" sed -i '' 's/site\.icon/site.logo/g'
done

# Delete width = 60px
apply_patch "Remove fixed logo width" "$PAGES/signup-page.jsx" sed -i '' '/width: 60px;/d'

# Replace the mobile media query block for .gh-portal-signup-logo
apply_patch "Replace mobile logo size" "$PAGES/signup-page.jsx" \
    perl -0pi -e 's/(\@media \(max-width: 480px\) \{\n[ \t]*\.gh-portal-signup-logo \{\n)[^}]*\}/$1        height: 80px;\n        margin: 48px auto;\n    }/'
