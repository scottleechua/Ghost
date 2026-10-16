# Ghost customizations

Contains:

- `customize-portal.zsh`
- `customize-sodosearch.zsh`
- `check-patches.zsh` and `contract.md`, which keep both working when upstream changes

## Local Dev Setup

Last worked on a Mac (Apple Silicon) with Node v22.22.2, Perl 5.34.1, and pnpm 11.4.0.

**Important: Docker should be open before running the below commands.**

```bash
git clone --recurse-submodules git@github.com:scottleechua/Ghost.git && cd Ghost
# corepack enable pnpm # only if not already installed via brew
pnpm run setup
```

## Customize Portal

```bash
./customize-portal.zsh [--placeholder-name <full name>] [--placeholder-email <email>] [--hide-already-member] [--hide-site-title] [--hide-powered-by-ghost] [--replace-icon-with-logo] [--enable-dark-mode] [--custom-accents <primary_light> <secondary_light> <primary_dark> <secondary_dark>] (<path/to/theme> | --check)
```

This script will:

1. Replace placeholder name/email in Portal input fields (if `--placeholder-name` and/or `--placeholder-email` are provided)
2. Hide the "Already a member?" message (if `--hide-already-member` is provided)
3. Hide the site title on the signin and signup pages (if `--hide-site-title` is provided)
4. Hide the "Powered by Ghost" badge (if `--hide-powered-by-ghost` is provided)
5. Replace the site icon with the site logo (if `--replace-icon-with-logo` is provided)
6. Enable dark mode synced to the parent page's `data-theme="dark"` attribute on `<html>` (if `--enable-dark-mode` is provided)
7. Apply custom accent colors for light and dark mode (if `--custom-accents` is provided; requires `--enable-dark-mode`)
8. Build a minified Portal with `en` locale only
9. Copy the built `portal.min.js` to your theme directory
10. Create or update a `PORTAL-VERSION` file with the current Portal version
11. Restore all modified source files

Every patch is checked: if one no longer applies (e.g. because upstream reformatted Portal's source), the script names it, restores the source files, and exits without building.

With `--check` in place of the theme path, the script applies the patches and builds, but copies nothing to a theme.

Note: `--hide-already-member` hides all of `renderLoginMessage()`, which also renders the free-trial message and the gift promotion.

Examples:

```bash
# Basic usage (only theme path required)
./customize-portal.zsh "path/to/theme"

# With custom name and email placeholders
./customize-portal.zsh --placeholder-name "John Doe" --placeholder-email "john@example.com" "path/to/theme"

# Hide the "Already a member?" message
./customize-portal.zsh --hide-already-member "path/to/theme"

# With all options
./customize-portal.zsh --placeholder-name "John Doe" --placeholder-email "john@example.com" --hide-already-member --hide-site-title --hide-powered-by-ghost --replace-icon-with-logo --enable-dark-mode --custom-accents "#ff0000" "#ffffff" "#cc0000" "#ffffff" "path/to/theme"
```

The script can be run from any directory by using its full path:

```bash
/Ghost/scottleechua/customize-portal.zsh "path/to/theme"
```

## Customize SodoSearch

```bash
./customize-sodosearch.zsh [--font-family <list of fonts>] [--placeholder-string <string>] (<path/to/theme> | --check)
```

This script will:

1. Apply custom font family to the whole search element (if `--font-family` is provided)
2. Replace the searchbar placeholder text (if `--placeholder-string` is provided)
3. Build a minified SodoSearch with `en` locale only
4. Copy the built `sodo-search.min.js` to your theme directory
5. Copy and rename `main.css` to `sodo-search-main.css` to your theme directory
6. Create or update a `SODOSEARCH-VERSION` file with the current SodoSearch version
7. Restore the original search placeholder text and styles

Patches are checked the same way as in `customize-portal.zsh`, and `--check` works the same way.

Examples:

```bash
# Basic usage (only theme path required)
./customize-sodosearch.zsh "path/to/theme"

# With custom font family
./customize-sodosearch.zsh --font-family "Arial, sans-serif" "path/to/theme"

# With custom placeholder text
./customize-sodosearch.zsh --placeholder-string "Search..." "path/to/theme"

# With all customization options
./customize-sodosearch.zsh --font-family "Arial, sans-serif" --placeholder-string "Search..." "path/to/theme"
```

The script can be run from any directory by using its full path:

```bash
/Ghost/scottleechua/customize-sodosearch.zsh "path/to/theme"
```

## Contract check

Upstream changes to Portal and SodoSearch can break the patches. Two checks catch this:

- `./check-patches.zsh [<output_dir>]` runs both scripts with every option in `--check` mode. It fails if a patch no longer applies or a build fails. Run it after syncing the fork. With `<output_dir>`, it saves the logs and the patched source as diffs.
- `contract.md` lists what each patch assumes about upstream that a patch that applies can still get wrong. When you add or change a patch, update its item.

`.github/workflows/portal-contract-check.yml` runs both twice a month (the 1st and 15th) against upstream `TryGhost/Ghost` `main`, when the files that the scripts patch have changed since the commit in `checked-upstream`. If all is well, it opens and merges a PR that updates `checked-upstream`. If not, it opens an issue (or comments on the open one).

The workflow needs:

- The `CLAUDE_CODE_OAUTH_TOKEN` repository secret.
- **Settings → Actions → General → Allow GitHub Actions to create and approve pull requests.**

Run it by hand from the Actions tab (**Portal contract check → Run workflow**).

## Updating dependencies inside portal or sodo-search

Just delete the Ghost directory and rerun a clean setup.

## Syncing with main Ghost repo

1. On GitHub, `Sync fork` on the `develop` branch.
2. On local:
   ```
   git fetch && git pull
   ```

## Guidelines

- Only make changes in `develop` branch; the `upstream` branch is mainly there for reference.
- Only make changes in `scottleechua/` folder. The one exception is `.github/workflows/portal-contract-check.yml`, because GitHub only runs workflows from `.github/workflows/`.

## Resources

- [Ghost developer setup](https://ghost.org/docs/install/source/)
- [Ghost configuration](https://ghost.org/docs/config/)
