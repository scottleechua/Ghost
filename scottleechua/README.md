# Ghost customizations

Contains:
- `customize-portal.zsh`
- `customize-sodosearch.zsh`

## Local Dev Setup
Last worked on a Mac (Apple Silicon) with Node v22.18.0, Perl 5.34.1, and Yarn 1.22.22.

**Important: Docker should be open before running the below commands.**

```bash
git clone --recurse-submodules git@github.com:scottleechua/Ghost.git && cd Ghost
yarn setup
```

## Customize Portal

```bash
./customize-portal.zsh [--placeholder-name <full name>] [--placeholder-email <email>] [--hide-already-member] [--hide-site-title] [--hide-powered-by-ghost] [--replace-icon-with-logo] [--enable-dark-mode] [--custom-accents <primary_light> <secondary_light> <primary_dark> <secondary_dark>] <path/to/theme>
```

This script will:
1. Replace placeholder name/email in Portal input fields (if `--placeholder-name` and/or `--placeholder-email` are provided)
2. Hide the "Already a member?" message (if `--hide-already-member` is provided)
3. Hide the site title on the signin and signup pages (if `--hide-site-title` is provided)
4. Hide the "Powered by Ghost" badge (if `--hide-powered-by-ghost` is provided)
5. Replace the site icon with the site logo (if `--replace-icon-with-logo` is provided)
6. Enable dark mode synced to the parent page's `dark` class (if `--enable-dark-mode` is provided)
7. Apply custom accent colors for light and dark mode (if `--custom-accents` is provided; requires `--enable-dark-mode`)
8. Build a minified Portal with `en` locale only
9. Copy the built `portal.min.js` to your theme directory
10. Create or update a `PORTAL-VERSION` file with the current Portal version
11. Restore all modified source files

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
./customize-sodosearch.zsh [--font-family <list of fonts>] [--placeholder-string <string>] <path/to/theme>
```

This script will:
1. Apply custom font family to the whole search element (if `--font-family` is provided)
2. Replace the searchbar placeholder text (if `--placeholder-string` is provided)
3. Build a minified SodoSearch with `en` locale only
4. Copy the built `sodo-search.min.js` to your theme directory
5. Copy and rename `main.css` to `sodo-search-main.css` to your theme directory
6. Create or update a `SODOSEARCH-VERSION` file with the current SodoSearch version
7. Restore the original search placeholder text and styles

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

## Updating dependencies inside portal or sodo-search

Just delete the Ghost directory and rerun a clean setup.

## Syncing with main Ghost repo

1, On GitHub, `Sync fork` on the `develop` branch.
2. On local:
    ```
    git fetch && git pull
    ```

## Guidelines
- Only make changes in `develop` branch; the `upstream` branch is mainly there for reference.
- Only make changes in `scottleechua/` folder.

## Resources
- [Ghost developer setup](https://ghost.org/docs/install/source/)
- [Ghost configuration](https://ghost.org/docs/config/)
