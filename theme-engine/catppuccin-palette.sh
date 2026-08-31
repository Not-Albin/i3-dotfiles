#!/usr/bin/env bash
# Catppuccin Color Palette - All 4 Variants
# Source this file to get color variables for any variant
# Usage: source catppuccin-palette.sh && get_colors mocha

# ============================================================================
# CATPPUCCIN PALETTE DATA
# ============================================================================

# Ordered list of all color keys (single source of truth)
CATPPUCCIN_KEYS=(
    rosewater flamingo pink mauve red maroon peach yellow green teal sky
    sapphire blue lavender text subtext1 subtext0 overlay2 overlay1 overlay0
    surface2 surface1 surface0 base mantle crust
)

# All variants in a single associative array of arrays
declare -A CATPPUCCIN_LATTE=(
    [rosewater]="dc8a78"   [flamingo]="dd7878"   [pink]="ea76cb"      [mauve]="8839ef"
    [red]="d20f39"         [maroon]="e64553"     [peach]="fe640b"     [yellow]="df8e1d"
    [green]="40a02b"       [teal]="179299"       [sky]="04a5e5"       [sapphire]="209fb5"
    [blue]="1e66f5"        [lavender]="7287fd"   [text]="4c4f69"      [subtext1]="5c5f77"
    [subtext0]="6c6f85"    [overlay2]="7c7f93"   [overlay1]="8c8fa1"  [overlay0]="9ca0b0"
    [surface2]="acb0be"    [surface1]="bcc0cc"   [surface0]="ccd0da"  [base]="eff1f5"
    [mantle]="e6e9ef"      [crust]="dce0e8"
)

declare -A CATPPUCCIN_FRAPPE=(
    [rosewater]="f2d5cf"   [flamingo]="eebebe"   [pink]="f4b8e4"      [mauve]="ca9ee6"
    [red]="e78284"         [maroon]="ea999c"     [peach]="ef9f76"     [yellow]="e5c890"
    [green]="a6d189"       [teal]="81c8be"       [sky]="99d1db"       [sapphire]="85c1dc"
    [blue]="8caaee"        [lavender]="babbf1"   [text]="c6d0f5"      [subtext1]="b5bfe2"
    [subtext0]="a5adce"    [overlay2]="949cbb"   [overlay1]="838ba7"  [overlay0]="737994"
    [surface2]="626880"    [surface1]="51576d"   [surface0]="414559"  [base]="303446"
    [mantle]="292c3c"      [crust]="232634"
)

declare -A CATPPUCCIN_MACCHIATO=(
    [rosewater]="f4dbd6"   [flamingo]="f0c6c6"   [pink]="f5bde6"      [mauve]="c6a0f6"
    [red]="ed8796"         [maroon]="ee99a0"     [peach]="f5a97f"     [yellow]="eed49f"
    [green]="a6da95"       [teal]="8bd5ca"       [sky]="91d7e3"       [sapphire]="7dc4e4"
    [blue]="8aadf4"        [lavender]="b7bdf8"   [text]="cad3f5"      [subtext1]="b8c0e0"
    [subtext0]="a5adcb"    [overlay2]="939ab7"   [overlay1]="8087a2"  [overlay0]="6e738d"
    [surface2]="5b6078"    [surface1]="494d64"   [surface0]="363a4f"  [base]="24273a"
    [mantle]="1e2030"      [crust]="181926"
)

declare -A CATPPUCCIN_MOCHA=(
    [rosewater]="f5e0dc"   [flamingo]="f2cdcd"   [pink]="f5c2e7"      [mauve]="cba6f7"
    [red]="f38ba8"         [maroon]="eba0ac"     [peach]="fab387"     [yellow]="f9e2af"
    [green]="a6e3a1"       [teal]="94e2d5"       [sky]="89dceb"       [sapphire]="74c7ec"
    [blue]="89b4fa"        [lavender]="b4befe"   [text]="cdd6f4"      [subtext1]="bac2de"
    [subtext0]="a6adc8"    [overlay2]="9399b2"   [overlay1]="7f849c"  [overlay0]="6c7086"
    [surface2]="585b70"    [surface1]="45475a"   [surface0]="313244"  [base]="1e1e2e"
    [mantle]="181825"      [crust]="11111b"
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Get all available variants
get_variants() {
    echo "latte frappe macchiato mocha"
}

# Validate variant name
is_valid_variant() {
    local variant="$1"
    [[ " latte frappe macchiato mocha " == *" $variant "* ]]
}

# Get color value for a variant
# Usage: get_color mocha blue
get_color() {
    local variant="$1"
    local color_name="$2"
    local -n palette="CATPPUCCIN_${variant^^}"

    if [[ -z "${palette[$color_name]+_}" ]]; then
        echo "ERROR: Color '$color_name' not found in variant '$variant'" >&2
        return 1
    fi
    echo "#${palette[$color_name]}"
}

# Get all colors for a variant as associative array with # prefix
# Usage: declare -A colors; load_colors mocha colors
load_colors() {
    local variant="$1"
    local -n target_array="$2"
    local -n palette="CATPPUCCIN_${variant^^}"

    for key in "${CATPPUCCIN_KEYS[@]}"; do
        target_array[$key]="#${palette[$key]}"
    done
}

# Get variant display name
get_variant_display_name() {
    local variant="$1"
    case "$variant" in
        latte)    echo "Catppuccin Latte (Light)" ;;
        frappe)   echo "Catppuccin Frappé (Medium-dark)" ;;
        macchiato) echo "Catppuccin Macchiato (Dark-medium)" ;;
        mocha)    echo "Catppuccin Mocha (Dark)" ;;
        *)        echo "Unknown" ;;
    esac
}

# Export all colors as environment variables
# Usage: export_colors mocha
export_colors() {
    local variant="$1"
    local -n palette="CATPPUCCIN_${variant^^}"

    for key in "${CATPPUCCIN_KEYS[@]}"; do
        local var_name="CATPPUCCIN_${key^^}"
        export "$var_name=#${palette[$key]}"
    done
    export CATPPUCCIN_VARIANT="$variant"
}

# Print all colors for a variant (for debugging)
print_colors() {
    local variant="$1"
    local -n palette="CATPPUCCIN_${variant^^}"

    echo "=== $(get_variant_display_name "$variant") ==="
    for key in "${CATPPUCCIN_KEYS[@]}"; do
        printf "  %-12s %s\n" "$key:" "#${palette[$key]}"
    done
}

# Generate a config file from template
# Usage: generate_config template_file output_file variant
generate_config() {
    local template_file="$1"
    local output_file="$2"
    local variant="$3"

    if [[ ! -f "$template_file" ]]; then
        echo "ERROR: Template not found: $template_file" >&2
        return 1
    fi

    # Load colors for the variant
    local -A colors
    load_colors "$variant" colors

    # Read template and replace {{color_name}} with actual values
    local content
    content=$(cat "$template_file")

    # Replace all {{color_name}} patterns
    for key in "${CATPPUCCIN_KEYS[@]}"; do
        local placeholder="{{${key}}}"
        local value="${colors[$key]}"
        content="${content//$placeholder/$value}"
    done

    # Also replace {{variant}} with variant name
    content="${content//\{\{variant\}\}/$variant}"

    # Write output
    mkdir -p "$(dirname "$output_file")"
    echo "$content" > "$output_file"
}

# Print color swatch for preview (used by theme-switcher.sh)
print_color_swatch() {
    local variant="$1"
    local -A colors
    load_colors "$variant" colors

    swatch() {
        local hex="$1"
        local r=$((16#${hex:1:2}))
        local g=$((16#${hex:3:2}))
        local b=$((16#${hex:5:2}))
        echo -ne "\e[48;2;${r};${g};${b}m    \e[0m"
    }

    # Source colors for BOLD/NC
    if [[ -z "${BOLD:-}" ]]; then
        source "$(dirname "${BASH_SOURCE[0]}")/../lib/colors.sh"
    fi

    echo -e "${BOLD}Color Palette:${NC}"
    echo -e "  ┌─────────────────────────────────────────────────────┐"
    printf "  │ ${BOLD}%-12s${NC} │ " "base"
    swatch "${colors[base]}"
    echo -e " ${colors[base]} │"
    printf "  │ ${BOLD}%-12s${NC} │ " "mantle"
    swatch "${colors[mantle]}"
    echo -e " ${colors[mantle]} │"
    printf "  │ ${BOLD}%-12s${NC} │ " "surface0"
    swatch "${colors[surface0]}"
    echo -e " ${colors[surface0]} │"
    printf "  │ ${BOLD}%-12s${NC} │ " "text"
    swatch "${colors[text]}"
    echo -e " ${colors[text]} │"
    echo -e "  ├─────────────────────────────────────────────────────┤"
    printf "  │ ${BOLD}%-12s${NC} │ " "blue"
    swatch "${colors[blue]}"
    echo -e " ${colors[blue]} │"
    printf "  │ ${BOLD}%-12s${NC} │ " "mauve"
    swatch "${colors[mauve]}"
    echo -e " ${colors[mauve]} │"
    printf "  │ ${BOLD}%-12s${NC} │ " "green"
    swatch "${colors[green]}"
    echo -e " ${colors[green]} │"
    printf "  │ ${BOLD}%-12s${NC} │ " "red"
    swatch "${colors[red]}"
    echo -e " ${colors[red]} │"
    echo -e "  └─────────────────────────────────────────────────────┘"
    echo
}

# ============================================================================
# MAIN (when run directly)
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script executed directly
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 <variant> [color_name]"
        echo "Variants: $(get_variants)"
        echo "Example: $0 mocha blue"
        echo "Example: $0 mocha  # prints all colors"
        exit 1
    fi

    variant="$1"

    if ! is_valid_variant "$variant"; then
        echo "Invalid variant: $variant"
        echo "Valid variants: $(get_variants)"
        exit 1
    fi

    if [[ $# -eq 2 ]]; then
        get_color "$variant" "$2"
    else
        print_colors "$variant"
    fi
fi