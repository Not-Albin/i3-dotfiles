#!/usr/bin/env bash
# Catppuccin Theme Dotfiles Installation Script
# Supports: Arch, Debian/Ubuntu, Fedora, openSUSE, NixOS, Alpine
# Usage: ./install.sh [--dry-run] [--skip-deps] [--variant=<variant>]

set -euo pipefail

# CONFIGURATION

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${HOME}"
USR_DIR="/usr"
BACKUP_DIR="${HOME}/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

# Catppuccin variants
CATPPUCCIN_VARIANTS=("latte" "frappe" "macchiato" "mocha")
SELECTED_VARIANT="mocha"  # Default

# Flags
DRY_RUN=false
SKIP_DEPS=false
VERBOSE=false

# Config lists (extracted for readability)
CONFIGS_TO_BACKUP=(
    ".config/alacritty" ".config/btop" ".config/dunst" ".config/gtk-3.0"
    ".config/gtk-4.0" ".config/i3" ".config/kitty" ".config/ncmpcpp"
    ".config/networkmanager-dmenu" ".config/picom" ".config/polybar"
    ".config/qt5ct" ".config/rofi" ".config/qt6ct"
)

SCRIPTS_TO_BACKUP=(
    "asus_fan_listener" "asus_fan_toggle" "battery_listener"
    "brightness_control" "brightness_level" "lock"
    "microphone_mute" "rofi-powermenu" "rofi-screenshot"
    "screenshot" "touchpad_toggle" "volume_control"
    "volume_level" "volume_mute"
)

VERIFY_COMMANDS=(
    "command -v i3:i3 window manager"
    "command -v polybar:Polybar"
    "command -v rofi:Rofi"
    "command -v kitty:Kitty terminal"
    "command -v alacritty:Alacritty terminal"
    "command -v picom:Picom compositor"
    "command -v dunst:Dunst notifications"
    "command -v feh:Feh wallpaper setter"
    "command -v btop:Btop monitor"
    "command -v mpd:MPD"
    "command -v ncmpcpp:Ncmpcpp"
    "command -v playerctl:Playerctl"
    "command -v networkmanager_dmenu:NetworkManager dmenu"
    "test -f /usr/local/bin/volume_control:Volume control script"
    "test -f /usr/local/bin/brightness_control:Brightness control script"
    "test -f /usr/local/bin/screenshot:Screenshot script"
    "test -f /usr/local/bin/lock:Lock script"
    "test -f /usr/local/bin/rofi-powermenu:Rofi powermenu"
    "fc-list | grep -qi inter:Inter font"
    "fc-list | grep -qi iosevka:Iosevka Nerd Font"
)

VERIFY_CONFIG_DIRS=(
    "$HOME_DIR/.config/i3"
    "$HOME_DIR/.config/polybar"
    "$HOME_DIR/.config/rofi"
    "$HOME_DIR/.config/kitty"
    "$HOME_DIR/.config/alacritty"
    "$HOME_DIR/.config/picom"
    "$HOME_DIR/.config/dunst"
)

# Source shared libraries
source "$DOTFILES_DIR/lib/logging.sh"

# HELPER FUNCTIONS

confirm() {
    local prompt="$1"
    local default="${2:-n}"
    local reply

    if [[ "$default" == "y" ]]; then
        prompt+=" [Y/n]: "
    else
        prompt+=" [y/N]: "
    fi

    read -r -p "$prompt" reply
    reply="${reply:-$default}"
    [[ "$reply" =~ ^[Yy]$ ]]
}

# OS DETECTION

detect_os() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        OS_ID="${ID}"
        OS_ID_LIKE="${ID_LIKE:-}"
        OS_VERSION="${VERSION_ID:-}"
        OS_NAME="${PRETTY_NAME:-$ID}"
    elif [[ -f /etc/arch-release ]]; then
        OS_ID="arch"
        OS_NAME="Arch Linux"
    elif [[ -f /etc/debian_version ]]; then
        OS_ID="debian"
        OS_NAME="Debian"
    elif [[ -f /etc/fedora-release ]]; then
        OS_ID="fedora"
        OS_NAME="Fedora"
    elif [[ -f /etc/alpine-release ]]; then
        OS_ID="alpine"
        OS_NAME="Alpine Linux"
    else
        OS_ID="unknown"
        OS_NAME="Unknown"
    fi

    log_info "Detected OS: ${OS_NAME} (${OS_ID})"
}

# PACKAGE MANAGER DETECTION

get_package_manager() {
    case "$OS_ID" in
        arch|manjaro|endeavouros|garuda|artix)
            PM="pacman"
            PM_INSTALL="sudo pacman -S --needed --noconfirm"
            PM_UPDATE="sudo pacman -Sy"
            AUR_HELPER=""
            if command -v yay &>/dev/null; then
                AUR_HELPER="yay"
            elif command -v paru &>/dev/null; then
                AUR_HELPER="paru"
            fi
            ;;
        debian|ubuntu|linuxmint|pop|elementary|zorin|kali)
            PM="apt"
            PM_INSTALL="sudo apt install -y"
            PM_UPDATE="sudo apt update"
            ;;
        fedora|rhel|centos|rocky|almalinux|nobara)
            PM="dnf"
            PM_INSTALL="sudo dnf install -y"
            PM_UPDATE="sudo dnf check-update || true"
            ;;
        opensuse*|suse)
            PM="zypper"
            PM_INSTALL="sudo zypper install -y"
            PM_UPDATE="sudo zypper refresh"
            ;;
        nixos)
            PM="nix"
            PM_INSTALL="nix profile install"
            PM_UPDATE="nix channel-update"
            ;;
        alpine)
            PM="apk"
            PM_INSTALL="sudo apk add"
            PM_UPDATE="sudo apk update"
            ;;
        *)
            log_error "Unsupported OS: $OS_ID"
            exit 1
            ;;
    esac
    log_info "Package manager: $PM"
}

# PACKAGE DEFINITIONS - using functions for maintainability

# Base packages common to most distros
get_common_packages() {
    cat << 'EOF'
i3:i3 window manager
i3status:i3 status bar
polybar:Status bar
rofi:Application launcher
picom:Compositor
dunst:Notification daemon
feh:Wallpaper setter
xss-lock:Screen locker for X11
xsettingsd:X settings daemon
kitty:GPU-accelerated terminal
alacritty:GPU-accelerated terminal
btop:Resource monitor
mpd:Music player daemon
ncmpcpp:MPD client
pulseaudio:Audio server
pavucontrol:PulseAudio volume control
playerctl:Media player controller
scrot:Screenshot tool
maim:Screenshot tool (alternative)
grim:Wayland screenshot tool
slurp:Wayland region selector
wl-clipboard:Wayland clipboard
blueman:Bluetooth manager
bluez:Bluetooth daemon
papirus-icon-theme:Papirus icon theme
qt5ct:Qt5 configuration tool
qt6ct:Qt6 configuration tool
git:Git version control
unzip:Unzip utility
curl:cURL
wget:wget
EOF
}

# Distro-specific package mappings (package_name:description)
get_packages_for_distro() {
    case "$OS_ID" in
        arch|manjaro|endeavouros|garuda|artix)
            cat << 'EOF'
i3-wm:i3 window manager
i3lock-color:i3lock with color support
networkmanager:Network management
networkmanager-dmenu:NetworkManager dmenu script (AUR)
pulseaudio-alsa:ALSA plugin for PulseAudio
xorg-xrandr:X RandR CLI
xorg-xset:X settings
xorg-xprop:X property utility
xorg-xwininfo:X window info utility
xorg-xkill:X kill utility
xorg-xinput:X input utility
xorg-xbacklight:X backlight control
mate-polkit:PolicyKit authentication agent
polkit-gnome:GNOME PolicyKit agent
bluez-utils:Bluetooth utilities
inter-font:Inter font family
ttf-iosevka-nerd:Iosevka Nerd Font
noto-fonts-emoji:Emoji font
ttf-font-awesome:Font Awesome
gtk3:GTK3 toolkit
gtk4:GTK4 toolkit
base-devel:Build tools (for AUR)
EOF
            ;;
        debian|ubuntu|linuxmint|pop|elementary|zorin|kali)
            cat << 'EOF'
i3-wm:i3 window manager
i3lock-fancy:i3lock with color support
network-manager:Network management
networkmanager-dmenu:NetworkManager dmenu script (may need manual install)
pulseaudio-utils:PulseAudio utils
x11-xserver-utils:xrandr, xset, etc.
x11-apps:xprop, xwininfo, xkill
xbacklight:X backlight control
mate-polkit:PolicyKit authentication agent
policykit-1-gnome:GNOME PolicyKit agent
fonts-inter:Inter font family
fonts-iosevka-nerd:Iosevka Nerd Font
fonts-noto-color-emoji:Emoji font
fonts-font-awesome:Font Awesome
libgtk-3-0:GTK3 toolkit
libgtk-4-1:GTK4 toolkit
build-essential:Build tools
EOF
            ;;
        fedora|rhel|centos|rocky|almalinux|nobara)
            cat << 'EOF'
i3:i3 window manager
i3lock-color:i3lock with color support
NetworkManager:Network management
networkmanager-dmenu:NetworkManager dmenu script (may need manual install)
pulseaudio-utils:PulseAudio utils
xorg-x11-server-utils:xrandr, xset, etc.
xorg-x11-apps:xprop, xwininfo, xkill
xbacklight:X backlight control
mate-polkit:PolicyKit authentication agent
polkit-gnome:GNOME PolicyKit agent
google-inter-fonts:Inter font family
iosevka-fonts:Iosevka font
google-noto-emoji-fonts:Emoji font
fontawesome-fonts:Font Awesome
gtk3:GTK3 toolkit
gtk4:GTK4 toolkit
@development-tools:Build tools
EOF
            ;;
        opensuse*|suse)
            cat << 'EOF'
i3:i3 window manager
i3lock-color:i3lock with color support
NetworkManager:Network management
pulseaudio-utils:PulseAudio utils
xrandr:xrandr
xset:xset
xprop:xprop
xwininfo:xwininfo
xkill:xkill
xbacklight:X backlight control
mate-polkit:PolicyKit authentication agent
polkit-gnome:GNOME PolicyKit agent
inter-fonts:Inter font family
iosevka-fonts:Iosevka font
noto-coloremoji-fonts:Emoji font
fontawesome-fonts:Font Awesome
gtk3-tools:GTK3 toolkit
gtk4-tools:GTK4 toolkit
patterns-devel-base-devel_basis:Build tools
EOF
            ;;
        nixos)
            cat << 'EOF'
i3:i3 window manager
i3lock-color:i3lock with color support
networkmanager:Network management
pulseaudio:Audio server
xorg.xrandr:xrandr
xorg.xset:xset
xorg.xprop:xprop
xorg.xwininfo:xwininfo
xorg.xkill:xkill
xorg.xbacklight:X backlight control
mate-polkit:PolicyKit authentication agent
polkit-gnome:GNOME PolicyKit agent
inter:Inter font family
iosevka-nerd-fonts:Iosevka Nerd Font
noto-fonts-emoji:Emoji font
font-awesome:Font Awesome
gtk3:GTK3 toolkit
gtk4:GTK4 toolkit
gnumake:Build tools
EOF
            ;;
        alpine)
            cat << 'EOF'
i3wm:i3 window manager
i3lock:i3lock
networkmanager:Network management
pulseaudio-utils:PulseAudio utils
xrandr:xrandr
xset:xset
xprop:xprop
xwininfo:xwininfo
xkill:xkill
xbacklight:X backlight control
polkit-elogind:PolicyKit
font-inter:Inter font family
font-iosevka-nerd:Iosevka Nerd Font
font-noto-emoji:Emoji font
font-awesome:Font Awesome
gtk+3.0:GTK3 toolkit
gtk+4.0:GTK4 toolkit
build-base:Build tools
EOF
            ;;
        *)
            log_error "No package list for OS: $OS_ID"
            exit 1
            ;;
    esac
}

# Build full package list for current OS
build_package_list() {
    local packages=()

    # Add common packages
    while IFS=: read -r pkg desc; do
        [[ -n "$pkg" ]] && packages+=("$pkg")
    done < <(get_common_packages)

    # Add distro-specific packages
    while IFS=: read -r pkg desc; do
        [[ -n "$pkg" ]] && packages+=("$pkg")
    done < <(get_packages_for_distro)

    echo "${packages[@]}"
}

# Get package descriptions for display
get_package_descriptions() {
    {
        get_common_packages
        get_packages_for_distro
    } | while IFS=: read -r pkg desc; do
        echo "$pkg:$desc"
    done
}

install_dependencies() {
    if [[ "$SKIP_DEPS" == true ]]; then
        log_warn "Skipping dependency installation (--skip-deps flag)"
        return 0
    fi

    log_step "Installing dependencies for $OS_NAME..."

    local packages
    read -r -a packages <<< "$(build_package_list)"

    # Update package database
    log_info "Updating package database..."
    run_cmd "$PM_UPDATE" true

    # Install packages
    log_info "Installing ${#packages[@]} packages..."

    if [[ "$PM" == "pacman" && -n "$AUR_HELPER" ]]; then
        # For Arch with AUR helper, use it for all packages
        run_cmd "$AUR_HELPER -S --needed --noconfirm ${packages[*]}" true
    elif [[ "$PM" == "nix" ]]; then
        # NixOS uses nix profile install
        run_cmd "nix profile install ${packages[*]}" true
    else
        run_cmd "$PM_INSTALL ${packages[*]}" true
    fi

    log_success "Dependencies installed!"
}

# CATPPUCCIN VARIANT SELECTION

get_variant_description() {
    local variant="$1"
    case "$variant" in
        latte)    echo "Light theme — warm, soft pastels for bright environments" ;;
        frappe)   echo "Medium-dark — balanced, muted tones for comfortable coding" ;;
        macchiato) echo "Dark-medium — richer contrast, popular for long sessions" ;;
        mocha)    echo "Dark (default) — deep, high-contrast palette for low light" ;;
        *)        echo "" ;;
    esac
}

preview_variant() {
    local variant="$1"
    if [[ -f "$DOTFILES_DIR/theme-switcher.sh" ]]; then
        echo
        "$DOTFILES_DIR/theme-switcher.sh" "$variant" --preview
    else
        log_warn "theme-switcher.sh not found, skipping preview"
    fi
}

select_catppuccin_variant() {
    if [[ -n "${EXPLICIT_VARIANT:-}" ]]; then
        log_step "Catppuccin Theme Variant"
        log_info "Using variant from command line: ${BOLD}$SELECTED_VARIANT${NC}"
        preview_variant "$SELECTED_VARIANT"
        return 0
    fi

    while true; do
        log_step "Catppuccin Theme Variant Selection"
        echo "Choose a variant (enter number or name):"
        echo

        for i in "${!CATPPUCCIN_VARIANTS[@]}"; do
            local variant="${CATPPUCCIN_VARIANTS[$i]}"
            local marker=" "
            [[ "$variant" == "$SELECTED_VARIANT" ]] && marker=" ${GREEN}← current${NC}"
            local desc="$(get_variant_description "$variant")"
            printf "  ${BOLD}%d)${NC} %-12s %s%s\n" "$((i+1))" "$variant" "$desc" "$marker"
        done
        echo

        read -r -p "Selection [1-4 or name]: " choice
        choice="${choice:-$SELECTED_VARIANT}"

        if [[ "$choice" =~ ^[1-4]$ ]]; then
            SELECTED_VARIANT="${CATPPUCCIN_VARIANTS[$((choice-1))]}"
        elif [[ " ${CATPPUCCIN_VARIANTS[*]} " =~ " ${choice} " ]]; then
            SELECTED_VARIANT="$choice"
        else
            log_warn "Invalid selection: '$choice'. Please enter 1-4 or variant name."
            continue
        fi

        log_info "Selected: ${BOLD}$SELECTED_VARIANT${NC} — $(get_variant_description "$SELECTED_VARIANT")"
        preview_variant "$SELECTED_VARIANT"

        echo
        if confirm "Use this variant?" "y"; then
            log_success "Variant locked in: ${BOLD}$SELECTED_VARIANT${NC}"
            break
        else
            log_info "Let's pick another one..."
            echo
        fi
    done
}

# DOTFILES INSTALLATION

backup_existing() {
    log_step "Backing up existing configs..."

    local has_backup=false

    for config in "${CONFIGS_TO_BACKUP[@]}"; do
        if [[ -e "$HOME_DIR/$config" || -L "$HOME_DIR/$config" ]]; then
            if [[ "$has_backup" == false ]]; then
                mkdir -p "$BACKUP_DIR"
                has_backup=true
            fi
            log_info "Backing up $config"
            run_cmd "cp -r \"$HOME_DIR/$config\" \"$BACKUP_DIR/\""
        fi
    done

    # Backup scripts in /usr/local/bin
    for script in "${SCRIPTS_TO_BACKUP[@]}"; do
        if [[ -e "/usr/local/bin/$script" || -L "/usr/local/bin/$script" ]]; then
            if [[ "$has_backup" == false ]]; then
                mkdir -p "$BACKUP_DIR/usr-local-bin"
                has_backup=true
            fi
            log_info "Backing up /usr/local/bin/$script"
            run_cmd "sudo cp \"/usr/local/bin/$script\" \"$BACKUP_DIR/usr-local-bin/\""
        fi
    done

    if [[ "$has_backup" == true ]]; then
        log_success "Backup created at: $BACKUP_DIR"
    else
        log_info "No existing configs to backup"
    fi
}

install_home_configs() {
    log_step "Installing user configs (canonical-configs/)..."

    local home_source="$DOTFILES_DIR/canonical-configs"

    if [[ ! -d "$home_source" ]]; then
        log_error "Source directory not found: $home_source"
        return 1
    fi

    # 1. Create staging dir under DOTFILES_DIR for inspectability on failure
    local staging_dir="$DOTFILES_DIR/.staging-$(date +%Y%m%d-%H%M%S)"
    run_cmd "mkdir -p \"$staging_dir\""

    # 2. Render selected variant into staging
    log_step "Rendering Catppuccin $SELECTED_VARIANT variant to staging..."
    if [[ -f "$DOTFILES_DIR/theme-switcher.sh" ]]; then
        "$DOTFILES_DIR/theme-switcher.sh" "$SELECTED_VARIANT" --render-to "$staging_dir"
    else
        log_error "theme-switcher.sh not found at $DOTFILES_DIR/theme-switcher.sh"
        return 1
    fi

    # 3. Copy rendered staging/.config -> ~/.config
    if [[ -d "$staging_dir/.config" ]]; then
        log_info "Copying rendered .config to $HOME_DIR/.config..."
        run_cmd "cp -r \"$staging_dir/.config/\"* \"$HOME_DIR/.config/\""
    fi

    # 4. Copy Pictures (wallpapers) from canonical (unchanged, no variant)
    if [[ -d "$home_source/Pictures" ]]; then
        log_info "Copying wallpapers..."
        run_cmd "mkdir -p \"$HOME_DIR/Pictures\""
        run_cmd "cp -r \"$home_source/Pictures/\"* \"$HOME_DIR/Pictures/\""
    fi

    # 5. Copy any other files in home root from canonical (no variant)
    for file in "$home_source"/.*; do
        [[ "$file" == "$home_source/." || "$file" == "$home_source/.." ]] && continue
        [[ "$file" == "$home_source/config" ]] && continue
        [[ "$file" == "$home_source/Pictures" ]] && continue
        if [[ -f "$file" ]]; then
            local fname=$(basename "$file")
            log_info "Copying $fname to home..."
            run_cmd "cp \"$file\" \"$HOME_DIR/$fname\""
        fi
    done

    log_success "User configs installed!"
}

install_system_configs() {
    log_step "Installing system configs (usr/)..."

    local usr_source="$DOTFILES_DIR/usr"

    if [[ ! -d "$usr_source" ]]; then
        log_error "Source directory not found: $usr_source"
        return 1
    fi

    # Install scripts to /usr/local/bin
    if [[ -d "$usr_source/local/bin" ]]; then
        log_info "Installing scripts to /usr/local/bin..."
        run_cmd "sudo mkdir -p /usr/local/bin"

        for script in "$usr_source/local/bin"/*; do
            [[ -f "$script" ]] || continue
            local fname=$(basename "$script")
            log_info "Installing $fname..."
            run_cmd "sudo cp \"$script\" \"/usr/local/bin/$fname\""
            run_cmd "sudo chmod +x \"/usr/local/bin/$fname\""
        done
    fi

    # Install icons for scripts
    if [[ -d "$usr_source/local/bin/icons" ]]; then
        log_info "Installing script icons..."
        run_cmd "sudo mkdir -p /usr/local/bin/icons"
        run_cmd "sudo cp -r \"$usr_source/local/bin/icons/\"* /usr/local/bin/icons/"
    fi

    # Install fonts
    if [[ -d "$usr_source/share/fonts" ]]; then
        log_info "Installing fonts..."
        run_cmd "sudo mkdir -p /usr/share/fonts"
        run_cmd "sudo cp -r \"$usr_source/share/fonts/\"* /usr/share/fonts/"
        run_cmd "sudo fc-cache -fv" true
    fi

    # Install GTK themes (if any)
    if [[ -d "$usr_source/share/themes" ]]; then
        log_info "Installing GTK themes..."
        run_cmd "sudo mkdir -p /usr/share/themes"
        run_cmd "sudo cp -r \"$usr_source/share/themes/\"* /usr/share/themes/"
    fi

    log_success "System configs installed!"
}

create_mpd_config() {
    local mpd_dir="$1"
    cat > "$mpd_dir/mpd.conf" << 'EOF'
music_directory    "~/Music"
playlist_directory "~/.config/mpd/playlists"
db_file            "~/.config/mpd/tag_cache"
log_file           "~/.config/mpd/mpd.log"
pid_file           "~/.config/mpd/mpd.pid"
state_file         "~/.config/mpd/state"
sticker_file       "~/.config/mpd/sticker.sql"

bind_to_address    "127.0.0.1"
port               "6600"

auto_update        "yes"
auto_update_depth  "3"

zeroconf_enabled   "yes"
zeroconf_name      "Music Player @ %h"

audio_output {
    type            "pulse"
    name            "PulseAudio Output"
    mixer_type      "software"
}

filesystem_charset "UTF-8"
id3v1_encoding     "UTF-8"
EOF
}

setup_mpd() {
    log_step "Setting up MPD..."

    local mpd_dir="$HOME_DIR/.config/mpd"
    local mpd_music_dir="$HOME_DIR/Music"

    run_cmd "mkdir -p \"$mpd_dir\" \"$mpd_music_dir\" \"$mpd_dir/playlists\""

    if [[ ! -f "$mpd_dir/mpd.conf" ]]; then
        create_mpd_config "$mpd_dir"
        log_info "Created basic MPD config at $mpd_dir/mpd.conf"
    fi

    log_success "MPD setup complete!"
}

create_wallpaper_script() {
    local wallpaper_path="$1"
    cat > "$HOME_DIR/.config/set-wallpaper.sh" << EOF
#!/usr/bin/env bash
# Auto-generated wallpaper setter
WALLPAPER="$wallpaper_path"
[[ -f "\$WALLPAPER" ]] && feh --no-fehbg --bg-fill "\$WALLPAPER"
EOF
    chmod +x "$HOME_DIR/.config/set-wallpaper.sh"
}

set_wallpaper() {
    log_step "Setting up wallpaper..."

    local default_wallpaper="$HOME_DIR/Pictures/wallpapers/wallhaven-6dygpl_1920x1080.png"
    local wallpaper_path=""

    if [[ -f "$default_wallpaper" ]]; then
        wallpaper_path="$default_wallpaper"
    else
        local wallpapers=("$HOME_DIR/Pictures/wallpapers/"*)
        if [[ -f "${wallpapers[0]}" ]]; then
            wallpaper_path="${wallpapers[0]}"
            log_warn "Default wallpaper not found, using: $(basename "$wallpaper_path")"
        fi
    fi

    if [[ -n "$wallpaper_path" ]]; then
        log_info "Setting wallpaper: $(basename "$wallpaper_path")"
        run_cmd "feh --no-fehbg --bg-fill \"$wallpaper_path\""
        create_wallpaper_script "$wallpaper_path"
        log_success "Wallpaper set!"
    else
        log_warn "No wallpapers found in ~/Pictures/wallpapers/"
        log_info "Add wallpapers and run: feh --no-fehbg --bg-fill ~/Pictures/wallpapers/your-wallpaper.png"
    fi
}

setup_shell() {
    log_step "Setting up shell integration..."

    local shell_rc=""
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        shell_rc="$HOME_DIR/.zshrc"
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        shell_rc="$HOME_DIR/.bashrc"
    else
        shell_rc="$HOME_DIR/.profile"
    fi

    if [[ -f "$shell_rc" ]] && ! grep -q "dotfiles" "$shell_rc"; then
        cat >> "$shell_rc" << 'EOF'

# Catppuccin Dotfiles
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
# Wallpaper setter (run on login)
[[ -f "$HOME/.config/set-wallpaper.sh" ]] && "$HOME/.config/set-wallpaper.sh"
EOF
        log_info "Added PATH and wallpaper setter to $shell_rc"
    fi

    log_success "Shell integration ready!"
}

# POST-INSTALL VERIFICATION

verify_installation() {
    log_step "Verifying installation..."

    local failed=0

    for check in "${VERIFY_COMMANDS[@]}"; do
        local cmd="${check%%:*}"
        local desc="${check#*:}"
        if eval "$cmd" >/dev/null 2>&1; then
            log_success "$desc"
        else
            log_warn "$desc (not found)"
            ((failed+=1))
        fi
    done

    for dir in "${VERIFY_CONFIG_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            log_success "Config: $(basename "$dir")"
        else
            log_warn "Config missing: $(basename "$dir")"
            ((failed+=1))
        fi
    done

    if [[ $failed -eq 0 ]]; then
        log_success "All checks passed!"
    else
        log_warn "$failed checks failed - some packages may need manual installation"
    fi
}

# MAIN

print_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║         Catppuccin Theme Dotfiles Installer                  ║
║         Inspired by Keyitdev's dotfiles                      ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

print_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    --dry-run         Show what would be done without making changes
    --skip-deps       Skip dependency installation
    --variant=NAME    Catppuccin variant (latte/frappe/macchiato/mocha)
    --verbose         Show command output
    -h, --help        Show this help

Examples:
    $0                    # Full installation
    $0 --dry-run          # Preview changes
    $0 --skip-deps        # Only install configs
    $0 --variant=mocha    # Select variant (future feature)
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                log_warn "DRY RUN MODE - No changes will be made"
                ;;
            --skip-deps)
                SKIP_DEPS=true
                ;;
            --variant=*)
                SELECTED_VARIANT="${1#*=}"
                EXPLICIT_VARIANT=true
                ;;
            --verbose)
                VERBOSE=true
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
        shift
    done
}

main() {
    print_banner
    parse_args "$@"

    log_info "Dotfiles directory: $DOTFILES_DIR"
    log_info "Target home: $HOME_DIR"
    log_info "Target usr: $USR_DIR"

    detect_os
    get_package_manager

    if [[ "$OS_ID" == "unknown" ]]; then
        log_error "Cannot detect OS. Supported: Arch, Debian/Ubuntu, Fedora, openSUSE, NixOS, Alpine"
        exit 1
    fi

    select_catppuccin_variant

    echo
    if ! confirm "Proceed with installation?" "y"; then
        log_info "Installation cancelled"
        exit 0
    fi

    install_dependencies
    backup_existing
    install_home_configs
    install_system_configs
    set_wallpaper
    setup_mpd
    setup_shell
    verify_installation

    echo
    log_success "Installation complete!"
    echo
    log_info "Next steps:"
    echo "  1. Restart your shell or run: source ~/.bashrc (or ~/.zshrc)"
    echo "  2. Log out and select 'i3' from your display manager"
    echo "  3. Run 'mpd' to start music daemon"
    echo "  4. Customize configs in ~/.config/"
    echo
    log_info "Key i3 bindings (Mod = Super/Win key):"
    echo "  Mod+Return  - Open terminal (kitty)"
    echo "  Mod+D       - Application launcher (rofi)"
    echo "  Mod+A       - Run launcher (rofi drun)"
    echo "  Mod+Shift+Q - Close window"
    echo "  Mod+1-0     - Switch workspace"
    echo "  Mod+Shift+1-0 - Move window to workspace"
    echo "  Mod+X       - Power menu"
    echo "  Mod+C       - Screenshot menu"
    echo "  Mod+Z       - Music player (ncmpcpp)"
    echo
    if [[ -d "$BACKUP_DIR" ]]; then
        log_info "Backups saved to: $BACKUP_DIR"
    fi
}

main "$@"
