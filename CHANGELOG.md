# Changelog for zsh-setup

## [Unreleased]

All notable changes to this project will be documented in this file.

## [feature/improvements] - 2024-06-XX

### Added
- Error and action logging to `~/.zsh-setup.log` for all scripts
- Disk space and network connectivity checks before downloads/installations
- Confirmation prompts and timestamped backups before destructive actions
- Warn before overwriting or removing custom configurations
- Selective uninstall and rollback options in `uninstall.sh`
- Idempotent config changes (no duplicate entries)
- Clear markers for auto-generated config sections in `.zshrc`
- Explanatory comments in config files and scripts
- Robust example `.zshrc` demonstrating best practices, Oh My Posh/NVM segment usage, and plugin blocks
- Comprehensive `CONTRIBUTING.md` with guidelines, code style, and community support
- Updated `README.md` with safety features, flags, FAQ, troubleshooting, NVM segment usage, and contribution info

### Changed
- Refactored scripts for readability, modularity, and maintainability
- Standardized variable naming and quoting for shell safety
- Improved colored output consistency and user prompts
- Enhanced backup logic for fonts and configs
- Improved Oh My Posh theme selection UX with previews and backup confirmation
- Added disk/network checks and error handling to `install_fonts.sh` and `change_posh_theme.sh`
- Improved documentation and example usage in all reference files

### Fixed
- Duplicate shell entries in `/etc/shells`
- Idempotent config file writes and plugin blocks
- Edge cases in theme block removal and malformed config files
- Font installation skips already-installed fonts


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
