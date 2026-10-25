# AGENTS.md

Catppuccin-themed dotfiles with a runtime theme engine. Supports Latte, Frappé, Macchiato, Mocha variants.

## Key commands

```bash
./install.sh                          # full install, prompts for variant
./install.sh --variant=mocha          # skip variant prompt
./install.sh --dry-run                # preview what would change
./install.sh --skip-deps              # skip dependency installation

./theme-switcher.sh mocha --preview   # show color swatch
./theme-switcher.sh frappe --apply-home   # recolor ~/.config in place
./theme-switcher.sh macchiato --render-to /tmp/staging  # render to directory
```

Source palette helpers directly:
```bash
source theme-engine/catppuccin-palette.sh && get_variants
source theme-engine/catppuccin-palette.sh && get_color mocha blue
source theme-engine/catppuccin-palette.sh && print_colors mocha
```

## Architecture

**Core flow:**
```
install.sh → theme-switcher.sh --render-to <staging> → ~/.config/
```

- `canonical-configs/config/` — immutable source of truth, always holds the **Mocha** variant. Never edit these with non-Mocha hex values.
- `theme-engine/catppuccin-palette.sh` — defines all 26 color keys × 4 variants as bash associative arrays. Provides `get_color`, `load_colors`, `generate_config`, `print_color_swatch`.
- `theme-engine/templates/` — Polybar/Rofi templates with `{{placeholders}}` filled by `generate_config`.
- `theme-switcher.sh` — recoloring engine. Uses `sed` to swap hex values between variants. `--render-to` copies canonical-configs then recolors. `--apply-home` modifies `~/.config` in place (creates backup first).
- `lib/logging.sh` — shared `log_info`/`log_success`/`log_warn`/`log_error`/`log_step` and `run_cmd` (respects `$DRY_RUN` and `$VERBOSE`).
- `usr/local/bin/` — POSIX shell scripts (`#!/bin/sh`) for i3 hotkeys: volume, brightness, screenshots, power menu, lock, touchpad, fan control. Use `dunstify` for notifications.

## Adding a new Catppuccin variant

1. Add color definitions to `catppuccin-palette.sh` (new associative array + add to `CATPPUCCIN_VARIANTS`).
2. Update `canonical-configs/` configs with the new variant's hex values (or keep Mocha as canonical and let sed handle it).
3. Update the variant selection menu in `install.sh`.

## Adding a new app config

1. Add reference config (with Mocha hex values) to `canonical-configs/config/<app>/`.
2. If the app uses color hex values, the theme-switcher will auto-recolor them via sed.
3. For template-based configs, add a template under `theme-engine/templates/` with `{{placeholders}}`.

## Testing locally

No test suite exists. To verify changes:
```bash
# Dry run to see what install would do
./install.sh --dry-run --variant=latte

# Render to a temp directory and inspect
./theme-switcher.sh latte --render-to /tmp/test-render
diff -r canonical-configs/config /tmp/test-render/.config

# Check palette helpers
source theme-engine/catppuccin-palette.sh && print_colors latte
```

## Gotchas

- `canonical-configs/` must always contain **Mocha** hex values. The sed recoloring swaps from Mocha to target — if canonical configs have non-Mocha values, recoloring breaks.
- No CI, no linting, no automated tests.
- `usr/local/bin/` scripts are POSIX sh (`#!/bin/sh`), not bash. Don't use bashisms there.
- The `theme-switcher.sh --apply-home` reads current variant from `~/.config/.catppuccin-variant`. If that file is missing/corrupt, it defaults to "mocha".
- `Backup/` and `Backup_conf/` directories inside `canonical-configs/` are skipped during rendering.
