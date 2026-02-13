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
  --exclude "**/.DS_Store"
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

log "Starting backup: $HOME/research -> dropbox:research"
if ! "$RCLONE_BIN" copy "$HOME/research" "dropbox:research" "${exclude_args[@]}" >> "$LOG_FILE" 2>&1; then
  log "ERROR: backup failed for $HOME/research"
  exit 1
fi

log "Starting backup: $HOME/projects -> dropbox:projects"
if ! "$RCLONE_BIN" copy "$HOME/projects" "dropbox:projects" "${exclude_args[@]}" >> "$LOG_FILE" 2>&1; then
  log "ERROR: backup failed for $HOME/projects"
  exit 1
fi

printf '%s\n' "$today" > "$LAST_RUN_FILE"
log "Backup completed successfully for $today"
