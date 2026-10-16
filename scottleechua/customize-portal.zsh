#!/bin/zsh

# Parse command line arguments
PLACEHOLDER_NAME=""
PLACEHOLDER_EMAIL=""
HIDE_ALREADY_MEMBER=false
HIDE_SITE_TITLE=false
HIDE_POWERED_BY_GHOST=false
REPLACE_ICON_WITH_LOGO=false
ENABLE_DARK_MODE=false
CUSTOM_ACCENTS=()
CHECK=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --placeholder-name) PLACEHOLDER_NAME="$2"; shift ;;
        --placeholder-email) PLACEHOLDER_EMAIL="$2"; shift ;;
        --hide-already-member) HIDE_ALREADY_MEMBER=true ;;
        --hide-site-title) HIDE_SITE_TITLE=true ;;
        --hide-powered-by-ghost) HIDE_POWERED_BY_GHOST=true ;;
        --replace-icon-with-logo) REPLACE_ICON_WITH_LOGO=true ;;
        --enable-dark-mode) ENABLE_DARK_MODE=true ;;
        --check) CHECK=true ;;
        --custom-accents)
            CUSTOM_ACCENTS=("$2" "$3" "$4" "$5")
            shift 4
            ;;
        *) break ;;
    esac
    shift
done

# Check if all required arguments are provided. With --check, there is no theme path.
if { [ "$CHECK" = true ] && [ "$#" -ne 0 ]; } || { [ "$CHECK" != true ] && [ "$#" -ne 1 ]; }; then
    echo "Usage: $0 [--placeholder-name <name>] [--placeholder-email <email>] [--hide-already-member] [--hide-site-title] [--hide-powered-by-ghost] [--replace-icon-with-logo] [--enable-dark-mode] [--custom-accents <primary_light> <secondary_light> <primary_dark> <secondary_dark>] (<path_to_theme> | --check)"
    echo "  --placeholder-name    Set placeholder name (e.g., 'John Doe')"
    echo "  --placeholder-email   Set placeholder email (e.g., 'john@example.com')"
    echo "  --hide-already-member  Hide the 'Already a member?' message"
    echo "  --hide-site-title     Hide the site title in the portal"
    echo "  --hide-powered-by-ghost  Hide the 'Powered by Ghost' badge"
    echo "  --replace-icon-with-logo  Replace the site icon in the portal with the site logo"
    echo "  --enable-dark-mode     Enable dark mode"
    echo "  --custom-accents       Set custom accent colors"
    echo "                         <primary_light>   Primary accent color for light mode (e.g., '#ff0000')"
    echo "                         <secondary_light> Secondary accent color for light mode (e.g., '#00ff00')"
    echo "                         <primary_dark>    Primary accent color for dark mode (e.g., '#ff0000')"
    echo "                         <secondary_dark>  Secondary accent color for dark mode (e.g., '#00ff00')"
    echo "  --check                Apply the patches and build, but do not copy to a theme"
    exit 1
fi

# Check if custom accents are provided without dark mode
if [ ${#CUSTOM_ACCENTS[@]} -eq 4 ] && [ "$ENABLE_DARK_MODE" != true ]; then
    echo "Error: Custom accents can only be applied when dark mode is enabled"
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

source "$GHOST_ROOT/scottleechua/patch-helpers.zsh" || exit 1

PAGES="$GHOST_ROOT/apps/portal/src/components/pages"
PORTAL_I18N_REGISTRY="$GHOST_ROOT/packages/i18n/src/registry/portal.ts"

# Restore all modified source files to their original state using Git.
# Runs on every exit, so a failed patch or build does not leave the source modified.
restore_sources() {
    echo "Cleaning up changes..."
    (cd "$GHOST_ROOT/apps/portal" && git restore .)
    # The i18n registry lives outside apps/portal, so restore it explicitly
    (cd "$GHOST_ROOT" && git restore "$PORTAL_I18N_REGISTRY")
}
trap restore_sources EXIT

# Replace a placeholder string in every Portal source file that uses it
replace_placeholder() {
    local original="$1"
    local replacement="$2"
    local files=("${(@f)$(grep -rlF --exclude='*.test.*' "$original" "$GHOST_ROOT/apps/portal/src/components")}")

    if [ -z "${files[1]}" ]; then
        echo "Error: placeholder '$original' not found in Portal source"
        exit 1
    fi

    for file in "${files[@]}"; do
        ORIGINAL="$original" REPLACEMENT="$replacement" apply_patch "Replace placeholder '$original'" "$file" \
            perl -pi -e 's/\Q$ENV{ORIGINAL}\E/$ENV{REPLACEMENT}/g'
    done
}

# Get Portal version
PORTAL_VERSION=$(jq -r '.version' "$GHOST_ROOT/apps/portal/package.json")
echo "=== Customize Portal ==="
echo "Portal version: $PORTAL_VERSION"

# Replace name placeholder in all files
if [ ! -z "$PLACEHOLDER_NAME" ]; then
    replace_placeholder "Jamie Larson" "$PLACEHOLDER_NAME"
fi

# Replace email placeholder in all files
if [ ! -z "$PLACEHOLDER_EMAIL" ]; then
    replace_placeholder "jamie@example.com" "$PLACEHOLDER_EMAIL"
fi

# Hide already a member message if flag is set
if [ "$HIDE_ALREADY_MEMBER" = true ]; then
    # Insert return null as first statement in renderLoginMessage() so the element is never rendered
    apply_patch "Hide 'Already a member?' message" "$PAGES/signup-page.jsx" \
        perl -pi -e 's/^(\s*)(renderLoginMessage\(.*\) \{)$/$1$2\n$1  return null;/'
fi

# Hide site title if flag is set
if [ "$HIDE_SITE_TITLE" = true ]; then
    echo "Removing site title on Signin and Signup pages..."

    # Delete the h1 element after renderSiteIcon() in signup-page.jsx
    apply_patch "Remove site title on Signup page" "$PAGES/signup-page.jsx" \
        perl -0pi -e 's/(\{this\.renderSiteIcon\(\)\})\s*<h1 className="gh-portal-main-title"[^>]*>\s*\{siteTitle\}\s*<\/h1>/$1/'

    # Find renderSiteTitle() and replace the siteTitle return with return null in signin-page.jsx
    apply_patch "Remove site title on Signin page" "$PAGES/signin-page.jsx" \
        perl -pi -e 's/return <h1 className="gh-portal-main-title">\{siteTitle\}<\/h1>;/return null;/'

    # Delete padding and margin from signup header
    apply_patch "Remove signup header padding and margin" "$PAGES/signup-page.jsx" \
        perl -0pi -e 's/\n[ \t]*padding: 0 32px;\n[ \t]*margin-bottom: 32px;//'

    # Modify margin in frame.styles.js
    apply_patch "Adjust newsletter selection margin" "$GHOST_ROOT/apps/portal/src/components/frame.styles.js" \
        sed -i '' '/\.gh-portal-newsletter-selection {/,+2 s/margin:.*;/margin: 12px auto;/'
fi

# Hide Powered by Ghost badge if flag is set
if [ "$HIDE_POWERED_BY_GHOST" = true ]; then
    echo "Removing Powered by Ghost box"
    apply_patch "Hide Powered by Ghost badge" "$GHOST_ROOT/apps/portal/src/components/popup-modal.jsx" \
        perl -pi -e "s/\+ \(hasMode\(\['preview'\]\) \? 'hidden ' : ''\) \+ pageClass/+ 'hidden ' + pageClass/g"
fi

# Replace icon with logo if flag is set
if [ "$REPLACE_ICON_WITH_LOGO" = true ]; then
    REPLACE_ICON_SCRIPT="$(dirname "$0")/portal-replace-icon-with-logo.zsh"
    if [ -f "$REPLACE_ICON_SCRIPT" ]; then
        "$REPLACE_ICON_SCRIPT" || exit 1
    else
        echo "Error: Replace icon script not found at $REPLACE_ICON_SCRIPT"
        exit 1
    fi
fi

# Enable dark mode if flag is set
if [ "$ENABLE_DARK_MODE" = true ]; then
    echo "Enabling dark mode..."
    # Execute the dark mode script
    DARK_MODE_SCRIPT="$(dirname "$0")/portal-dark-mode.zsh"
    if [ -f "$DARK_MODE_SCRIPT" ]; then
        "$DARK_MODE_SCRIPT" || exit 1
    else
        echo "Error: Dark mode script not found at $DARK_MODE_SCRIPT"
        exit 1
    fi

    # Apply custom accents if provided
    if [ ${#CUSTOM_ACCENTS[@]} -eq 4 ]; then
        CUSTOM_ACCENTS_SCRIPT="$(dirname "$0")/portal-custom-accents.zsh"
        if [ -f "$CUSTOM_ACCENTS_SCRIPT" ]; then
            "$CUSTOM_ACCENTS_SCRIPT" "${CUSTOM_ACCENTS[1]}" "${CUSTOM_ACCENTS[2]}" "${CUSTOM_ACCENTS[3]}" "${CUSTOM_ACCENTS[4]}" || exit 1
        else
            echo "Error: Custom accents script not found at $CUSTOM_ACCENTS_SCRIPT"
            exit 1
        fi
    fi
fi

# Temporarily slim Portal's i18n bundle to English only.
# Locales are loaded through a static registry (@tryghost/i18n/registry/portal)
# that globs every locale via import.meta.glob. Narrow that glob to `en` so only
# English is bundled. Restored via git at cleanup.
echo "Slimming Portal i18n registry to English-only translations..."
apply_patch "Slim i18n registry to English only" "$PORTAL_I18N_REGISTRY" \
    sed -i '' "s|locales/\*/portal.json|locales/en/portal.json|"

# In check mode, keep the patched source as a diff, to review where each patch landed
if [ "$CHECK" = true ] && [ -n "$PATCH_DIFF" ]; then
    (cd "$GHOST_ROOT" && git diff -- apps/portal "$PORTAL_I18N_REGISTRY") > "$PATCH_DIFF"
fi

echo "Build started..."

# Run pnpm build
if ! (cd "$GHOST_ROOT/apps/portal" && pnpm build); then
    echo "Error: Portal build failed"
    exit 1
fi

echo "Build completed."

if [ "$CHECK" = true ]; then
    echo "Check passed: every patch applied and Portal built."
    exit 0
fi

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

echo "Done!"
echo ""