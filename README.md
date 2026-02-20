# Automated Dropbox & Github Project Sync

Automated Dropbox & Github Project Sync is a macOS automation setup that runs unattended backup and version-control jobs for local project roots. It copies `~/research` to `dropbox:research` and `~/projects` to `dropbox:projects` using `rclone copy` (so files are never deleted from Dropbox), and it performs nightly Git maintenance (`add`, commit if needed, `pull --ff-only`, `push`) for repositories with files modified that day.

## What It Includes
- `scripts/backup_dropbox.sh`: Dropbox backup job (research first, then projects).
- `scripts/git_nightly_sync.sh`: nightly Git sync job.
- `runtime/`: rolling logs and last-run markers.
- LaunchAgent labels used by this setup:
  - `com.cesarlandin.backup_dropbox`
  - `com.cesarlandin.git_nightly_sync`

## Schedule and Run Model
- Intended schedule window: `20:00`, `21:00`, `22:00`, `23:00` local time.
- Each script enforces "run at most once per day" using:
  - `runtime/backup_last_run`
  - `runtime/git_last_run`
- If a script runs outside that window, it exits without doing work.

## Prerequisites
- macOS with `launchd` (LaunchAgents).
- `zsh`, `git`, and `rclone` installed.
- Dropbox remote configured in rclone as `dropbox:`.
- Non-interactive Git auth configured (SSH key or credential manager) for `pull`/`push`.

## Installation
1. Clone or place this repo at:
   - `~/projects/Life Systems/backup_automation`
2. Install or verify `zsh`:
   - Download: `https://www.zsh.org/`
   - macOS usually includes `zsh` by default (`zsh --version`)
3. Install or verify `git`:
   - Download: `https://git-scm.com/downloads`
   - Verify: `git --version`
4. Download `rclone` from the official page:
   - `https://rclone.org/downloads/`
5. Verify `rclone` is executable:
   - `~/.local/bin/rclone version`
6. Configure Dropbox remote (one-time):
   - `~/.local/bin/rclone config`
   - `~/.local/bin/rclone listremotes` (must include `dropbox:`)
7. Verify git authentication is ready for unattended pushes:
   - `ssh -T git@github.com`
8. Ensure LaunchAgents exist and point to the script paths in this repo:
   - `~/Library/LaunchAgents/com.cesarlandin.backup_dropbox.plist`
   - `~/Library/LaunchAgents/com.cesarlandin.git_nightly_sync.plist`
9. Load/reload LaunchAgents:
   - `launchctl bootout gui/$(id -u)/com.cesarlandin.backup_dropbox 2>/dev/null || true`
   - `launchctl bootout gui/$(id -u)/com.cesarlandin.git_nightly_sync 2>/dev/null || true`
   - `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.cesarlandin.backup_dropbox.plist`
   - `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.cesarlandin.git_nightly_sync.plist`

## Usage
- Let it run unattended on schedule.
- Manual trigger:
  - `launchctl kickstart -k gui/$(id -u)/com.cesarlandin.backup_dropbox`
  - `launchctl kickstart -k gui/$(id -u)/com.cesarlandin.git_nightly_sync`
- Run scripts directly for debugging:
  - `~/projects/Life\ Systems/backup_automation/scripts/backup_dropbox.sh`
  - `~/projects/Life\ Systems/backup_automation/scripts/git_nightly_sync.sh`

## Logs and Run State
- Backup log: `runtime/backup.log`
- Git sync log: `runtime/git_sync.log`
- Last-run markers:
  - `runtime/backup_last_run`
  - `runtime/git_last_run`
- LaunchAgent status:
  - `launchctl print gui/$(id -u)/com.cesarlandin.backup_dropbox`
  - `launchctl print gui/$(id -u)/com.cesarlandin.git_nightly_sync`

## Troubleshooting
- `too_many_write_operations` (Dropbox throttling): allow retries and next scheduled window to continue progress.
- `path/disallowed_name`: temporary Office files (`~$...`) are excluded, but remove/close problematic temp files if errors persist.
- Backup not reaching `projects`: check `runtime/backup.log` for failures during the `research` stage.
- Git sync failures: inspect `runtime/git_sync.log` for auth errors or `pull --ff-only` conflicts.

## For AI Agents
- Implementation and validation instructions: `AGENT_IMPLEMENTATION.md`
