# Ghost customizations

Contains:
- `customize-portal.zsh` - generate `portal.min.js` with custom placeholders.
- `generate-sodosearch.zsh` - generate `sodo-search.min.js` and `sodo-search-main.css` for local use.

## Local Dev Setup
Last worked on a Mac (Apple Silicon) with Node v18.10.2 and Yarn 4.8.1. Yarn 1.22.22 was installed globally.

```bash
git clone --recurse-submodules git@github.com:scottleechua/Ghost.git
cd Ghost
git checkout develop

yarn install
yarn setup

cd scottleechua
chmod +x customize-portal.zsh
chmod +x generate-sodosearch.zsh
```

## Customize Portal

```bash
./customize-portal.zsh "Full Name" "example@email.com" "repo/theme"
```

This script will:
1. Replace placeholder text in Portal components with your information
2. Build the Portal
3. Copy the built `portal.min.js` to the specified theme directory
4. Create or update a `PORTAL-VERSION` file with the current Portal version
5. Restore the original placeholder text

The script can be run from any directory by using its full path:

```bash
/Ghost/scottleechua/customize-portal.zsh "Full Name" "example@email.com" "repo/theme"
```

## Generate SodoSearch

```bash
./generate-sodosearch.zsh "repo/theme"
```

This script will:
1. Build SodoSearch
2. Copy the built `sodo-search.min.js` to your theme directory
3. Copy and rename `main.css` to `sodo-search-main.css` in your theme directory
4. Create or update a `SODOSEARCH-VERSION` file with the current SodoSearch version

The script can be run from any directory by using its full path:

```bash
/Ghost/scottleechua/generate-sodosearch.zsh "repo/theme"
```

## Guidelines
- Only make changes in `develop` branch.
- Only make changes in `scottleechua/` folder unless absolutely necessary.

## Resources
- [Ghost developer setup](https://ghost.org/docs/install/source/)
- [Ghost configuration](https://ghost.org/docs/config/)