#!/bin/zsh
set -u

PROJECT_DIR="$HOME/projects/Life Systems/backup_automation"
RUNTIME_DIR="$PROJECT_DIR/runtime"
LOG_FILE="$RUNTIME_DIR/backup.log"
LAST_RUN_FILE="$RUNTIME_DIR/backup_last_run"
RCLONE_BIN="$HOME/.local/bin/rclone"

mkdir -p "$RUNTIME_DIR"
touch "$LOG_FILE"

log() {
  printf '%s [backup] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

run_copy() {
  local src="$1"
  local dst="$2"

  log "Starting backup: $src -> $dst"
  if "$RCLONE_BIN" copy "$src" "$dst" "${exclude_args[@]}" "${rclone_args[@]}" >> "$LOG_FILE" 2>&1; then
    log "Completed backup: $src -> $dst"
    return 0
  fi

  log "ERROR: backup failed for $src"
  return 1
}

today="$(date +%F)"
hour="$(date +%H)"

if [[ ! "$hour" =~ '^(20|21|22|23)$' ]]; then
  log "Outside run window (20-23). Current hour: $hour. Exiting."
  exit 0
fi

if [[ -f "$LAST_RUN_FILE" ]]; then
  last_run="$(tr -d '[:space:]' < "$LAST_RUN_FILE")"
  if [[ "$last_run" == "$today" ]]; then
    log "Backup already completed for $today. Skipping."
    exit 0
  fi
fi

if [[ ! -x "$RCLONE_BIN" ]]; then
  log "ERROR: rclone binary not found or not executable at $RCLONE_BIN"
  exit 1
fi

if ! "$RCLONE_BIN" listremotes >> "$LOG_FILE" 2>&1; then
  log "ERROR: unable to query rclone remotes."
  exit 1
fi

if ! "$RCLONE_BIN" listremotes 2>> "$LOG_FILE" | grep -Fxq 'dropbox:'; then
  log "ERROR: rclone remote dropbox: not configured. Run: $RCLONE_BIN config"
  exit 1
fi

exclude_args=(
  --exclude ".git/**"
  --exclude "**/.git/**"
  --exclude ".DS_Store"
  --exclude "**/.DS_Store"
  --exclude "~\$*"
  --exclude "**/~\$*"
  --exclude "._*"
  --exclude "**/._*"
  --exclude "**/.ipynb_checkpoints/**"
  --exclude "**/__pycache__/**"
  --exclude "**/.pytest_cache/**"
  --exclude "**/.mypy_cache/**"
  --exclude "**/.ruff_cache/**"
  --exclude "**/.cache/**"
  --exclude "**/*.tmp"
  --exclude "**/*.swp"
  --exclude "**/*~"
)

# Keep Dropbox API pressure low to avoid "too_many_write_operations" failures.
rclone_args=(
  --checkers 4
  --transfers 2
  --retries 12
  --low-level-retries 25
  --retries-sleep 10s
  --tpslimit 6
  --tpslimit-burst 6
  --dropbox-batch-mode off
)

failures=0

run_copy "$HOME/research" "dropbox:research" || failures=$((failures + 1))
run_copy "$HOME/projects" "dropbox:projects" || failures=$((failures + 1))

if [[ "$failures" -gt 0 ]]; then
  log "Backup finished with failures in $failures root(s)."
  exit 1
fi

printf '%s\n' "$today" > "$LAST_RUN_FILE"
log "Backup completed successfully for $today"
