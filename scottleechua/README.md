# Ghost customizations

Contains:
- `customize-portal.zsh`
- `customize-sodosearch.zsh`

## Local Dev Setup
Last worked on a Mac (Apple Silicon) with Node v18.10.2 and Yarn 4.8.1. Yarn 1.22.22 was installed globally.

```bash
git clone --recurse-submodules git@github.com:scottleechua/Ghost.git && cd Ghost
yarn install
yarn setup

cd scottleechua
chmod +x customize-portal.zsh
chmod +x customize-sodosearch.zsh
```

## Customize Portal

```bash
./customize-portal.zsh [--placeholder-name <full name>] [--placeholder-email <email>] [--hide-already-member] <path/to/theme>
```

This script will:
1. Replace placeholder text in Portal components with your information (if `--placeholder-name` and/or `--placeholder-email` are provided)
2. Hide the "Already a member?" message (if `--hide-already-member` is provided)
3. Build the Portal
4. Copy the built `portal.min.js` to your theme directory
5. Create or update a `PORTAL-VERSION` file with the current Portal version
6. Restore the original placeholder text and styles

Examples:
```bash
# Basic usage (only theme path required)
./customize-portal.zsh "path/to/theme"

# With custom name and email
./customize-portal.zsh --placeholder-name "John Doe" --placeholder-email "john@example.com" "path/to/theme"

# Hide the "Already a member?" message
./customize-portal.zsh --hide-already-member "path/to/theme"

# With all customization options
./customize-portal.zsh --placeholder-name "John Doe" --placeholder-email "john@example.com" --hide-already-member "path/to/theme"
```

The script can be run from any directory by using its full path:

```bash
/Ghost/scottleechua/customize-portal.zsh "path/to/theme"
```

## Customize SodoSearch

```bash
./customize-sodosearch.zsh [--placeholder-string <string>] [--placeholder-color <hexcode>] [--placeholder-font <list of fonts>] <path/to/theme>
```

This script will:
1. Replace the searchbar placeholder text (if `--placeholder-string` is provided)
2. Apply custom styles to the placeholder text (if `--placeholder-color` and/or `--placeholder-font` are provided)
3. Build SodoSearch
4. Copy the built `sodo-search.min.js` to your theme directory
5. Copy and rename `main.css` to `sodo-search-main.css` to your theme directory
6. Create or update a `SODOSEARCH-VERSION` file with the current SodoSearch version
7. Restore the original search placeholder text and styles

Examples:
```bash
# Basic usage (only theme path required)
./customize-sodosearch.zsh "path/to/theme"

# With custom placeholder text
./customize-sodosearch.zsh --placeholder-string "Search..." "path/to/theme"

# With custom placeholder text and color
./customize-sodosearch.zsh --placeholder-string "Search..." --placeholder-color "#6B7280" "path/to/theme"

# With all customization options
./customize-sodosearch.zsh --placeholder-string "Search..." --placeholder-color "#6B7280" --placeholder-font "'Arial, sans-serif'" "path/to/theme"
```

The script can be run from any directory by using its full path:

```bash
/Ghost/scottleechua/customize-sodosearch.zsh "path/to/theme"
```

## Guidelines
- Pull changes from upstream before generating new versions of files.
- Only make changes in `develop` branch; the `main` branch is there for reference.
- Only make changes in `scottleechua/` folder unless absolutely necessary.

## Resources
- [Ghost developer setup](https://ghost.org/docs/install/source/)
- [Ghost configuration](https://ghost.org/docs/config/)