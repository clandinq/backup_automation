# Backup Automation Project Update (Rolling Logs + Rclone Install Help)

## Brief Summary
- Create project at `~/projects/Life Systems/backup_automation` and save this spec to `~/projects/Life Systems/backup_automation/PLAN.md`.
- Keep only two rolling logs and two `last_run` files in `runtime/` (no per-day log files).
- Keep schedule windows at `20:00`, `21:00`, `22:00`, `23:00`; each job runs at most once per day.
- Use commit title exactly `Nightly GitHub automated sync`.
- Replace rebase with `git pull --ff-only` for unattended safety.
- Add explicit assisted `rclone` install from existing download at `~/Downloads/rclone-v1.73.0-osx-amd64/rclone`.

## Files and Locations
- Project root: `~/projects/Life Systems/backup_automation`
- Plan: `~/projects/Life Systems/backup_automation/PLAN.md`
- Scripts: `~/projects/Life Systems/backup_automation/scripts/backup_dropbox.sh`
- Scripts: `~/projects/Life Systems/backup_automation/scripts/git_nightly_sync.sh`
- Runtime log: `~/projects/Life Systems/backup_automation/runtime/backup.log`
- Runtime log: `~/projects/Life Systems/backup_automation/runtime/git_sync.log`
- Run marker: `~/projects/Life Systems/backup_automation/runtime/backup_last_run`
- Run marker: `~/projects/Life Systems/backup_automation/runtime/git_last_run`
- LaunchAgent: `~/Library/LaunchAgents/com.cesarlandin.backup_dropbox.plist`
- LaunchAgent: `~/Library/LaunchAgents/com.cesarlandin.git_nightly_sync.plist`
- `rclone` binary target: `~/.local/bin/rclone`

## Rclone Installation Assistance (Using Existing Download)
- Source binary: `~/Downloads/rclone-v1.73.0-osx-amd64/rclone`
- Install flow:
  - Create `~/.local/bin` if missing.
  - Copy source binary to `~/.local/bin/rclone`.
  - `chmod +x ~/.local/bin/rclone`.
  - Verify with `~/.local/bin/rclone version`.
  - Configure Dropbox remote with `~/.local/bin/rclone config`.
  - Verify remote exists via `~/.local/bin/rclone listremotes` and includes `dropbox:`.
- Script contract:
  - Scripts use absolute `RCLONE_BIN="$HOME/.local/bin/rclone"` so PATH does not matter.
  - Backup job exits non-zero with clear log entry if binary or `dropbox:` is missing.

## Dropbox Backup Job (`backup_dropbox.sh`)
- Trigger window:
  - Launchd runs at 20/21/22/23; script also verifies current hour is in-window.
- Once-per-day guard:
  - If `backup_last_run` equals today (`YYYY-MM-DD`), log skip and exit `0`.
- Copy behavior:
  - `rclone copy "$HOME/research" "dropbox:research" ...`
  - `rclone copy "$HOME/projects" "dropbox:projects" ...`
  - Never delete Dropbox files.
- Excludes:
  - `.git/**`, `**/.DS_Store`, `**/.ipynb_checkpoints/**`, `**/__pycache__/**`, `**/.pytest_cache/**`, `**/.mypy_cache/**`, `**/.ruff_cache/**`, `**/.cache/**`, `**/*.tmp`, `**/*.swp`, `**/*~`.
- Success:
  - Update `backup_last_run` only after both copy commands succeed.
  - Append all output/errors to `runtime/backup.log`.

## GitHub Sync Job (`git_nightly_sync.sh`)
- Trigger window:
  - Same 20/21/22/23 launch + in-script hour check.
- Once-per-day guard:
  - If `git_last_run` equals today, log skip and exit `0`.
- Repo scan scope:
  - First-level under `~/research/*`.
  - First-level under `~/projects/*`.
  - Second-level only under `~/projects/Life Systems/*` and `~/projects/Small Projects/*`.
- Repo eligibility:
  - Must be a Git repo.
  - Must have at least one working-tree file modified today.
- Per-repo workflow:
  - `git add -A`
  - Commit only if staged changes exist, with message `Nightly GitHub automated sync`
  - `git pull --ff-only`
  - `git push`
- Failure handling:
  - Continue to next repo on repo failure and log it.
  - Set `git_last_run` only if all qualifying repos succeed.
  - Exit non-zero if any qualifying repo fails.

## LaunchAgents
- `com.cesarlandin.backup_dropbox.plist` and `com.cesarlandin.git_nightly_sync.plist`:
  - `StartCalendarInterval` entries for 20:00, 21:00, 22:00, 23:00.
  - `RunAtLoad` set to true.
  - `ProgramArguments` point to absolute script paths.
  - Stdout/stderr go to the rolling logs in `runtime/`.
