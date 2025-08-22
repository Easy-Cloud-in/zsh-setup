# Changelog for zsh-setup

## [Unreleased]

All notable changes to this project will be documented in this file.

## [1.2.0] - 2025-08-22

### Added

- Non-interactive flags (`--force`, `--update-rc`, `--dry-run`, `--no-prompt`) to main setup script
- Dry-run mode for previewing changes
- Backup mechanism for .zshrc before modifications
- Search utilities installation options (fzf, ripgrep, fd)
- Improved error logging and validation
- Example config files (`example.zshrc`, `example.aliases`)

### Changed

- Refactored argument parsing and error handling logic
- Enhanced colored output consistency
- Added timestamped backups for config files
- Improved Oh My Posh theme selection UX with previews

### Fixed

- Duplicate shell entries in `/etc/shells`
- Idempotent config file writes
