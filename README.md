# zsh-setup

A modern Zsh environment setup with Oh My Posh themes, essential plugins, and advanced search capabilities.

## Overview

- Automates Zsh, Oh My Zsh, Oh My Posh, and plugin setup
- **New!** Includes modern CLI tools: `zoxide`, `eza`, `bat`, `delta`, `tldr`
- **New!** Selective plugin uninstallation
- Includes robust safety features (backups, error logging, rollback)
- Supports non-interactive and dry-run modes for automation
- Compatible with Ubuntu/Debian-based Linux

## Quick Start

```bash
git clone https://github.com/Easy-Cloud-in/zsh-setup.git
cd zsh-setup
chmod +x *.sh
./install_fonts.sh
./zsh_oh_my_posh_setup.sh
```

## Install from Zip Release

You can install zsh-setup directly from a GitHub release zip package:

```bash
# Download the latest release from GitHub
wget https://github.com/Easy-Cloud-in/zsh-setup/releases/download/v1.0.0/zsh-setup-v1.0.0.zip

# Unzip and enter the directory
unzip zsh-setup-v1.0.0.zip
cd zsh-setup-*/

# Run the installer script
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

The `install.sh` script will set up fonts, Zsh, Oh My Zsh, Oh My Posh, and recommended plugins automatically.

See [User Manual](USER_MANUAL.md) for more details.

For more details, advanced usage, flags, troubleshooting, and customization, see the [User Manual](USER_MANUAL.md).

## Documentation & Support

- [User Manual](USER_MANUAL.md): Full usage, flags, troubleshooting, and customization guide
- [CHANGELOG.md](CHANGELOG.md): Version history and updates
- [CONTRIBUTING.md](CONTRIBUTING.md): Contribution guidelines

## License

MIT License - See [LICENSE](LICENSE) for details

## Author

[Sakar SR](https://github.com/Easy-Cloud-in)  
[Easy-Cloud.in](https://easy-cloud.in)

