#!/bin/bash

# Set strict error handling
set -euo pipefail

# Log file for errors and actions
LOG_FILE="$HOME/.zsh-setup.log"
mkdir -p "$(dirname "$LOG_FILE")" || true
touch "$LOG_FILE" || true
chmod 600 "$LOG_FILE" || true

# Error handler: log to file and stderr
trap '{
    echo "Error on line $LINENO. Previous command exited with status $?" >&2
    echo "Error on line $LINENO. Previous command exited with status $?" >> "$LOG_FILE"
}' ERR

# Define colors for better readability
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

# Directory where Oh My Posh themes are stored
readonly THEMES_DIR="$HOME/.oh-my-posh-themes"
readonly PREVIEW_TIME=3  # Time in seconds to preview each theme
readonly ZSHRC_FILE="$HOME/.zshrc"
readonly ZSHRC_BACKUP="$HOME/.zshrc.backup" # Fixed backup file name
readonly OMP_MARKER_START="# --- Oh My Posh Theme Start ---"
readonly OMP_MARKER_END="# --- Oh My Posh Theme End ---"
readonly BACKUP_CONFIRM_PROMPT="Do you want to create a backup of your current .zshrc before applying a new theme? (y/n): "

# Function to check dependencies
check_dependencies() {
    local missing_deps=()
    command -v oh-my-posh &> /dev/null || missing_deps+=("oh-my-posh")
    command -v wget &> /dev/null || missing_deps+=("wget")
    command -v unzip &> /dev/null || missing_deps+=("unzip")

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log "$RED" "Error: Missing dependencies: ${missing_deps[*]}"
        log "$YELLOW" "Please install the missing dependencies and try again."
        exit 1
    fi

    # Check disk space (minimum 100MB required)
    local available_space
    available_space=$(df "$HOME" | awk 'NR==2 {print $4}')
    if (( available_space < 102400 )); then
        log "$RED" "Insufficient disk space. At least 100MB required."
        exit 1
    fi

    # Check network connectivity
    if ! ping -c 1 github.com &>/dev/null; then
        log "$RED" "Network connectivity check failed. Please check your internet connection."
        exit 1
    fi
}

# Function to validate themes directory
check_themes_dir() {
    if [ ! -d "$THEMES_DIR" ]; then
        log "$RED" "Error: Oh My Posh themes directory not found at $THEMES_DIR"
        log "$YELLOW" "Attempting to create and download themes..."

        mkdir -p "$THEMES_DIR"
        local themes_zip="$THEMES_DIR/themes.zip"

        # Remove potentially corrupted old zip file
        rm -f "$themes_zip"

        log "$BLUE" "Downloading themes..."
        if wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip -O "$themes_zip"; then
            log "$BLUE" "Unzipping themes..."
            if unzip "$themes_zip" -d "$THEMES_DIR"; then
                rm "$themes_zip"
                log "$GREEN" "Themes downloaded and unpacked successfully!"
            else
                log "$RED" "Failed to unzip themes. Check permissions or disk space."
                rm -f "$themes_zip" # Clean up zip on failure
                exit 1
            fi
        else
            log "$RED" "Failed to download themes. Please check your internet connection."
            exit 1
        fi
    fi
}

# Function to get the last installed theme from .zshrc using markers
get_last_installed_theme() {
    # Idempotency: Only show last theme if markers exist
    if [ ! -f "$ZSHRC_FILE" ]; then
        log "$YELLOW" "\n⚠️ .zshrc file not found. Cannot determine last theme."
        return
    fi

    # Extract the theme path between the markers
    local theme_line=$(sed -n "/^${OMP_MARKER_START}$/,/^${OMP_MARKER_END}$/{ /eval.*--config/p; }" "$ZSHRC_FILE" | head -n 1)

    if [[ -n "$theme_line" ]]; then
        # Extract the path using parameter expansion or sed
        local last_theme=$(echo "$theme_line" | sed -n "s/.*--config '\([^']*\)'.*/\1/p")
        if [[ -n "$last_theme" ]]; then
            log "$GREEN" "\n🎨 Last applied theme: $(basename "$last_theme")"
        else
             log "$YELLOW" "\n⚠️ Could not parse theme from .zshrc markers."
        fi
    else
        log "$YELLOW" "\n⚠️ No Oh My Posh theme configuration found between markers in $ZSHRC_FILE."
    fi
}

# Function to list themes
list_themes() {
    # Expects the themes array to be passed as an argument ($1: name of the array)
    local -n themes_ref=$1 # Use nameref for indirect array access
    local count=1

    log "$BLUE" "\nAvailable Oh My Posh themes:"
    log "$YELLOW" "----------------------------------------"

    for theme in "${themes_ref[@]}"; do
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

    # Check if .zshrc exists
    if [ ! -f "$ZSHRC_FILE" ]; then
        log "$RED" "Error: $ZSHRC_FILE not found. Cannot apply theme."
        log "$YELLOW" "Please ensure your Zsh configuration file exists."
        exit 1
    fi

    # Remove previous backup and create a new one with a fixed name
    log "$BLUE" "Backing up $ZSHRC_FILE to $ZSHRC_BACKUP..."
    rm -f "$ZSHRC_BACKUP" # Remove old backup first
    cp "$ZSHRC_FILE" "$ZSHRC_BACKUP"

    # Remove previous Oh My Posh configuration block using markers
    log "$BLUE" "Removing previous Oh My Posh theme configuration (if any)..."
    # Use awk for safer multi-line deletion between markers
    # Read from current file, write to temporary file, then replace original
    local temp_file=$(mktemp)
    awk -v start="$OMP_MARKER_START" -v end="$OMP_MARKER_END" '
        $0 == start {p=1}
        !p {print}
        $0 == end {p=0}
    ' "$ZSHRC_FILE" > "$temp_file" && mv "$temp_file" "$ZSHRC_FILE"

    # Add new theme configuration with markers (idempotent: only one block)
    log "$BLUE" "Applying new theme: $theme_name..."
    {
        echo "$OMP_MARKER_START"
        echo "# BEGIN: Oh My Posh theme block (auto-generated)"
        echo "eval \"\$(oh-my-posh init zsh --config '$theme_path')\""
        echo "# END: Oh My Posh theme block"
        echo "$OMP_MARKER_END"
    } >> "$ZSHRC_FILE"

    log "$GREEN" "Theme '$theme_name' successfully applied to $ZSHRC_FILE."
    log "$YELLOW" "Backup created at $ZSHRC_BACKUP"
    log "$YELLOW" "Restarting Zsh to apply changes..."

    # Apply changes by restarting zsh
    exec zsh
}

# Main function
main() {
    check_dependencies
    check_themes_dir

    while true; do
        # Get available themes sorted alphabetically
        mapfile -t themes < <(find "$THEMES_DIR" -name "*.omp.json" -type f | sort)
        local theme_count=${#themes[@]}

        if [ "$theme_count" -eq 0 ]; then
             log "$RED" "No Oh My Posh themes (*.omp.json) found in $THEMES_DIR."
             exit 1
        fi

        # List themes
        list_themes themes # Pass the array name 'themes'

        # Show last installed theme after the list
        get_last_installed_theme

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
            # Backup confirmation prompt for safety
            read -p "$BACKUP_CONFIRM_PROMPT" backup_confirm
            if [[ "$backup_confirm" =~ ^[Yy]$ ]]; then
                log "$BLUE" "Creating backup of $ZSHRC_FILE to $ZSHRC_BACKUP..."
                cp "$ZSHRC_FILE" "$ZSHRC_BACKUP"
                log "$GREEN" "Backup created at $ZSHRC_BACKUP"
            else
                log "$YELLOW" "Skipping backup as per user choice."
            fi

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
