#!/bin/bash

# Log file for error and action logging
LOG_FILE=~/.zsh-setup.log
mkdir -p "$(dirname "$LOG_FILE")" || true
touch "$LOG_FILE" || true
chmod 600 "$LOG_FILE" || true

# Define colors as variables for better maintainability
readonly RED='\033[1;31m'
readonly GREEN='\033[1;32m'
readonly BLUE='\033[1;34m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Helper function for colored output and logging
log() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') $message" >> "$LOG_FILE"
}

# Error handler for robust error logging
trap '{
    log "$RED" "Error on line $LINENO. Previous command exited with status $?"
}' ERR

# Check for required commands and network connectivity
check_requirements() {
    local requirements=(wget unzip)
    for cmd in "${requirements[@]}"; do
        if ! command -v "$cmd" > /dev/null; then
            log "$RED" "Error: $cmd is not installed. Installing..."
            sudo apt update && sudo apt install -y "$cmd"
        fi
    done

    # Check network connectivity
    if ! ping -c 1 github.com &>/dev/null; then
        log "$RED" "Network check failed. Cannot reach github.com. Please check your internet connection."
        exit 1
    fi

    # Check disk space (minimum 100MB required)
    local avail_space
    avail_space=$(df "$HOME" | awk 'NR==2 {print $4}')
    if [ "$avail_space" -lt 102400 ]; then
        log "$RED" "Insufficient disk space. At least 100MB required in $HOME."
        exit 1
    fi
}

# Function to install Nerd Fonts with idempotency and backup confirmation
install_fonts() {
    local FONTS_DIR="$HOME/.local/share/fonts"
    local TEMP_DIR=$(mktemp -d)

    # Backup fonts directory if it exists
    if [ -d "$FONTS_DIR" ]; then
        local backup_dir="$HOME/.zsh-setup-backups/fonts_backup_$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$(dirname "$backup_dir")"
        cp -r "$FONTS_DIR" "$backup_dir"
        log "$BLUE" "Backup of existing fonts created at $backup_dir"
        echo "Backup created at $backup_dir. Continue with font installation? (y/n): "
        read -r confirm_backup
        if [[ ! "$confirm_backup" =~ ^[Yy]$ ]]; then
            log "$YELLOW" "Font installation cancelled by user after backup."
            exit 0
        fi
    fi
    log "$BLUE" "Installing required fonts..."
    log "$BLUE" "# --- BEGIN NERD FONTS INSTALLATION ---"
    # Create fonts directory if it doesn't exist
    mkdir -p "$FONTS_DIR"

    # List of recommended Nerd Fonts for Oh My Posh
    local fonts=(
        "CascadiaCode"
        "FiraCode"
        "Meslo"
        "JetBrainsMono"
        "Hack"
    )
    # Download and install fonts (idempotent: skip if already installed)
    for font in "${fonts[@]}"; do
        if [ -d "$FONTS_DIR/$font" ] && [ "$(ls -A "$FONTS_DIR/$font")" ]; then
            log "$GREEN" "$font Nerd Font already installed. Skipping."
            continue
        fi
        log "$YELLOW" "Installing $font Nerd Font..."
        # Download font
        wget -q "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip" -O "$TEMP_DIR/${font}.zip"
        if [ $? -ne 0 ]; then
            log "$RED" "Failed to download $font Nerd Font. Check network or permissions."
            continue
        fi
        # Unzip and install font
        unzip -q -o "$TEMP_DIR/${font}.zip" -d "$FONTS_DIR/${font}" 2>/dev/null
        if [ $? -ne 0 ]; then
            log "$RED" "Failed to unzip $font Nerd Font. Check disk space or permissions."
            continue
        fi
        # Clean up zip file
        rm "$TEMP_DIR/${font}.zip"
    done
    # Update font cache
    log "$BLUE" "Updating font cache..."
    fc-cache -f
    log "$BLUE" "# --- END NERD FONTS INSTALLATION ---"
    # Clean up temporary directory
    rm -rf "$TEMP_DIR"
    # Configure terminal font settings
    log "$GREEN" "✨ Fonts installed successfully!"
    log "$YELLOW" "\nPlease manually set your terminal font to one of the following Nerd Fonts:"
    for font in "${fonts[@]}"; do
        echo "  • ${font} Nerd Font"
    done
    log "$BLUE" "# --- BEGIN TERMINAL FONT INSTRUCTIONS ---"
    # Instructions for different terminals
    cat << 'EOL'

📝 Terminal Font Configuration Instructions:

1. GNOME Terminal:
   • Right-click in terminal → Preferences
   • Select your profile
   • Check "Custom font" box
   • Choose one of the installed Nerd Fonts (e.g., "JetBrainsMono Nerd Font")

2. Konsole:
   • Settings → Edit Current Profile
   • Appearance tab → Font
   • Select one of the installed Nerd Fonts

3. VS Code:
   • Open Settings (Ctrl+,)
   • Search for "terminal.integrated.fontFamily"
   • Set to: "JetBrainsMono Nerd Font" (or any other installed Nerd Font)
   • Add to settings.json:
     "terminal.integrated.fontFamily": "JetBrainsMono Nerd Font"

4. Terminator:
   • Right-click → Preferences
   • Profiles tab → General tab
   • Uncheck "Use system font"
   • Choose one of the installed Nerd Fonts

Would you like to configure your terminal font now? (y/n):
EOL
    log "$BLUE" "# --- END TERMINAL FONT INSTRUCTIONS ---"
    read -r configure_font
    if [[ "$configure_font" =~ ^[Yy]$ ]]; then
        # Try to detect and configure terminal
        if [[ "$TERM" == "xterm-256color" && -n "$GNOME_TERMINAL_SERVICE" ]]; then
            # GNOME Terminal detected
            gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$(gsettings get org.gnome.Terminal.ProfilesList default)/ font 'JetBrainsMono Nerd Font 12'
            log "$GREEN" "✨ GNOME Terminal font configured!"
        else
            log "$YELLOW" "Please configure your terminal font manually using the instructions above."
        fi
    fi
    # End of install_fonts function
}

# Main function
main() {
    log "$BLUE" "# --- BEGIN FONT INSTALLATION SCRIPT ---"
    check_requirements
    install_fonts
    log "$GREEN" "\n✨ Font installation completed! Please restart your terminal after configuring the font."
    log "$YELLOW" "You can now proceed with running the zsh setup script."
    log "$BLUE" "# --- END FONT INSTALLATION SCRIPT ---"
}

# Run main function
main
