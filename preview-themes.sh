#!/bin/bash

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
THEMES_DIR="$HOME/.oh-my-posh-themes"

# Check if Oh My Posh is installed
if ! command -v oh-my-posh &> /dev/null; then
    log "$RED" "Oh My Posh is not installed. Please install it first."
    exit 1
fi

# Check if themes directory exists and download if needed
if [ ! -d "$THEMES_DIR" ]; then
    log "$YELLOW" "Themes directory not found. Downloading themes..."
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

# Function to preview a theme
preview_theme() {
    local theme_path=$1
    local theme_name=$(basename "$theme_path")
    
    clear
    log "$BLUE" "Applying theme: $theme_name"
    log "$YELLOW" "Theme will remain active until you select another."
    
    # Apply the theme interactively to the current shell session
    eval "$(oh-my-posh init bash --config "$theme_path")"
    
    # Persist the theme by updating the shell configuration
    if [[ "$SHELL" == *"bash"* ]]; then
        echo "eval \"\$(oh-my-posh init bash --config '$theme_path')\"" > ~/.bashrc
        log "$GREEN" "Theme applied and saved in ~/.bashrc (Restart terminal or run 'source ~/.bashrc' to keep it applied)"
    elif [[ "$SHELL" == *"zsh"* ]]; then
        echo "eval \"\$(oh-my-posh init zsh --config '$theme_path')\"" > ~/.zshrc
        log "$GREEN" "Theme applied and saved in ~/.zshrc (Restart terminal or run 'source ~/.zshrc' to keep it applied)"
    fi
    
    echo
    log "$GREEN" "Theme applied! Open a new terminal or restart your session to reset."
}

# Get list of themes
themes=($(find "$THEMES_DIR" -name "*.json" -type f | sort))
total_themes=${#themes[@]}

# Display themes in a formatted grid
display_themes() {
    local columns=3
    local width=30
    
    log "$BLUE" "\n📚 Available Oh My Posh Themes"
    log "$YELLOW" "══════════════════════════════════════════════════════════════"
    
    local rows=$(( (total_themes + columns - 1) / columns ))
    
    for ((i = 0; i < rows; i++)); do
        for ((j = 0; j < columns; j++)); do
            local index=$((j * rows + i))
            if [ $index -lt $total_themes ]; then
                local theme_name=$(basename "${themes[$index]}" .json)
                printf "${GREEN}[%03d]${NC} %-${width}s" $((index + 1)) "$theme_name"
            fi
        done
        echo
    done
    
    log "$YELLOW" "══════════════════════════════════════════════════════════════"
}

# Main loop
while true; do
    display_themes
    
    log "$BLUE" "\n🎨 Options:"
    echo "  • Enter a number (1-$total_themes) to preview a theme"
    echo "  • Enter 'q' to quit"
    echo
    read -p "💫 Your choice: " choice
    
    if [[ "$choice" == "q" ]]; then
        log "$GREEN" "Thanks for previewing themes!"
        exit 0
    fi
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= total_themes)); then
        preview_theme "${themes[choice-1]}"
    else
        log "$RED" "Invalid selection. Please try again."
    fi
done
