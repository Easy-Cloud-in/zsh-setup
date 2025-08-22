# zsh-setup User Manual

_Last updated: June 2024_

---

## Table of Contents

1. [Introduction](#introduction)
2. [System Requirements](#system-requirements)
3. [Installation & Quick Start](#installation--quick-start)
4. [Script Flags & Options](#script-flags--options)
5. [Step-by-Step Setup Guide](#step-by-step-setup-guide)
6. [Backup, Rollback & Safety Features](#backup-rollback--safety-features)
7. [Theme & Plugin Management](#theme--plugin-management)
8. [Advanced Usage](#advanced-usage)
9. [Troubleshooting & FAQ](#troubleshooting--faq)
10. [Restoring Backups](#restoring-backups)
11. [Self-Check & Testing](#self-check--testing)
12. [Contributing](#contributing)
13. [Support & Feedback](#support--feedback)

---

## Introduction

**zsh-setup** automates the installation and configuration of Zsh, Oh My Zsh, Oh My Posh, recommended plugins, and Nerd Fonts. It prioritizes user safety, error handling, and idempotency, making it suitable for both beginners and advanced users.

---

## System Requirements

- Ubuntu/Debian-based Linux distribution
- Minimum 256MB RAM
- 100MB free disk space
- Internet connection
- Terminal with Unicode support
- Git installed (`sudo apt install git`)
- Nerd Fonts (recommended for prompt icons)

---

## Installation & Quick Start

```bash
# Clone the repository
git clone https://github.com/Easy-Cloud-in/zsh-setup.git
cd zsh-setup

# Make scripts executable
chmod +x *.sh

# Install Nerd Fonts (if not already installed)
./install_fonts.sh

# Run the setup script (interactive mode)
./zsh_oh_my_posh_setup.sh

# Start using Zsh
zsh
```

---

### Install from Zip Release

If you downloaded a release zip from GitHub:

```bash
unzip zsh-setup-v*.zip
cd zsh-setup-*/
chmod +x install.sh
./install.sh
```

To uninstall, run:
```bash
./uninstall.sh
```

For advanced/manual uninstallation, you can run:
```bash
./zsh-setup-uninstall.sh
```

The `install.sh` script automates the full setup process—fonts, Zsh, Oh My Zsh, Oh My Posh, and recommended plugins.  
No manual steps required—just run the installer!

See the main README for the latest release links and details on advanced/manual uninstallation.

---

## Script Flags & Options

All scripts support flags for automation, safety, and advanced usage.

### Main Setup Script (`zsh_oh_my_posh_setup.sh`)

| Flag/Option      | Description                                                                                   |
|------------------|----------------------------------------------------------------------------------------------|
| `-h`, `--help`   | Show help message and exit                                                                   |
| `-f`, `--force`  | Force reinstallation/reconfiguration of all components                                       |
| `--update-rc`    | Only update the `~/.zshrc` configuration file (skip installations)                           |
| `--dry-run`      | Preview planned changes without applying them                                                |
| `--no-prompt`    | Run non-interactively (for CI/dotfiles automation)                                           |
| `--self-check`   | Run environment and config self-checks before setup                                          |

### Font Installation Script (`install_fonts.sh`)

- Prompts for backup before modifying fonts
- Skips already-installed fonts (idempotent)
- Checks disk space and network connectivity

### Uninstall Script (`uninstall.sh`)

- Selective uninstall options (everything, only Oh My Posh, only plugins, only Zsh)
- Prompts for backup and rollback on failure

---

## Step-by-Step Setup Guide

1. **Install Nerd Fonts**
   - Run `./install_fonts.sh`
   - Follow prompts to back up existing fonts and configure your terminal font

2. **Run Main Setup**
   - Run `./zsh_oh_my_posh_setup.sh`
   - Choose your preferred Oh My Posh theme
   - Confirm backup of `.zshrc` before changes
   - Select plugins to install

3. **Customize `.zshrc`**
   - Manual customizations can be added outside auto-generated blocks
   - See `example.zshrc` for best practices

4. **Restart Terminal**
   - Run `zsh` or open a new terminal window

---

## Backup, Rollback & Safety Features

- **Automatic Backups:**  
  Before modifying `.zshrc` or fonts, scripts create timestamped backups in your home directory or `~/.zsh-setup-backups/`.
- **Rollback on Failure:**  
  If an error occurs, you are prompted to restore from the latest backup.
- **Idempotency:**  
  Auto-generated config blocks are replaced, not duplicated.
- **Disk & Network Checks:**  
  Scripts check for sufficient disk space and internet connectivity before major operations.
- **Logging:**  
  All actions and errors are logged to `~/.zsh-setup.log` for troubleshooting.

---

## Theme & Plugin Management

### Changing Themes

```bash
./change_posh_theme.sh
```
- Preview themes before applying
- Backup `.zshrc` before changes
- Only one theme block present (idempotent)

### Managing Plugins

- Plugins are installed to `~/.oh-my-zsh/custom/plugins`
- Auto-suggestions, syntax highlighting, completions, and fuzzy search are enabled by default
- Use arrays/maps for easy maintenance

---

## Advanced Usage

### Non-Interactive Automation

```bash
./zsh_oh_my_posh_setup.sh --no-prompt --dry-run
```
- Suitable for CI, dotfiles, or unattended installs

### Update Only `.zshrc`

```bash
./zsh_oh_my_posh_setup.sh --update-rc
```
- Skips installations, only updates config

### Self-Check/Test Mode

```bash
./zsh_oh_my_posh_setup.sh --self-check
```
- Validates environment, config syntax, and prerequisites

---

## Troubleshooting & FAQ

**Q: How do I restore a previous .zshrc backup?**  
A: Use: `cp ~/.zshrc.backup.* ~/.zshrc` and then `source ~/.zshrc`

**Q: How do I run a dry-run to preview changes?**  
A: Run `./zsh_oh_my_posh_setup.sh --dry-run`

**Q: Can I skip font installation or prompts?**  
A: Yes, use `--no-prompt` for non-interactive mode

**Q: How do I enable NVM support in Oh My Posh?**  
A: Install NVM separately and ensure it's in your `$PATH`. The theme must include the NVM segment.  
_Note: The setup script does NOT install or initialize NVM for you._

**Q: How do I rollback if something fails?**  
A: If installation or uninstall fails, you will be prompted to restore from the latest backup automatically.

**Q: Where are logs stored?**  
A: All actions and errors are logged to `~/.zsh-setup.log`

---

## Restoring Backups

1. Find your latest backup:
   ```bash
   ls -t ~/.zshrc.backup.*
   ```
2. Restore:
   ```bash
   cp ~/.zshrc.backup.YYYYMMDD_HHMMSS ~/.zshrc
   source ~/.zshrc
   ```

---

## Self-Check & Testing

- Run `./zsh_oh_my_posh_setup.sh --self-check` to validate:
  - Required commands
  - Disk space and network
  - Config file syntax
  - Plugin and theme availability

---

## Contributing

- Fork the repository and create a feature branch
- Follow code style and safety best practices (strict error handling, idempotency, backups, logging)
- Add comments and documentation for new features
- Test your changes in a safe environment
- Open a Pull Request and respond to feedback

See [CONTRIBUTING.md](CONTRIBUTING.md) for full guidelines.

---

## Support & Feedback

- For help, open an issue on GitHub
- For feature requests, use the "Issues" tab and label your request
- For security concerns, contact the maintainers directly

---

**Thank you for using zsh-setup! Your safety, productivity, and feedback are our priorities.**