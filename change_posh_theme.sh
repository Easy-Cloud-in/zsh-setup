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
readonly PREVIEW_TIME=3
readonly ZSHRC_FILE="$HOME/.zshrc"
readonly OMP_MARKER_START="# --- Oh My Posh Theme Start ---"
readonly OMP_MARKER_END="# --- Oh My Posh Theme End ---"
readonly BACKUP_DIR="$HOME/.zsh-backups"

# Robust backup function
backup_zshrc() {
    mkdir -p "$BACKUP_DIR"

    if [ -f "$ZSHRC_FILE" ]; then
        local timestamp=$(date +%Y%m%d_%H%M%S)
        local backup_file="$BACKUP_DIR/.zshrc.backup.$timestamp"
        
        log "$BLUE" "Creating backup of existing .zshrc to $backup_file"
        cp "$ZSHRC_FILE" "$backup_file"
        
        # Rotate backups: keep only the last 5
        local backups=($(ls -t "$BACKUP_DIR"/.zshrc.backup.* 2>/dev/null))
        if [ ${#backups[@]} -gt 5 ]; then
            log "$YELLOW" "Rotating old backups..."
            for ((i=5; i<${#backups[@]}; i++)); do
                rm "${backups[$i]}"
                log "$YELLOW" "Deleted old backup: ${backups[$i]}"
            done
        fi
        
        log "$GREEN" "Backup created and rotation applied."
    fi
}

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
    local -n themes_ref=$1
    local columns=3
    local width=30
    
    log "$BLUE" "\n📚 Available Oh My Posh Themes"
    log "$YELLOW" "══════════════════════════════════════════════════════════════"

    local total=${#themes_ref[@]}
    local rows=$(( (total + columns - 1) / columns ))

    for ((i = 0; i < rows; i++)); do
        for ((j = 0; j < columns; j++)); do
            local index=$((j * rows + i))
            if [ $index -lt $total ]; then
                local theme_name=$(basename "${themes_ref[$index]}" .omp.json)
                printf "${GREEN}[%03d]${NC} %-${width}s" $((index + 1)) "$theme_name"
            fi
        done
        echo
    done

    log "$YELLOW" "══════════════════════════════════════════════════════════════"
}

# Improved preview function using subshell
preview_theme_subshell() {
    local theme_path=$1
    local theme_name=$(basename "$theme_path")

    log "$BLUE" "\nPreviewing theme: $theme_name"
    log "$YELLOW" "Opening temporary shell with theme... Type 'exit' or Ctrl+D to return."

    # Create a temporary directory for ZDOTDIR
    local temp_dir=$(mktemp -d)
    local temp_zshrc="$temp_dir/.zshrc"
    
    cat << EOF > "$temp_zshrc"
# Preview configuration
export ZDOTDIR="$HOME" # Reset ZDOTDIR so subsequent shells find the real config if needed (optional)
source "$HOME/.zshrc" 2>/dev/null || true
# Override theme
eval "\$(oh-my-posh init zsh --config '$theme_path')"
echo
echo -e "\033[1;32m🎨 Previewing: $theme_name \033[0m"
echo "---------------------------------------------------"
echo "Try typing commands to see how the prompt behaves."
echo "Type 'exit' to return to the menu."
echo
EOF

    # Launch Zsh with the temp config directory
    # Zsh will look for .zshrc in ZDOTDIR
    ZDOTDIR="$temp_dir" zsh -i || true

    # Clean up
    rm -rf "$temp_dir"
    clear
}

# Interactive selection using fzf
interactive_fzf_selection() {
    local themes_dir=$1
    local fzf_path=$2
    
    # Send logs to stderr so they aren't captured by command substitution
    log "$BLUE" "Launching interactive preview with fzf..." >&2
    log "$YELLOW" "Use Arrow keys to navigate. The preview pane shows the prompt." >&2
    log "$YELLOW" "Press ENTER to select a theme, ESC to quit." >&2
    
    # We use --shell bash for preview but strip the \[ and \] markers using sed for clean rendering
    local selected_config=$(find "$themes_dir" -name "*.omp.json" -type f | \
        "$fzf_path" \
        --preview 'oh-my-posh print primary --config {} --shell bash | sed "s/\\\\\[//g; s/\\\\]//g"' \
        --preview-window 'top:45%' \
        --height '80%' \
        --layout=reverse \
        --header 'Select Oh My Posh Theme (ESC to Quit/Cancel)' \
        --border \
        --prompt 'Theme > '
    )
    
    if [ -n "$selected_config" ]; then
        echo "$selected_config"
        return 0
    fi
    
    return 1
}

# Function to apply the selected theme
apply_theme() {
    local theme_path=$1
    local theme_name=$(basename "$theme_path")
    
    if [ ! -f "$ZSHRC_FILE" ]; then
        log "$RED" "Error: $ZSHRC_FILE not found."
        exit 1
    fi

    backup_zshrc

    log "$BLUE" "Updating .zshrc..."
    
    # Create temp file
    local temp_file=$(mktemp)
    
    # Copy zshrc excluding old Posh block
    sed "/^${OMP_MARKER_START}$/,/^${OMP_MARKER_END}$/d" "$ZSHRC_FILE" > "$temp_file"
    
    # Append new block
    {
        echo "$OMP_MARKER_START"
        echo "# BEGIN: Oh My Posh theme block (auto-generated)"
        echo "eval \"\$(oh-my-posh init zsh --config '$theme_path')\""
        echo "# END: Oh My Posh theme block"
        echo "$OMP_MARKER_END"
    } >> "$temp_file"
    
    mv "$temp_file" "$ZSHRC_FILE"

    log "$GREEN" "✨ Theme '$theme_name' applied!"
    log "$YELLOW" "Restart your terminal or run 'exec zsh' to see changes."
    
    # Optional: Exec zsh to apply immediately
    read -p "Reload shell now? (y/N): " reload
    if [[ "$reload" =~ ^[Yy]$ ]]; then
        exec zsh
    fi
}

# Main function
main() {
    check_dependencies
    check_themes_dir

    # Check for fzf location
    local fzf_cmd=""
    if command -v fzf &> /dev/null; then
        fzf_cmd=$(command -v fzf)
    elif [ -f "$HOME/.fzf/bin/fzf" ]; then
        fzf_cmd="$HOME/.fzf/bin/fzf"
    fi

    # Auto-detect mode
    if [ -n "$fzf_cmd" ]; then
        log "$GREEN" "Interactive filter (fzf) detected."
        local selected
        if selected=$(interactive_fzf_selection "$THEMES_DIR" "$fzf_cmd"); then
             log "$YELLOW" "\nSelected theme: $(basename "$selected")"
             read -p "Apply this theme? (y/N): " confirm_fzf
             if [[ "$confirm_fzf" =~ ^[Yy]$ ]]; then
                 apply_theme "$selected"
             else
                 log "$YELLOW" "Cancelled. No changes made."
             fi
             exit 0
        else
             log "$YELLOW" "Selection cancelled."
             # Do not exit, fall back to menu or just exit? 
             # Usually cancellation means user wants to quit.
             # But let's ask if they want the manual menu.
             read -p "Open manual selection menu? (y/N): " manual_opt
             if [[ ! "$manual_opt" =~ ^[Yy]$ ]]; then
                 exit 0
             fi
        fi
    fi

    # Fallback to manual loop
    while true; do
        mapfile -t themes < <(find "$THEMES_DIR" -name "*.omp.json" -type f | sort)
        local theme_count=${#themes[@]}

        if [ "$theme_count" -eq 0 ]; then
             log "$RED" "No themes found."
             exit 1
        fi

        list_themes themes
        get_last_installed_theme

        log "$BLUE" "\n🎨 Options:"
        echo "  • Enter number (1-$theme_count) to select"
        echo "  • Enter 'p' + number to preview (e.g., 'p1')"
        echo "  • Enter 'q' to quit"
        echo
        read -p "💫 Your choice: " choice

        if [[ "$choice" == "q" ]]; then
            log "$GREEN" "Bye!"
            exit 0
        fi

        if [[ "$choice" =~ ^p([0-9]+)$ ]]; then
            number=${match[1]}
            if ((number >= 1 && number <= theme_count)); then
                preview_theme_subshell "${themes[number-1]}"
                continue
            fi
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= theme_count)); then
            selected_theme="${themes[choice-1]}"
            log "$YELLOW" "\n✨ Selected: $(basename "$selected_theme")"
            apply_theme "$selected_theme"
            break
        fi
        
        log "$RED" "Invalid choice."
    done
}

main
