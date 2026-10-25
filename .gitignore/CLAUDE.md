# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## High-level Code Architecture and Structure

The repository is structured as follows:

-   `install.sh`: The main installation script responsible for detecting the OS, installing dependencies, backing up existing configurations, rendering Catppuccin themes to config files, and installing system-wide scripts and fonts.
-   `theme-switcher.sh`: A script to manage Catppuccin theme variants. It can render a chosen variant into a staging directory (for `install.sh`) or recolor existing `~/.config` files in place at runtime. It relies on `catppuccin-palette.sh` for color definitions.
-   `theme-engine/catppuccin-palette.sh`: Defines the Catppuccin color palettes for Latte, Frappé, Macchiato, and Mocha variants. It also provides helper functions to retrieve colors and generate configs.
-   `canonical-configs/`: This directory contains the "golden" or reference configuration files for various applications (i3, Polybar, Rofi, Kitty, Alacritty, Dunst, etc.). These configs are written in the `mocha` variant by default and are used as templates for `theme-switcher.sh`.
-   `usr/`: Contains system-wide configurations, primarily scripts for `/usr/local/bin` (e.g., `volume_control`, `brightness_control`, `screenshot`, `rofi-powermenu`) and fonts for `/usr/share/fonts`). These scripts are often bound to i3 hotkeys.
-   `theme-engine/templates/`: Contains templates for generating configuration files for applications like Polybar and Rofi, which use placeholders like `{{base}}` or `{{text}}` that are replaced by `catppuccin-palette.sh` during the rendering process.

The core workflow involves `install.sh` using `theme-switcher.sh` to apply the chosen Catppuccin variant to the dotfiles found in `canonical-configs/`. These themed dotfiles are then copied to the user's `~/.config` directory. System-level scripts and fonts are copied from `usr/` to their respective system locations.

## Common Development Tasks

### Installation

-   **Full Installation**: `./install.sh`
-   **Dry Run (preview changes)**: `./install.sh --dry-run`
-   **Skip dependency installation**: `./install.sh --skip-deps`
-   **Install a specific variant**: `./install.sh --variant=<variant_name>` (e.g., `mocha`, `latte`, `frappe`, `macchiato`)

### Theme Management

-   **Preview a theme variant**: `./theme-switcher.sh <variant> --preview`
-   **Recolor ~/.config in place**: `./theme-switcher.sh <variant> --apply-home`
-   **Render theme to a staging directory**: `./theme-switcher.sh <variant> --render-to <directory>`

### Working with `catppuccin-palette.sh`

-   **Get available variants**: `source theme-engine/catppuccin-palette.sh && get_variants`
-   **Get a specific color for a variant**: `source theme-engine/catppuccin-palette.sh && get_color mocha blue`
-   **Print all colors for a variant**: `source theme-engine/catppuccin-palette.sh && print_colors mocha`

### Key i3 Bindings (after installation and i3 session login)

-   `Mod+Return`: Open terminal (kitty)
-   `Mod+D`: Application launcher (rofi)
-   `Mod+A`: Run launcher (rofi drun)
-   `Mod+Shift+Q`: Close window
-   `Mod+1-0`: Switch workspace
-   `Mod+Shift+1-0`: Move window to workspace
-   `Mod+X`: Power menu
-   `Mod+C`: Screenshot menu
-   `Mod+Z`: Music player (ncmpcpp)
-   `Mod` refers to the Super/Windows key.