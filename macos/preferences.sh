#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bash macos/preferences.sh [options]

  --show-extensions on|off           Set whether Finder shows filename extensions
  --clock-seconds on|off             Set whether the menu bar clock shows seconds
  --finder-path-bar on|off           Set whether Finder shows the path bar
  --finder-search current|mac        Set the default Finder search scope
  --hidden-files on|off              Set whether Finder shows hidden files
  --screenshots-dir ABSOLUTE_PATH    Set the default screenshot folder
  -h, --help                         Show this help

Only the settings specified are changed. Finder may restart.
EOF
}

show_extensions=""
clock_seconds=""
finder_path_bar=""
finder_search=""
hidden_files=""
screenshots_dir=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --show-extensions|--clock-seconds|--finder-path-bar|--finder-search|--hidden-files|--screenshots-dir)
            option="$1"
            if [ "$#" -lt 2 ]; then
                printf 'Missing value for %s\n' "$option" >&2
                exit 1
            fi
            case "$option:$2" in
                --show-extensions:on|--show-extensions:off)
                    show_extensions="$2" ;;
                --clock-seconds:on|--clock-seconds:off)
                    clock_seconds="$2" ;;
                --finder-path-bar:on|--finder-path-bar:off)
                    finder_path_bar="$2" ;;
                --finder-search:current|--finder-search:mac)
                    finder_search="$2" ;;
                --hidden-files:on|--hidden-files:off)
                    hidden_files="$2" ;;
                --screenshots-dir:/*)
                    screenshots_dir="$2" ;;
                *)
                    printf 'Invalid value for %s: %s\n' "$option" "$2" >&2
                    exit 1 ;;
            esac
            shift 2
            ;;
        *)
            printf 'Unknown option: %s\n' "$1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [ -z "$show_extensions$clock_seconds$finder_path_bar$finder_search$hidden_files$screenshots_dir" ]; then
    usage
    exit 0
fi

if [ "$(uname -s)" != Darwin ]; then
    printf 'macOS preferences can only be applied on macOS.\n' >&2
    exit 1
fi

if [ -n "$screenshots_dir" ]; then
    mkdir -p "$screenshots_dir"
fi

if [ -n "$show_extensions" ]; then
    printf 'Setting filename extensions to %s\n' "$show_extensions"
    defaults write NSGlobalDomain AppleShowAllExtensions -bool "$([ "$show_extensions" = on ] && printf true || printf false)"
fi

if [ -n "$finder_path_bar" ]; then
    printf 'Setting Finder path bar to %s\n' "$finder_path_bar"
    defaults write com.apple.finder ShowPathbar -bool "$([ "$finder_path_bar" = on ] && printf true || printf false)"
fi

if [ -n "$finder_search" ]; then
    printf 'Setting Finder search scope to %s\n' "$finder_search"
    defaults write com.apple.finder FXDefaultSearchScope -string "$([ "$finder_search" = current ] && printf SCcf || printf SCev)"
fi

if [ -n "$hidden_files" ]; then
    printf 'Setting hidden files to %s\n' "$hidden_files"
    defaults write com.apple.finder AppleShowAllFiles -bool "$([ "$hidden_files" = on ] && printf true || printf false)"
fi

if [ -n "$show_extensions$finder_path_bar$finder_search$hidden_files" ]; then
    killall Finder || true
fi

if [ -n "$screenshots_dir" ]; then
    printf 'Setting screenshot folder to %s\n' "$screenshots_dir"
    defaults write com.apple.screencapture location -string "$screenshots_dir"
fi

if [ -n "$clock_seconds" ]; then
    printf 'Setting clock seconds to %s\n' "$clock_seconds"
    defaults write com.apple.menuextra.clock ShowSeconds -bool "$([ "$clock_seconds" = on ] && printf true || printf false)"
    printf 'The clock may need a logout and login to refresh.\n'
fi
