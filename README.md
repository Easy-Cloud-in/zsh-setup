# Enhanced Zsh Setup with Oh My Posh and Fuzzy Search

A powerful Zsh environment setup with Oh My Posh themes, essential plugins, and advanced search capabilities. This repository provides scripts to automatically configure your terminal with modern features and aesthetics.

## System Requirements

- Minimum 256MB RAM
- 100MB free disk space
- Internet connection for installation
- Terminal with Unicode support

## Prerequisites

- Ubuntu/Debian-based Linux distribution
- Basic terminal knowledge
- Git installed (`sudo apt install git`)
- **Nerd Fonts** - Required for proper icon display
  - If not installed, run `./install_fonts.sh` before proceeding with the setup
  - Recommended fonts: JetBrainsMono Nerd Font, Meslo LGM Nerd Font, or FiraCode Nerd Font
  - After installing fonts, configure your terminal to use one of the Nerd Fonts
  - Restart your terminal after font configuration

## Quick Start

```bash
# Clone the repository
git clone https://github.com/Easy-Cloud-in/zsh-setup.git
cd zsh-setup

# Make scripts executable
chmod +x *.sh

# Install and configure Nerd Fonts (if not already installed)
./install_fonts.sh
# After font installation, configure your terminal to use a Nerd Font and restart your terminal

# Run the setup script
./zsh_oh_my_posh_setup.sh

# Start using Zsh (either open a new terminal or run):
zsh
```

## Detailed Installation Steps

1. **Clone the Repository**

   ```bash
   git clone https://github.com/Easy-Cloud-in/zsh-setup.git
   cd zsh-setup
   ```

2. **Make Scripts Executable**

   ```bash
   chmod +x *.sh
   ```

3. **Install Required Fonts (if not already installed)**

   ```bash
   ./install_fonts.sh
   ```

   - Configure your terminal to use one of the installed Nerd Fonts
   - For VS Code, add to settings.json:
     ```json
     {
       "terminal.integrated.fontFamily": "JetBrainsMono Nerd Font",
       "editor.fontFamily": "JetBrainsMono Nerd Font"
     }
     ```
   - Restart your terminal/editor after font configuration

4. **Run the Setup Script**

   ```bash
   ./zsh_oh_my_posh_setup.sh
   ```

5. **Restart Your Terminal**
   ```bash
   zsh
   ```

## Features Installed

### 1. Zsh Plugins

#### Auto Suggestions

- Automatically suggests commands as you type
- Accept suggestion: `Right Arrow` or `Ctrl + E`
- Accept word: `Alt + Right Arrow`

#### Syntax Highlighting

- Commands appear in green if valid
- Red if invalid
- Yellow for aliases
- Blue for functions

#### Git Plugin Shortcuts

- `gst` - git status
- `ga` - git add
- `gc` - git commit
- `gp` - git push
- `gl` - git pull
- Full list: Run `alias | grep git`

### 2. Fuzzy Search Tools

#### fzf (Fuzzy Finder)

- `Ctrl + T` - Fuzzy file search
- `Ctrl + R` - Search command history
- `Alt + C` - Fuzzy directory navigation

#### File Search Functions

```bash
# Search file contents
fif "search term"

# Find files
fd pattern

# Search with ripgrep
rg "pattern"
```

### 3. Oh My Posh Themes

Change theme anytime:

```bash
./change_posh_theme.sh
```

## Customization

### Change Theme

1. List themes:

   ```bash
   ls ~/.oh-my-posh-themes/*.json
   ```

2. Change theme:
   ```bash
   ./change_posh_theme.sh
   ```

### Modify Configuration

```bash
# Edit Zsh settings
nano ~/.zshrc

# Apply changes
source ~/.zshrc
```

## Updates

To update all components to their latest versions:

```bash
./zsh_oh_my_posh_setup.sh -f
```

## Security

This project:

- Does not collect any personal data
- Requires sudo access only for package installation
- Creates backups before modifying any config files
- All scripts are open source and can be reviewed

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and updates.

## Troubleshooting

### Font Issues

- Make sure Nerd Fonts are installed correctly
- Verify terminal is using a Nerd Font
- Try reinstalling fonts: `./install_fonts.sh`

### Theme Issues

```bash
# Check themes directory
ls -l ~/.oh-my-posh-themes/

# Reinitialize Oh My Posh
oh-my-posh init zsh
```

### Configuration Issues

```bash
# Restore backup
cp ~/.zshrc.backup.* ~/.zshrc

# Rebuild cache
rm ~/.zcompdump*
compinit
```

### Common Issues

- If you see boxes or question marks instead of icons:

  - Verify terminal is using a Nerd Font
  - Run `fc-list | grep "Nerd"` to confirm font installation
  - Try different Nerd Font if issues persist

- If prompt looks broken:
  - Check terminal font settings
  - Try updating Oh My Posh: `./zsh_oh_my_posh_setup.sh -f`
  - Verify terminal supports Unicode

## Uninstallation

Remove all components:

```bash
uninstall_oh_my_zsh
rm -rf ~/.oh-my-posh-themes
rm -rf ~/.fzf
sudo apt remove zsh ripgrep fd-find
```

## Contributing

1. Fork the repository
2. Create your feature branch:
   ```bash
   git checkout -b feature/AmazingFeature
   ```
3. Commit your changes:
   ```bash
   git commit -m 'Add some AmazingFeature'
   ```
4. Push to the branch:
   ```bash
   git push origin feature/AmazingFeature
   ```
5. Open a Pull Request

## License

MIT License - See [LICENSE](LICENSE) for details

## Author

[Sakar SR](https://github.com/Easy-Cloud-in)  
[Easy-Cloud.in](https://easy-cloud.in)

## Support

- Star this repository if you find it helpful
- Report issues on GitHub with:
  - Your OS version
  - Terminal emulator and version
  - Steps to reproduce the issue
  - Error messages (if any)
- Submit pull requests with improvements
- Share with others who might benefit
- Follow [Easy-Cloud.in](https://easy-cloud.in) for updates

## Credits & Acknowledgments

This project stands on the shoulders of giants. Special thanks to:

### Core Components

- [Zsh](https://www.zsh.org/) - The powerful shell that makes this possible
- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) - Framework for managing Zsh configuration
- [Oh My Posh](https://github.com/JanDeDobbeleer/oh-my-posh) - Prompt theme engine
- [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) - Iconic font aggregator

### Search Tools

- [fzf](https://github.com/junegunn/fzf) - Command-line fuzzy finder
- [ripgrep](https://github.com/BurntSushi/ripgrep) - Line-oriented search tool
- [fd](https://github.com/sharkdp/fd) - Simple, fast alternative to 'find'

### Zsh Plugins

- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
- [zsh-completions](https://github.com/zsh-users/zsh-completions)
- [fzf-tab](https://github.com/Aloxaf/fzf-tab)

### Additional Tools

- [bat](https://github.com/sharkdp/bat) - A cat clone with syntax highlighting

These projects have made our terminal experience better, and we're grateful for their continuous work in the open-source community.

---

Made with ❤️ by [Easy-Cloud.in](https://easy-cloud.in)

## Usage

To run the setup script:

```bash
./zsh_oh_my_posh_setup.sh [options]
```

**Available Options:**

*   `-h`, `--help`: Show the help message and exit.
*   `-f`, `--force`: Force reinstallation of Zsh, Oh My Zsh, Oh My Posh, and plugins, even if they seem to be installed already. This also overwrites the existing `.zshrc` backup.
*   `--update-rc`: Only update the `~/.zshrc` configuration file. Skips installation checks and plugin updates. Useful for quickly applying changes to the `.zshrc` template or switching themes without reinstalling components.

**Example:**

Run the full setup:
```bash
./zsh_oh_my_posh_setup.sh
```

Force a full reinstall/reconfiguration:
```bash
./zsh_oh_my_posh_setup.sh --force
```

Only update the `.zshrc` file (e.g., after modifying the script or to change themes):
```bash
./zsh_oh_my_posh_setup.sh --update-rc
```
