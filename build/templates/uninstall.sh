zsh-setup/build/templates/uninstall.sh
#!/usr/bin/env bash
# Uninstaller for zsh-setup (Distribution Package)

set -e

echo "🧹 Uninstalling Zsh Setup..."

# Run the main uninstall script
if [[ -f ./zsh-setup-uninstall.sh ]]; then
    ./zsh-setup-uninstall.sh
else
    echo "⚠️ zsh-setup-uninstall.sh not found in the current directory."
fi

# Optionally restore previous .zshrc backup if it exists
if [[ -f ~/.zshrc.backup-zsh-setup ]]; then
    echo "🔄 Restoring previous .zshrc from backup..."
    mv ~/.zshrc.backup-zsh-setup ~/.zshrc
    echo "✅ .zshrc restored."
fi

# Remove Oh My Posh configuration if present
if [[ -d ~/.poshthemes ]]; then
    echo "🗑️ Removing Oh My Posh themes..."
    rm -rf ~/.poshthemes
fi

# Remove any log or temp files created by zsh-setup
rm -f /tmp/zsh-setup.log 2>/dev/null || true

echo ""
echo "✅ Uninstallation complete! Your previous configuration should be restored."
echo "ℹ️ You may need to restart your terminal for changes to take effect."
