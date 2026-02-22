#!/usr/bin/env zsh
set -euo pipefail

# Clean caches and heavy regen-able build artifacts across the user folder.
# Usage: ./recover-memory.sh [-f] [-n] [-p] [-r] [-h]
#   -f : skip confirmation prompt
#   -n : dry run (show what would be removed)
#   -p : also delete Photos Library (~/Pictures/Photos Library.photoslibrary)
#   -r : reboot after cleanup (skipped in dry run)
#   -h : show this help and exit

FORCE=false
DRY_RUN=false
PHOTOS=false
REBOOT=false
did_run=false

# Auto-elevate for permission-sensitive paths.
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  exec sudo -- "$0" "$@"
fi

show_help() {
  cat <<'EOF'
Usage: recover-memory.sh [options]
Options:
  -f    skip confirmation prompt
  -n    dry run (show what would be removed)
  -p    also delete Photos Library (~/Pictures/Photos Library.photoslibrary)
  -r    reboot after cleanup (skipped in dry run)
  -h    show this help
EOF
}

while getopts ":fnprh" opt; do
  case "$opt" in
    f) FORCE=true ;;
    n) DRY_RUN=true ;;
    p) PHOTOS=true ;;
    r) REBOOT=true ;;
    h) show_help; exit 0 ;;
    \?) show_help; exit 1 ;;
  esac
done

home_dir="${HOME:?}" 

log()  { printf "[recover] %s\n" "$*"; }
free_kb() { df -k "$home_dir" 2>/dev/null | awk 'NR==2 {print $4}' || true; }
format_kb() {
  awk -v kb="$1" 'BEGIN {
    if (kb >= 1048576) printf "%.2f GB", kb/1048576;
    else if (kb >= 1024) printf "%.2f MB", kb/1024;
    else printf "%d KB", kb;
  }'
}

finish() {
  if ! $did_run; then
    return
  fi

  if ! $DRY_RUN; then
    local after_kb
    after_kb=$(free_kb || true)
    if [[ -n "$after_kb" && -n "$before_kb" && "$after_kb" -ge "$before_kb" ]]; then
      local reclaimed_kb
      reclaimed_kb=$((after_kb - before_kb))
      log "space reclaimed: $(format_kb "$reclaimed_kb")"
    fi
  fi

  log "done. Consider rebooting or re-logging to reclaim RAM if needed."
  log "tip: use -r to reboot immediately after cleanup"
}
is_under_parent() {
  local child="$1"; shift
  local child_abs="${child:A}"
  for parent in "$@"; do
    local parent_abs="${parent:A}"
    [[ "$child_abs" == "$parent_abs" || "$child_abs" == ${parent_abs}/* ]] && return 0
  done
  return 1
}

rm_path_list() {
  local -a paths=("$@")
  local -a removed=()
  for target in "$paths[@]"; do
    # Expand globs up front to avoid double processing.
    for p in ${(f)$(print -r -- $~target)}; do
      [[ -e "$p" ]] || continue
      # Skip if already removed or nested under an earlier target.
      if is_under_parent "$p" "$removed[@]"; then
        continue
      fi
      if $DRY_RUN; then
        log "(dry run) would remove: $p"
      else
        log "removing: $p"
        rm -rf "$p" 2>/dev/null || log "skipped (permission denied): $p"
      fi
      removed+=("$p")
    done
  done
}

if ! $FORCE; then
  echo "This will delete caches and build artifacts under $home_dir."
  read "?Proceed? (y/N) " ans
  if [[ "$ans" != "y" && "$ans" != "Y" ]]; then
    echo "Aborted."; exit 0
  fi
fi

before_kb=0
if ! $DRY_RUN; then
  before_kb=$(free_kb || true)
fi

did_run=true
trap finish EXIT

# Targeted cache and artifact directories.
declare -a PATHS_TO_REMOVE=(
  "$home_dir/Library/Caches"
  "$home_dir/Library/Developer/Xcode/DerivedData"
  "$home_dir/Library/Developer/Xcode/Archives"
  "$home_dir/Library/Developer/Xcode/Products"
  "$home_dir/Library/Developer/Xcode/Previews"
  "$home_dir/Library/Developer/Xcode/ModuleCache.noindex"
  "$home_dir/Library/Developer/CoreSimulator/Caches"
  "$home_dir/Library/Developer/CoreSimulator/Devices/*/data/Library/Caches"
  "$home_dir/Library/Developer/CoreSimulator/Devices/*/data/tmp"
  "$home_dir/Library/Caches/com.apple.dt.Xcode"
  "$home_dir/Library/Caches/com.apple.dt.instruments"
  "$home_dir/Library/Developer/XCPGDevices"
  "$home_dir/Library/Application Support/Tuist/Cache"
  "$home_dir/Library/Application Support/Tuist/Artifacts"
  "$home_dir/Library/Caches/Tuist"
  "$home_dir/Library/Caches/io.tuist"
  "$home_dir/.cache/tuist"
  "$home_dir/Library/Application Support/Code/Cache"
  "$home_dir/Library/Application Support/Code/CachedData"
  "$home_dir/Library/Application Support/Code/User/workspaceStorage"
  "$home_dir/Library/Application Support/Code/User/globalStorage/state.vscdb"
  "$home_dir/Library/Application Support/Code/User/globalStorage/storage.json"
  "$home_dir/Library/Application Support/Code/Service Worker/CacheStorage"
  "$home_dir/Library/Application Support/Code/Service Worker/ScriptCache"
  "$home_dir/Library/Caches/Google/Chrome"
  "$home_dir/Library/Application Support/Google/Chrome/Default/Cache"
  "$home_dir/Library/Application Support/Google/Chrome/Default/Service Worker/CacheStorage"
  "$home_dir/Library/Caches/com.apple.Safari"
  "$home_dir/Library/Caches/com.apple.Safari.SafeBrowsing"
  "$home_dir/Library/Application Support/com.apple.Safari/Service Worker/CacheStorage"
  "$home_dir/Library/Caches/com.apple.WebKit.Networking"
  "$home_dir/Library/Caches/com.apple.WebKit.PluginProcess"
  "$home_dir/Library/Caches/com.apple.WebKit.GPU"
  "$home_dir/Library/Caches/Firefox"
  "$home_dir/Library/Application Support/Firefox/Profiles/*/cache2"
  "$home_dir/Library/Application Support/Firefox/Profiles/*/storage/default"
  "/Library/Caches/Homebrew"
  "$home_dir/Library/Caches/Homebrew"
  "$home_dir/Library/Logs/Homebrew"
  "$home_dir/.cache/pip"
  "$home_dir/Library/Caches/pip"
  "$home_dir/.cache/npm"
  "$home_dir/.npm/_cacache"
  "$home_dir/.cache/yarn"
  "$home_dir/.cache/pypoetry"
  "$home_dir/Library/Caches/org.swift.swiftpm"
)

if $PHOTOS; then
  PATHS_TO_REMOVE+=("$home_dir/Pictures/Photos Library.photoslibrary")
fi

# Remove targeted cache paths first.
rm_path_list "${PATHS_TO_REMOVE[@]}"

# Prune large per-project artifacts across the home folder.
log "scanning for build artifacts and virtualenvs…"
artifact_paths=(
  ${(f)$(find "$home_dir" \
    -path "$home_dir/Library" -prune -o \
    -path "$home_dir/.Trash" -prune -o \
    -path "$home_dir/.cache" -prune -o \
    -type d \( \
      -name node_modules -o \
      -name target -o \
      -name __pycache__ -o \
      -name .pytest_cache -o \
      -name .mypy_cache -o \
      -name .ruff_cache -o \
      -name .venv -o \
      -name .tox -o \
      -name .parcel-cache -o \
      -name .next -o \
      -name .turbo \
    \) -prune -print 2>/dev/null)}
)
# Remove artifact paths while skipping nested children of already-removed parents.
rm_path_list "$artifact_paths[@]"

# Encourage memory reclamation on macOS (optional and best-effort).
if ! $DRY_RUN && command -v purge >/dev/null 2>&1; then
  log "triggering macOS purge (disk cache eviction hint)"
  purge || true
fi

if $REBOOT; then
  if $DRY_RUN; then
    log "(dry run) would reboot system"
  else
    log "rebooting system in 5 seconds (Ctrl+C to cancel)"
    sleep 5
    if command -v osascript >/dev/null 2>&1; then
      osascript -e 'tell app "System Events" to restart' || true
    elif command -v shutdown >/dev/null 2>&1; then
      sudo shutdown -r now || shutdown -r now || log "reboot command failed; please reboot manually"
    else
      log "no reboot command available; please reboot manually"
    fi
  fi
fi

true
