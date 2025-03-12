#!/bin/bash

# Set strict error handling
set -euo pipefail

# Define colors for better readability
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

# Directory where Oh My Posh themes are stored
readonly THEMES_DIR="$HOME/.oh-my-posh-themes"
readonly PREVIEW_TIME=3  # Time in seconds to preview each theme

# Function to check dependencies
check_dependencies() {
    if ! command -v oh-my-posh &> /dev/null; then
        log "$RED" "Error: Oh My Posh is not installed."
        log "$YELLOW" "Please install Oh My Posh first using the setup script."
        exit 1
    fi
}

# Function to validate themes directory
check_themes_dir() {
    if [ ! -d "$THEMES_DIR" ]; then
        log "$RED" "Error: Oh My Posh themes directory not found at $THEMES_DIR"
        log "$YELLOW" "Attempting to create and download themes..."
        
        mkdir -p "$THEMES_DIR"
        if wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip -O "$THEMES_DIR/themes.zip"; then
            unzip "$THEMES_DIR/themes.zip" -d "$THEMES_DIR"
            rm "$THEMES_DIR/themes.zip"
            log "$GREEN" "Themes downloaded successfully!"
        else
            log "$RED" "Failed to download themes. Please check your internet connection."
            exit 1
        fi
    fi
}

# Function to list themes
list_themes() {
    local themes=("$THEMES_DIR"/*.json)
    local count=1
    
    log "$BLUE" "\nAvailable Oh My Posh themes:"
    log "$YELLOW" "----------------------------------------"
    
    for theme in "${themes[@]}"; do
        echo -e "${GREEN}$count)${NC} $(basename "$theme")"
        ((count++))
    done
    
    log "$YELLOW" "----------------------------------------"
}

# Function to preview a theme
preview_theme() {
    local theme_path=$1
    local theme_name=$(basename "$theme_path")
    
    log "$BLUE" "\nPreviewing theme: $theme_name"
    log "$YELLOW" "Preview will last for $PREVIEW_TIME seconds..."
    
    # Temporarily apply theme
    eval "$(oh-my-posh init zsh --config "$theme_path")"
    sleep "$PREVIEW_TIME"
}

# Function to apply the selected theme
apply_theme() {
    local theme_path=$1
    local theme_name=$(basename "$theme_path")
    
    # Backup current .zshrc
    cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)
    
    # Remove previous Oh My Posh configuration
    log "$BLUE" "Removing previous Oh My Posh theme configuration..."
    sed -i '/^eval "$(oh-my-posh init zsh --config /d' ~/.zshrc
    
    # Add new theme configuration
    log "$BLUE" "Applying new theme: $theme_name..."
    echo 'eval "$(oh-my-posh init zsh --config '"$theme_path"')" # Oh My Posh Theme' >> ~/.zshrc
    
    # Apply changes
    log "$BLUE" "Applying changes..."
    exec zsh
}

# Main function
main() {
    check_dependencies
    check_themes_dir
    
    while true; do
        list_themes
        
        # Get available themes
        mapfile -t themes < <(find "$THEMES_DIR" -name "*.json" -type f)
        theme_count=${#themes[@]}
        
        # Prompt for theme selection
        log "$BLUE" "\nOptions:"
        echo "- Enter a number (1-$theme_count) to select a theme"
        echo "- Enter 'p' followed by a number to preview a theme (e.g., 'p1')"
        echo "- Enter 'q' to quit"
        
        read -p "Your choice: " choice
        
        # Handle quit
        if [[ "$choice" == "q" ]]; then
            log "$GREEN" "No changes made. Exiting..."
            exit 0
        fi
        
        # Handle preview
        if [[ "$choice" =~ ^p[0-9]+$ ]]; then
            number=${choice:1}
            if ((number >= 1 && number <= theme_count)); then
                preview_theme "${themes[number-1]}"
                continue
            fi
        fi
        
        # Handle theme selection
        if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= theme_count)); then
            selected_theme="${themes[choice-1]}"
            
            log "$YELLOW" "\nYou selected: $(basename "$selected_theme")"
            read -p "Do you want to apply this theme? (y/n): " confirm
            
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                apply_theme "$selected_theme"
                break
            fi
        else
            log "$RED" "Invalid selection. Please try again."
        fi
    done
}

# Run main function
main

