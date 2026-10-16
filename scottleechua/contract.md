# Portal and SodoSearch contract

What the scripts in `scottleechua/` depend on in upstream Portal (`apps/portal`), SodoSearch (`apps/sodo-search`) and `@tryghost/i18n` (`packages/i18n`). Check every item when upstream changes.

Two checks keep the scripts working:

- **Mechanical:** `check-patches.zsh` runs every patch with every option and builds both apps. Each patch fails if its file is missing or comes out unchanged (`apply_patch` in `patch-helpers.zsh`). This catches an anchor that no longer matches.
- **This contract:** what a patch that applies can still get wrong. The patch can land, but upstream now renders the element somewhere else, or the variable no longer controls the color, or the patch now also hides something new.

When you add or change a patch, add or update its item here.
In **Patch**, name the script and the `apply_patch` description, not a line number.

## Build environment

Use these facts to decide if an upstream change affects these scripts.

- **Where the scripts run:** macOS, with BSD `sed` (`sed -i ''`) and `perl`. The check workflow also runs on macOS.
- **Where the output goes:** a Ghost theme ships the built `portal.min.js`, `sodo-search.min.js` and `sodo-search-main.css` (`umd/main.css`) itself, in place of the CDN copies. A theme loads them in the parent page, and Portal renders in same-origin iframes.
- **Locale:** the site is English only. The scripts bundle only `en`.

The upstream commit last checked is in `scottleechua/checked-upstream`. `.github/workflows/portal-contract-check.yml` reads and updates it.

---

## A. Build and output

### A1. Build commands and output files

- **Assumes:** `pnpm build` in `apps/portal` writes `umd/portal.min.js`. `pnpm build` in `apps/sodo-search` writes `umd/sodo-search.min.js` and `umd/main.css`. Each app's version is in its `package.json` `version`.
- **Patch:** `customize-portal.zsh` and `customize-sodosearch.zsh` (the `cp` of each output file, and `PORTAL-VERSION` / `SODOSEARCH-VERSION`).
- **If broken:** The copy fails, or copies a stale or wrong file.

### A2. i18n registries glob every locale

- **Assumes:** Portal and SodoSearch load translations only through `packages/i18n/src/registry/portal.ts` and `search.ts`, each an `import.meta.glob('../../locales/*/<app>.json')`. Narrowing the glob to `en` removes the other locales from the bundle, and nothing else imports them.
- **Patch:** "Slim i18n registry to English only" in both customize scripts.
- **If broken:** The patch fails (registry moved), or applies but the bundle still holds every locale (a second import path), or English text breaks.

### A3. Restoring the source

- **Assumes:** Every file that a patch edits is under `apps/portal`, `apps/sodo-search`, or is one of the two registry files. The scripts restore only those with `git restore`.
- **Patch:** `restore_sources()` in both customize scripts.
- **If broken:** A patch that moves outside these paths leaves the fork's source modified after a run.

## B. Portal placeholders and text

### B1. Placeholder name and email

- **Assumes:** The placeholder name `Jamie Larson` and email `jamie@example.com` are plain strings in `.jsx`/`.tsx` files under `src/components`, not translated with `t()` and not built from parts.
- **Patch:** `replace_placeholder` in `customize-portal.zsh` (`--placeholder-name`, `--placeholder-email`).
- **If broken:** Some forms show the default placeholder. The patch fails only if no file has the string, so a new form that builds it differently is not caught.

### B2. "Already a member?" message

- **Assumes:** `renderLoginMessage()` in `pages/signup-page.jsx` renders the "Already a member?" row. Returning `null` from it hides that row. It is not rendered anywhere else on the signup page.
- **Known side effect:** `renderLoginMessage()` also renders `renderFreeTrialMessage()` and `SignupGiftPromotion`, so `--hide-already-member` hides those too. Report it if more content moves into this function, or if these move out.
- **Patch:** "Hide 'Already a member?' message" in `customize-portal.zsh`.
- **If broken:** The message shows again, or other signup content disappears.

### B3. Site title on the signin and signup pages

- **Assumes:**
  - On the signup page, the site title is the `<h1 className="gh-portal-main-title">{siteTitle}</h1>` right after `{this.renderSiteIcon()}`.
  - On the signin page, `renderSiteTitle()` returns `<h1 className="gh-portal-main-title">{siteTitle}</h1>` when there is a title.
  - The signup header spacing comes from `padding: 0 32px; margin-bottom: 32px;` in the signup page styles, and the newsletter list margin from the first `.gh-portal-newsletter-selection` rule in `frame.styles.js`.
- **Patch:** "Remove site title on Signup page", "Remove site title on Signin page", "Remove signup header padding and margin" and "Adjust newsletter selection margin" in `customize-portal.zsh`.
- **If broken:** The title shows again, or the header spacing is wrong. If the padding/margin pair moves to another rule, the patch can remove spacing from the wrong element.

### B4. "Powered by Ghost" badge

- **Assumes:** In `popup-modal.jsx`, the badge's class names are built as `'gh-portal-powered …' + (hasMode(['preview']) ? 'hidden ' : '') + pageClass`, for both the inside and the outside badge, and the `hidden` class hides it.
- **Patch:** "Hide Powered by Ghost badge" in `customize-portal.zsh`.
- **If broken:** The badge shows again. If only one of the two class strings matches, the patch applies and the other badge still shows.

## C. Portal logo

### C1. Site icon to site logo

- **Assumes:**
  - In `pages/signup-page.jsx` and `pages/signin-page.jsx`, the icon is rendered only by `renderSiteIcon()`, which reads `site.icon` into `siteIcon`. Renaming `SiteIcon`/`siteIcon`/`site.icon` to `SiteLogo`/`siteLogo`/`site.logo` in these files changes nothing else.
  - `site.logo` is in Portal's site data (from the Members/Content API settings).
  - The logo size is set by `width: 60px;` in `.gh-portal-signup-logo`, and by a `@media (max-width: 480px) { .gh-portal-signup-logo { … } }` block directly after it.
- **Patch:** "Rename SiteIcon to SiteLogo", "Rename siteIcon to siteLogo", "Use site.logo instead of site.icon", "Remove fixed logo width" and "Replace mobile logo size" in `portal-replace-icon-with-logo.zsh`.
- **If broken:** Portal shows the icon, or no image, or a logo of the wrong size. `width: 60px;` is deleted on every line of the file, so a second rule with it also loses its width.

## D. Portal dark mode

### D1. Reading the parent page's theme

- **Assumes:**
  - Portal's iframes are same-origin with the parent page, so `window.parent.document` can be read.
  - `PopupModal.render()` (after `const isMobile = window.innerWidth < 480;`) and `Notification.render()` (after the `this.state` destructure with `notificationCount`) each render one `Frame`. The popup `Frame` has `dataDir={this.context.dir}` and the notification `Frame` has `testid="portal-notification-frame"`.
  - The value is read on each render. Portal does not re-render when the parent's `data-theme` changes, so a theme switch takes effect on the next open.
- **Patch:** "Detect dark mode in popup", "Pass dark mode to popup frame", "Detect dark mode in notification" and "Pass dark mode to notification frame" in `portal-dark-mode.zsh`.
- **If broken:** Portal is always light, or throws if the iframe is not same-origin. A new popup or notification frame without the prop stays light.

### D2. The `dark` class on the iframe's `<html>`

- **Assumes:** `Frame.setupFrameBaseStyle()` in `frame.jsx` runs `this.forceUpdate();` once, after it sets `this.iframeHtml`. It is the only `forceUpdate()` in the file. Portal does not set or clear classes on the iframe's `<html>` elsewhere.
- **Patch:** "Add dark/light class to frame" in `portal-dark-mode.zsh`.
- **If broken:** The `dark` class is missing (light Portal), or added before `iframeHtml` exists (an error).

### D3. Dark palette through CSS variables

- **Assumes:** `global.styles.js` defines the palette as `--black`, `--blackrgb`, `--grey0` … `--grey14`, `--grey1rgb`, `--grey13rgb`, `--white` and `--whitergb` on `:root`, and Portal's styles use these variables, not fixed colors. The popup backdrop is `.gh-portal-popup-background`, tinted with `--blackrgb`. The dark rules go before a line that is exactly `body {`.
- **Patch:** "Add dark mode palette" in `portal-dark-mode.zsh`.
- **If broken:** Parts of Portal stay light in dark mode (new fixed colors or new variables), or the backdrop turns white.

## E. Portal accent colors

### E1. Accent variables

- **Assumes:** `global.styles.js` has one `:root {` rule and, after D3, one `html.dark {` rule. Variables added there apply in every Portal iframe.
- **Patch:** "Add light accent variables" and "Add dark accent variables" in `portal-custom-accents.zsh`.
- **If broken:** Accent colors are unset, so buttons and links lose their color.

### E2. Brand color on buttons, links and switches

- **Assumes:**
  - Primary buttons get their background only from `const backgroundColor = brandColor || '#3eb0ef';` and `...(isPrimary ? { backgroundColor } : {})` in `common/action-button.jsx`. Text color is not set elsewhere for primary buttons.
  - The "Sign in" / "Sign up" link buttons get their color only from `style={{ color: brandColor }}` on `className="gh-portal-btn gh-portal-btn-link"`, in `signup-page.jsx`, `signin-page.jsx`, `offer-page.jsx` and `support-success.jsx`.
  - Checked switches get their color from the `background:` line right after `.gh-portal-for-switch input:checked + .input-toggle-component {` in `common/switch.jsx`.
  - Links in the signup terms are inside `.gh-portal-signup-terms-content p` in `signup-page.jsx`.
- **Patch:** the other `apply_patch` calls in `portal-custom-accents.zsh`.
- **If broken:** These elements show the site's brand color instead of the accent. A new page with a link button, or a new component colored with `brandColor` or `--brandcolor`, keeps the brand color; report it.

## F. SodoSearch

### F1. Font family

- **Assumes:** `apps/sodo-search/src/index.css` has a line that is exactly `body {`, and a `font-family` there applies to the whole search UI (it beats Tailwind's `:host, html` font rule).
- **Patch:** "Add font family to body" in `customize-sodosearch.zsh`.
- **If broken:** Search shows Tailwind's default font.

### F2. Search placeholder in the built bundle

- **Assumes:** The placeholder is the English key `Search posts, tags and authors`, passed to `t()` in `src/components/popup-modal.tsx`, and the `en` translation is empty, so the bundle holds the key as a plain string. The patch edits the built `umd/sodo-search.min.js`, not the source, so every use of the key changes (placeholder, `aria-label`, `title`).
- **Patch:** "Replace search placeholder" in `customize-sodosearch.zsh`.
- **If broken:** The patch fails (key renamed), or the `en` translation gets a value, so the bundle shows that value instead.
