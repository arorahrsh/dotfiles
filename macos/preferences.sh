#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'HELP'
Usage: ./macos/preferences.sh [--dry-run] [--help]

Apply preferred Finder, clock, and screenshot settings:
  Show filename extensions, hidden files, and the Finder path bar
  Search the current folder by default in Finder
  Show seconds in the menu bar clock
  Save screenshots to $HOME/Pictures/Screenshots

  --dry-run     Preview changes without applying them
  -h, --help    Show this help

Unchanged settings are skipped. Finder restarts once if its settings change.
HELP
}

dry_run=false
for option in "$@"; do
    case "$option" in
        --dry-run) dry_run=true ;;
        -h|--help) usage; exit 0 ;;
        *)
            printf 'Unknown option: %s\n' "$option" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [ "$(uname -s)" != Darwin ]; then
    printf 'macOS preferences can only be applied on macOS.\n' >&2
    exit 1
fi

screenshots_dir="$HOME/Pictures/Screenshots"
finder_changed=false
clock_changed=false

set_preference() {
    local domain="$1" key="$2" type="$3" value="$4" component="$5"
    local current write_value="$value"
    # Readback uses 1/0, but the defaults CLI requires boolean words on writes.
    if [ "$type" = -bool ]; then
        case "$value" in
            1) write_value=true ;;
            0) write_value=false ;;
        esac
    fi
    # Missing keys need an explicit value, just like mismatched settings.
    if current=$(defaults read "$domain" "$key" 2>/dev/null) && [ "$current" = "$value" ]; then
        printf 'Already set: %s %s = %s\n' "$domain" "$key" "$value"
        return 0
    fi

    if [ "$dry_run" = true ]; then
        printf 'Would set: %s %s = %s\n' "$domain" "$key" "$value"
    else
        printf 'Setting: %s %s = %s\n' "$domain" "$key" "$value"
        defaults write "$domain" "$key" "$type" "$write_value"
    fi
    case "$component" in
        finder) finder_changed=true ;;
        clock) clock_changed=true ;;
    esac
}

if [ ! -d "$screenshots_dir" ]; then
    if [ "$dry_run" = true ]; then
        printf 'Would create directory: %s\n' "$screenshots_dir"
    else
        mkdir -p "$screenshots_dir"
    fi
fi

# defaults read represents enabled booleans as 1.
set_preference NSGlobalDomain AppleShowAllExtensions -bool 1 finder
set_preference com.apple.finder ShowPathbar -bool 1 finder
set_preference com.apple.finder FXDefaultSearchScope -string SCcf finder
set_preference com.apple.finder AppleShowAllFiles -bool 1 finder
set_preference com.apple.screencapture location -string "$screenshots_dir" screenshots
set_preference com.apple.menuextra.clock ShowSeconds -bool 1 clock

if [ "$finder_changed" = true ]; then
    if [ "$dry_run" = true ]; then
        printf 'Would restart Finder once.\n'
    else
        killall Finder || true
    fi
fi

if [ "$clock_changed" = true ]; then
    printf 'The clock may need a logout and login to refresh after applying changes.\n'
fi
