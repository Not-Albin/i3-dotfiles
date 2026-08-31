#!/usr/bin/env bash
# Shared logging functions

# Source colors if not already sourced
if [[ -z "${RED:-}" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"
fi

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*"; }
log_step()    { echo -e "\n${MAGENTA}▶${NC} ${BOLD}$*${NC}"; }

# run_cmd: executes command with dry-run and verbose support
# Usage: run_cmd "command" [verbose]
#   - if DRY_RUN=true, shows what would run
#   - if VERBOSE=true (or 2nd arg is true), shows output
#   - otherwise suppresses output
run_cmd() {
    local cmd="$1"
    local verbose="${2:-${VERBOSE:-false}}"

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] $cmd"
    else
        if [[ "$verbose" == true ]]; then
            eval "$cmd"
        else
            eval "$cmd" >/dev/null 2>&1
        fi
    fi
}