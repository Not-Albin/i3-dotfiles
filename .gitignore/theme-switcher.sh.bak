#!/usr/bin/env bash
# Catppuccin Theme Switcher
# Renders a chosen Catppuccin variant from the immutable canonical-configs/ into a
# staging directory (install-time), or recolors ~/.config in place (runtime).
# Only color hex values are changed - all other config content is left exactly as-is.
#
# Usage:
#   ./theme-switcher.sh <variant> --render-to <dir>   # Render canonical -> staging dir
#   ./theme-switcher.sh <variant> --apply-home        # Recolor ~/.config in place
#   ./theme-switcher.sh <variant> --preview           # Show color swatch preview

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENGINE_DIR="$SCRIPT_DIR/theme-engine"
REPO_HOME="$SCRIPT_DIR/canonical-configs"

# The single source-of-truth variant that canonical-configs/.config always holds.
# This is baked into the script; canonical-configs is never modified after reset.
REFERENCE_VARIANT="mocha"

# Source shared libraries and color palette
source "$SCRIPT_DIR/lib/logging.sh"
source "$ENGINE_DIR/catppuccin-palette.sh"

# CONFIGURATION
VARIANT=""
PREVIEW=false
RENDER_TO=""
APPLY_HOME=false
HOME_DIR=""

# HEX REPLACEMENT

# Emit a sed script that rewrites every current-variant palette hex in a file
# to the corresponding target-variant hex. Emits both lowercase and UPPERCASE
# forms so each file's existing case style is preserved.
build_sed_script() {
    local current_variant_name="$1" target_variant_name="$2"
    local -A cur_colors tgt_colors
    load_colors "$current_variant_name" cur_colors
    load_colors "$target_variant_name" tgt_colors

    local key src_l src_u dst_l dst_u
    for key in "${!cur_colors[@]}"; do
        src_l="${cur_colors[$key]#\#}"
        src_u="$(echo "$src_l" | tr '[:lower:]' '[:upper:]')"
        dst_l="${tgt_colors[$key]#\#}"
        dst_u="$(echo "$dst_l" | tr '[:lower:]' '[:upper:]')"
        printf 's/#%s/#%s/g;' "$src_l" "$dst_l"
        printf 's/#%s/#%s/g;' "$src_u" "$dst_u"
    done
}

# True if the file contains at least one hex from the variant's palette
file_has_variant_colors() {
    local variant_name="$1" file="$2"
    local -A pal_colors
    load_colors "$variant_name" pal_colors

    local key
    for key in "${!pal_colors[@]}"; do
        if grep -qiE "#${pal_colors[$key]#\#}" "$file"; then
            return 0
        fi
    done
    return 1
}

# Shared recoloring logic - applies sed script to files in a directory
recolor_directory() {
    local sed_script="$1"
    local target_dir="$2"
    local changed=0

    while IFS= read -r -d '' f; do
        case "$f" in
            */Backup/*|*/Backup_conf/*) continue ;;
        esac
        grep -qE '#[0-9a-fA-F]{6}' "$f" || continue

        sed -i "$sed_script" "$f"
        ((changed+=1))
    done < <(find "$target_dir" -type f -print0)

    echo "$changed"
}

# RENDER TO STAGING DIRECTORY (install-time)

render_to_staging() {
    local target="$1"
    local staging="$2"
    local src_config="$REPO_HOME/config"
    local dst_config="$staging/.config"

    if [[ "$target" == "$REFERENCE_VARIANT" ]]; then
        # No recoloring needed - just copy canonical to staging
        rm -rf "$dst_config"
        cp -r "$src_config" "$dst_config"
        log_info "Copied canonical-configs to $staging/.config (no recoloring needed)"
        return 0
    fi

    log_info "Rendering $(get_variant_display_name "$target") from $REFERENCE_VARIANT to $staging/.config"

    # 1. Fresh copy canonical .config -> staging
    rm -rf "$dst_config"
    cp -r "$src_config" "$dst_config"

    # 2. Build sed script: REFERENCE_VARIANT -> target
    local sed_script
    sed_script="$(build_sed_script "$REFERENCE_VARIANT" "$target")"

    # 3. Recolor all palette-holding files under staging, skip Backup/
    local changed
    changed=$(recolor_directory "$sed_script" "$dst_config")

    log_success "Rendered $changed file(s) to $staging/.config"
}

# APPLY TO HOME CONFIG (runtime switching)

apply_to_home() {
    local target="$1"
    local home_config="${HOME_DIR:-$HOME/.config}"
    local home_parent="$(dirname "$home_config")"
    local backup_dir="$home_parent/.theme-backup-$(date +%Y%m%d-%H%M%S)"

    if [[ "$target" == "$REFERENCE_VARIANT" && ! -d "$home_config" ]]; then
        log_warn "$home_config does not exist yet; nothing to recolor"
        return 0
    fi

    log_info "Applying $(get_variant_display_name "$target") to $home_config"

    # Backup config before in-place recolor
    mkdir -p "$backup_dir"
    cp -r "$home_config" "$backup_dir/.config"

    local current_variant
    local variant_file="$home_config/.catppuccin-variant"

    if [[ ! -f "$variant_file" ]]; then
        log_warn "No .catppuccin-variant file found at $variant_file; assuming reference variant ($REFERENCE_VARIANT)"
        current_variant="$REFERENCE_VARIANT"
    else
        current_variant="$(cat "$variant_file")"
        if ! is_valid_variant "$current_variant"; then
            log_error "Invalid variant '$current_variant' in $variant_file; assuming reference variant ($REFERENCE_VARIANT)"
            current_variant="$REFERENCE_VARIANT"
        fi
    fi

    local sed_script
    sed_script="$(build_sed_script "$current_variant" "$target")"

    local changed
    changed=$(recolor_directory "$sed_script" "$home_config")

    if [[ "$changed" -eq 0 ]]; then
        log_warn "No palette colors found to change"
    fi

    printf '%s\n' "$target" > "$variant_file"

    log_success "Applied $(get_variant_display_name "$target") to $home_config ($changed file(s) recolored)"
    log_info "Backup saved to: $backup_dir"
}

# PREVIEW MODE - uses palette's print_color_swatch

preview_variant() {
    local variant="$1"

    echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  Preview: $(get_variant_display_name "$variant")${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"

    print_color_swatch "$variant"
}

# USAGE

print_usage() {
    echo -e "$(cat << EOF
${BOLD}Catppuccin Theme Switcher${NC}

Renders a Catppuccin variant from the immutable canonical-configs/ into a staging
directory (for installation), or recolors ~/.config in place (for runtime switching).
Only color hex values change - no other config content is touched.

${BOLD}Usage:${NC}
    $0 <variant> [options]

${BOLD}Variants:${NC}
    latte       Catppuccin Latte (Light)
    frappe      Catppuccin Frappé (Medium-dark)
    macchiato   Catppuccin Macchiato (Dark-medium)
    mocha       Catppuccin Mocha (Dark) - reference variant

${BOLD}Options:${NC}
    --preview         Show color swatch preview without applying
    --render-to DIR   Render canonical-configs into DIR/.config in the variant
    --apply-home      Recolor ~/.config in place to the variant
    --home-dir DIR    Override home config directory (for testing, default: \$HOME/.config)
    -h, --help        Show this help

${BOLD}Examples:${NC}
    $0 mocha --preview                # Preview mocha colors
    $0 latte --render-to /tmp/stage   # Render latte to staging dir
    $0 frappe --apply-home            # Recolor ~/.config to frappe
    $0 latte --apply-home --home-dir /tmp/test-home/.config  # Test with custom home dir

${BOLD}Files recolored (in staging or ~/.config):${NC}
    .config/polybar/colors.ini
    .config/rofi/colors.rasi
    .config/rofi/catppuccin-mocha.rasi
    .config/dunst/dunstrc
    .config/kitty/kitty.conf
    .config/kitty/catppuccin-mocha.conf
    .config/alacritty/colors.toml
    .config/gtk-3.0/colors.css
    .config/gtk-4.0/colors.css
    .config/i3/config
    .config/btop/themes/catppuccin_mocha.theme
    ... (any file containing a catppuccin palette hex)

${BOLD}Notes:${NC}
    - canonical-configs/ is immutable and always holds the $REFERENCE_VARIANT palette.
    - The staging directory is a scratch space; it can be deleted after installation.
    - Runtime switching (--apply-home) creates a backup at ~/.theme-backup-<timestamp>.
    - Files under ${BOLD}Backup/${NC} and ${BOLD}Backup_conf/${NC} are left untouched.
    - Non-palette colors (custom shades) are left as-is.

EOF
)"
}

# ARGUMENT PARSING

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --preview)
                PREVIEW=true
                ;;
            --render-to)
                RENDER_TO="${2:-}"
                [[ -z "$RENDER_TO" ]] && { log_error "--render-to requires a directory argument"; exit 1; }
                shift
                ;;
            --apply-home)
                APPLY_HOME=true
                ;;
            --home-dir)
                HOME_DIR="${2:-}"
                [[ -z "$HOME_DIR" ]] && { log_error "--home-dir requires a directory argument"; exit 1; }
                shift
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                print_usage
                exit 1
                ;;
            *)
                if [[ -z "$VARIANT" ]]; then
                    VARIANT="$1"
                else
                    log_error "Unexpected argument: $1"
                    print_usage
                    exit 1
                fi
                ;;
        esac
        shift
    done
}

# MAIN

main() {
    parse_args "$@"

    if [[ -z "$VARIANT" ]]; then
        print_usage
        exit 0
    fi

    if ! is_valid_variant "$VARIANT"; then
        log_error "Invalid variant: $VARIANT"
        echo "Valid variants: $(get_variants)"
        exit 1
    fi

    # Validate mutually exclusive modes
    local mode_count=0
    [[ "$PREVIEW" == true ]] && ((mode_count+=1))
    [[ -n "$RENDER_TO" ]] && ((mode_count+=1))
    [[ "$APPLY_HOME" == true ]] && ((mode_count+=1))
    if [[ $mode_count -gt 1 ]]; then
        log_error "Choose exactly one mode: --preview, --render-to, or --apply-home"
        exit 1
    fi

    if [[ "$PREVIEW" == true ]]; then
        preview_variant "$VARIANT"
    elif [[ -n "$RENDER_TO" ]]; then
        mkdir -p "$RENDER_TO"
        render_to_staging "$VARIANT" "$RENDER_TO"
    elif [[ "$APPLY_HOME" == true ]]; then
        apply_to_home "$VARIANT"
    else
        # Default: preview
        preview_variant "$VARIANT"
    fi
}

main "$@"
