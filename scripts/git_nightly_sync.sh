#!/bin/zsh
set -u

# Force non-interactive Git behavior for unattended launchd execution.
export GIT_TERMINAL_PROMPT=0
export GIT_ASKPASS=/usr/bin/true
export SSH_ASKPASS=/usr/bin/true
export GCM_INTERACTIVE=Never
export GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=20 -o ServerAliveInterval=15 -o ServerAliveCountMax=2"

PROJECT_DIR="$HOME/projects/Life Systems/backup_automation"
RUNTIME_DIR="$PROJECT_DIR/runtime"
LOG_FILE="$RUNTIME_DIR/git_sync.log"
LAST_RUN_FILE="$RUNTIME_DIR/git_last_run"

mkdir -p "$RUNTIME_DIR"
touch "$LOG_FILE"

log() {
  printf '%s [git-sync] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

git_safe() {
  git -c credential.interactive=never -c http.lowSpeedLimit=1 -c http.lowSpeedTime=30 "$@"
}

is_git_repo() {
  git_safe -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1
}

modified_today() {
  local repo="$1"
  local today="$2"
  local tomorrow="$3"

  find "$repo" \
    -type f \
    -not -path "*/.git/*" \
    -newermt "$today 00:00:00" \
    ! -newermt "$tomorrow 00:00:00" \
    -print -quit | grep -q .
}

today="$(date +%F)"
tomorrow="$(date -v+1d +%F)"
hour="$(date +%H)"

if [[ ! "$hour" =~ '^(20|21|22|23)$' ]]; then
  log "Outside run window (20-23). Current hour: $hour. Exiting."
  exit 0
fi

if [[ -f "$LAST_RUN_FILE" ]]; then
  last_run="$(tr -d '[:space:]' < "$LAST_RUN_FILE")"
  if [[ "$last_run" == "$today" ]]; then
    log "Git sync already completed for $today. Skipping."
    exit 0
  fi
fi

repos=()

for dir in "$HOME/research"/*; do
  [[ -d "$dir" ]] && repos+=("$dir")
done

for dir in "$HOME/projects"/*; do
  [[ -d "$dir" ]] && repos+=("$dir")
done

for parent in "$HOME/projects/Life Systems" "$HOME/projects/Small Projects"; do
  if [[ -d "$parent" ]]; then
    for dir in "$parent"/*; do
      [[ -d "$dir" ]] && repos+=("$dir")
    done
  fi
done

if [[ ${#repos[@]} -eq 0 ]]; then
  log "No candidate directories found."
  exit 0
fi

failures=0
processed=0

for repo in "${repos[@]}"; do
  if ! is_git_repo "$repo"; then
    continue
  fi

  if ! modified_today "$repo" "$today" "$tomorrow"; then
    log "Skipping $repo (no files modified today)."
    continue
  fi

  processed=$((processed + 1))
  log "Processing repo: $repo"

  if ! git_safe -C "$repo" add -A >> "$LOG_FILE" 2>&1; then
    log "ERROR: git add -A failed for $repo"
    failures=$((failures + 1))
    continue
  fi

  if ! git_safe -C "$repo" diff --cached --quiet --ignore-submodules --; then
    if ! git_safe -C "$repo" commit -m "Nightly GitHub automated sync" >> "$LOG_FILE" 2>&1; then
      log "ERROR: git commit failed for $repo"
      failures=$((failures + 1))
      continue
    fi
  else
    log "No staged changes to commit in $repo"
  fi

  if ! git_safe -C "$repo" pull --ff-only >> "$LOG_FILE" 2>&1; then
    log "ERROR: git pull --ff-only failed for $repo"
    failures=$((failures + 1))
    continue
  fi

  if ! git_safe -C "$repo" push >> "$LOG_FILE" 2>&1; then
    log "ERROR: git push failed for $repo"
    failures=$((failures + 1))
    continue
  fi

  log "Completed repo: $repo"
done

if [[ "$failures" -eq 0 ]]; then
  printf '%s\n' "$today" > "$LAST_RUN_FILE"
  log "Git sync completed successfully. Processed repos: $processed"
  exit 0
fi

log "Git sync completed with failures: $failures (processed repos: $processed)"
exit 1
