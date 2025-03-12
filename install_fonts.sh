#!/bin/bash

# Define colors as variables for better maintainability
readonly RED='\033[1;31m'
readonly GREEN='\033[1;32m'
readonly BLUE='\033[1;34m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Helper function for colored output
log() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check for required commands
check_requirements() {
    local requirements=(wget unzip)
    for cmd in "${requirements[@]}"; do
        if ! command -v "$cmd" > /dev/null; then
            log "$RED" "Error: $cmd is not installed. Installing..."
            sudo apt update && sudo apt install -y "$cmd"
        fi
    done
}

# Function to install Nerd Fonts
install_fonts() {
    local FONTS_DIR="$HOME/.local/share/fonts"
    local TEMP_DIR=$(mktemp -d)
    
    log "$BLUE" "Installing required fonts..."
    
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
    
    # Download and install fonts
    for font in "${fonts[@]}"; do
        log "$YELLOW" "Installing $font Nerd Font..."
        
        # Download font
        wget -q "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip" -O "$TEMP_DIR/${font}.zip"
        
        # Unzip and install font
        unzip -q -o "$TEMP_DIR/${font}.zip" -d "$FONTS_DIR/${font}" 2>/dev/null || true
        
        # Clean up zip file
        rm "$TEMP_DIR/${font}.zip"
    done
    
    # Update font cache
    log "$BLUE" "Updating font cache..."
    fc-cache -f
    
    # Clean up temporary directory
    rm -rf "$TEMP_DIR"
    
    # Configure terminal font settings
    log "$GREEN" "✨ Fonts installed successfully!"
    log "$YELLOW" "\nPlease manually set your terminal font to one of the following Nerd Fonts:"
    for font in "${fonts[@]}"; do
        echo "  • ${font} Nerd Font"
    done
    
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
}

# Main function
main() {
    check_requirements
    install_fonts
    log "$GREEN" "\n✨ Font installation completed! Please restart your terminal after configuring the font."
    log "$YELLOW" "You can now proceed with running the zsh setup script."
}

# Run main function
main