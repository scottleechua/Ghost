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

echo "Applying dark mode changes..."

# 1. Create the new Global.styles.js
cat > "$GHOST_ROOT/apps/portal/src/components/Global.styles.js" << 'EOL'
import {createGlobalStyle} from 'styled-components';

export const GlobalStyle = createGlobalStyle`
    :root {
        --brand-color: #3eb0ef;
        --background-color: #ffffff;
        --text-color: #15171a;
        --secondary-text-color: #738a94;
        --border-color: #e3e9ed;
    }

    [data-dark="true"] {
        --brand-color: #3eb0ef;
        --background-color: #15171a;
        --text-color: #ffffff;
        --secondary-text-color: #a4b0b6;
        --border-color: #2a2a2a;
    }

    body {
        background-color: var(--background-color);
        color: var(--text-color);
    }

    .gh-portal-btn {
        background-color: var(--brand-color);
        color: white;
    }

    .gh-portal-btn-link {
        color: var(--brand-color);
    }

    .gh-portal-input {
        background-color: var(--background-color);
        color: var(--text-color);
        border-color: var(--border-color);
    }

    .gh-portal-label {
        color: var(--text-color);
    }

    .gh-portal-text {
        color: var(--secondary-text-color);
    }
`;
EOL

# 2. Add invertColor to App.js state
sed -i '' '/scrollbarWidth: 0,/a\
        invertColor: props.invertColor || '\''#999'\'',\
' "$GHOST_ROOT/apps/portal/src/App.js"

sed -i '' '/initStatus: '\''success'\'',/a\
        invertColor: this.props.invertColor || '\''#999'\'',\
' "$GHOST_ROOT/apps/portal/src/App.js"

# Add getInvertColor method after getAccentColor method
sed -i '' '/getAccentColor() {/,/return accentColor;/a\
\
getInvertColor() {\
    const {accent_color: accentColor} = this.state.site || {};\
\
    if (!accentColor) {\
        return '\''#000'\'';\
    }\
\
    const color = accentColor.replace('\''#'\'', '\'''\'');\
    const r = parseInt(color.substr(0, 2), 16);\
    const g = parseInt(color.substr(2, 2), 16);\
    const b = parseInt(color.substr(4, 2), 16);\
    const brightness = (r * 299 + g * 587 + b * 114) / 1000;\
    return brightness > 128 ? '\''#000'\'' : '\''#fff'\'';\
}\
' "$GHOST_ROOT/apps/portal/src/App.js"

# 3. Add invertColor to AppContext.js
sed -i '' '/dir: '\''ltr'\''/s/$/,/' "$GHOST_ROOT/apps/portal/src/AppContext.js"
sed -i '' '/dir: '\''ltr'\'',/a\
    invertColor: '\'''\''\
' "$GHOST_ROOT/apps/portal/src/AppContext.js"

# 4. Add dataDark to Frame.js
sed -i '' '/title="portal-popup"/a\
            dataDark={this.props.dataDark}\
' "$GHOST_ROOT/apps/portal/src/components/Frame.js"

# 5. Update SigninPage.js and SignupPage.js to use CSS variables
sed -i '' 's/style={{color: brandColor}}/style={{color: '\''var(--brand-color)'\''}}/g' "$GHOST_ROOT/apps/portal/src/components/pages/SigninPage.js"
sed -i '' 's/style={{color: brandColor}}/style={{color: '\''var(--brand-color)'\''}}/g' "$GHOST_ROOT/apps/portal/src/components/pages/SignupPage.js"

# 6. Update index.js to handle invertColor
sed -i '' '/const locale = scriptTag.dataset.locale;/a\
    const invertColor = scriptTag.dataset.invertColor;\
' "$GHOST_ROOT/apps/portal/src/index.js"

sed -i '' 's/return {siteUrl, apiKey, apiUrl, siteI18nEnabled, locale};/return {siteUrl, apiKey, apiUrl, siteI18nEnabled, locale, invertColor};/g' "$GHOST_ROOT/apps/portal/src/index.js"

sed -i '' 's/<App siteUrl={siteUrl} customSiteUrl={customSiteUrl} apiKey={apiKey} apiUrl={apiUrl} siteI18nEnabled={siteI18nEnabled} locale={locale}\/>/<App siteUrl={siteUrl} customSiteUrl={customSiteUrl} apiKey={apiKey} apiUrl={apiUrl} siteI18nEnabled={siteI18nEnabled} locale={locale} invertColor={invertColor}\/>/g' "$GHOST_ROOT/apps/portal/src/index.js"

echo "Dark mode changes applied successfully!" 