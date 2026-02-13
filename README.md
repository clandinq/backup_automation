# Backup Automation

Automates Dropbox backups and nightly GitHub syncs for `~/research` and `~/projects`.

## Jobs
- Dropbox backup via `rclone copy` (never deletes destination files).
- Nightly GitHub sync for repositories with files modified today.

## Schedule
Both jobs are scheduled via LaunchAgents at local time:
- 20:00
- 21:00
- 22:00
- 23:00

Each job runs at most once per day, controlled by `runtime/*_last_run` files.

## Paths
- Scripts: `scripts/`
- Runtime logs/state: `runtime/`
- LaunchAgents: `~/Library/LaunchAgents/`

## Setup
1. Ensure `~/.local/bin/rclone` exists and is executable.
2. Configure Dropbox remote: `~/.local/bin/rclone config`
3. Verify remote: `~/.local/bin/rclone listremotes`
4. Load agents:
   - `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.cesarlandin.backup_dropbox.plist`
   - `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.cesarlandin.git_nightly_sync.plist`
