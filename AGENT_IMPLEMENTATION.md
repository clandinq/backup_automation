# Agent Implementation Guide: Automated Dropbox & Github Project Sync

## Objective
Implement, validate, and maintain this system exactly as documented in `README.md` with unattended operation on macOS.

## Scope
Maintain and verify two jobs:
- Dropbox backup job: `scripts/backup_dropbox.sh`
- Nightly git sync job: `scripts/git_nightly_sync.sh`

Also maintain:
- LaunchAgent scheduling and wiring
- Rolling logs in `runtime/`
- Daily last-run guards in `runtime/*_last_run`

## Hard Constraints
- Do not delete files from Dropbox.
- Preserve backup order: `research` first, then `projects`.
- Keep commit message exactly: `Nightly GitHub automated sync`.
- Keep scheduled window behavior: 20:00, 21:00, 22:00, 23:00 local time.
- Do not commit runtime logs/state files.
- Do not commit secrets, tokens, keys, or credential files.

## Required Inputs and Environment
- macOS with `launchd`.
- `rclone` available at `~/.local/bin/rclone`.
- `rclone` remote named `dropbox:` configured.
- Git authentication configured for unattended pull/push.
- Repo located at `~/projects/Life Systems/backup_automation` unless scripts are updated intentionally.

## Ordered Implementation Workflow
1. Validate prerequisites.
   - Confirm `~/.local/bin/rclone` exists and is executable.
   - Confirm `dropbox:` appears in `rclone listremotes`.
   - Confirm git auth can operate non-interactively.
2. Validate script behavior and path assumptions.
   - Verify script shebangs and executable bits.
   - Verify runtime paths and log destinations.
3. Validate LaunchAgent wiring.
   - Confirm plists exist and point to script paths.
   - Confirm labels are bootstrapped and enabled.
4. Validate schedule and daily guard behavior.
   - Confirm scripts skip outside 20-23 window.
   - Confirm last-run files gate repeat runs on the same day.
5. Validate logging and failure handling.
   - Confirm logs append entries with timestamps.
   - Confirm non-zero exits on failed backup/sync operations.

## Verification Checklist (Commands)
Run from repo root unless noted.

1. Syntax checks:
- `zsh -n scripts/backup_dropbox.sh`
- `zsh -n scripts/git_nightly_sync.sh`

2. LaunchAgent status:
- `launchctl print gui/$(id -u)/com.cesarlandin.backup_dropbox`
- `launchctl print gui/$(id -u)/com.cesarlandin.git_nightly_sync`

3. Manual trigger checks:
- `launchctl kickstart -k gui/$(id -u)/com.cesarlandin.backup_dropbox`
- `launchctl kickstart -k gui/$(id -u)/com.cesarlandin.git_nightly_sync`
- Inspect:
  - `runtime/backup.log`
  - `runtime/git_sync.log`

4. Secret scans (tracked files):
- `rg -n --hidden --no-ignore -S "BEGIN (RSA|OPENSSH|EC|DSA) PRIVATE KEY|access_token|refresh_token|api[_-]?key|secret[_-]?key|client_secret|authorization: bearer|x-api-key|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}" $(git ls-files) || true`

5. Secret scan (history):
- Scan all commits for the same patterns before public release.

## Acceptance Criteria
- Backup and git jobs run during configured window and log outcomes.
- Daily run guards prevent duplicate full runs per day.
- Backup job uses non-destructive copy semantics.
- Git sync job keeps commit message and ff-only pull behavior unchanged.
- No private key/token material in tracked files or commit history.

## Change Policy
If modifying behavior, update both:
- `README.md`
- this file (`AGENT_IMPLEMENTATION.md`)

Keep docs and scripts in sync.
