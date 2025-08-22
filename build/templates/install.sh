zsh-setup/build/templates/install.sh
#!/usr/bin/env bash
# Installer for zsh-setup (Distribution Package)
# This script automates the installation of Zsh, Oh My Zsh, Oh My Posh, recommended fonts, and plugins.

set -e

echo "🚀 Installing Zsh Setup..."

# Ensure all scripts are executable
chmod +x *.sh

# Install recommended fonts for prompt themes
echo "🔤 Installing recommended fonts..."
./install_fonts.sh

# Run the main setup script for Zsh, Oh My Zsh, Oh My Posh, and plugins, forwarding all flags
echo "🛠️ Running main setup script..."
./zsh_oh_my_posh_setup.sh "$@"

echo ""
echo "✅ Installation complete!"
echo "👉 See example.zshrc for a sample configuration."
echo "ℹ️ For advanced usage and troubleshooting, refer to USER_MANUAL.md."
