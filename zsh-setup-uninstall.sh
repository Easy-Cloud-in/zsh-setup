#!/bin/bash

# Set strict error handling
set -euo pipefail

# Error logging setup
LOG_FILE=~/.zsh-setup.log
mkdir -p "$(dirname "$LOG_FILE")" || true
touch "$LOG_FILE" || true
chmod 600 "$LOG_FILE" || true

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

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to backup existing configurations
backup_configs() {
    local backup_dir="$HOME/zsh_backup_$(date +%Y%m%d_%H%M%S)"
    log "$BLUE" "Creating backup directory: $backup_dir"
    mkdir -p "$backup_dir"

    # Backup existing configurations
    if [ -f "$HOME/.zshrc" ]; then
        cp "$HOME/.zshrc" "$backup_dir/"
    fi
    if [ -f "$HOME/.zshenv" ]; then
        cp "$HOME/.zshenv" "$backup_dir/"
    fi
    if [ -f "$HOME/.zprofile" ]; then
        cp "$HOME/.zprofile" "$backup_dir/"
    fi
    if [ -f "$HOME/.zlogin" ]; then
        cp "$HOME/.zlogin" "$backup_dir/"
    fi
    if [ -f "$HOME/.zlogout" ]; then
        cp "$HOME/.zlogout" "$backup_dir/"
    fi
    if [ -d "$HOME/.oh-my-zsh" ]; then
        cp -r "$HOME/.oh-my-zsh" "$backup_dir/"
    fi
    if [ -d "$HOME/.oh-my-posh-themes" ]; then
        cp -r "$HOME/.oh-my-posh-themes" "$backup_dir/"
    fi
    if [ -d "$HOME/.zsh" ]; then
        cp -r "$HOME/.zsh" "$backup_dir/"
    fi

    log "$GREEN" "Backup created at: $backup_dir"
}

# Function to remove Oh My Posh
remove_oh_my_posh() {
    log "$BLUE" "Removing Oh My Posh..."

    local clean=true
    
    # Remove Oh My Posh binary
    if command_exists oh-my-posh; then
        if [ -f "/usr/local/bin/oh-my-posh" ]; then
            sudo rm -f /usr/local/bin/oh-my-posh || clean=false
        fi
        if [ -f "/usr/bin/oh-my-posh" ]; then
             sudo rm -f /usr/bin/oh-my-posh || clean=false
        fi
    fi

    # Remove themes and cache
    if [ -d "$HOME/.oh-my-posh-themes" ]; then
        rm -rf "$HOME/.oh-my-posh-themes" || clean=false
    fi
    if [ -d "$HOME/.poshthemes" ]; then
        rm -rf "$HOME/.poshthemes" || clean=false
    fi
     if [ -d "$HOME/.cache/oh-my-posh" ]; then
        rm -rf "$HOME/.cache/oh-my-posh" || clean=false
    fi

    # Remove init lines from shell configs
    for file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" "$HOME/.bash_profile" "$HOME/.zshenv" "$HOME/.zprofile"; do
        if [ -f "$file" ] && grep -qE "(oh-my-posh|poshthemes)" "$file"; then
            log "$BLUE" "Cleaning Oh My Posh entries from $file"
            # Create a temporary file
            temp_file=$(mktemp)
            # Remove Oh My Posh related lines more comprehensively
            grep -v -E "(oh-my-posh|poshthemes)" "$file" > "$temp_file" || true
            # Check if temp file is different from original before moving
            if ! cmp -s "$temp_file" "$file"; then
                mv "$temp_file" "$file" || clean=false
            else
                rm "$temp_file" # No changes needed, remove temp file
            fi
        fi
    done

    if [ "$clean" = true ]; then
        log "$GREEN" "Oh My Posh removed successfully"
        return 0
    else
        log "$YELLOW" "Some Oh My Posh components could not be removed."
        return 1
    fi
}

# Function to remove Oh My Zsh
remove_oh_my_zsh() {
    log "$BLUE" "Removing Oh My Zsh..."

    if [ -d "$HOME/.oh-my-zsh" ]; then
        if [ -f "$HOME/.oh-my-zsh/tools/uninstall.sh" ]; then
            # Use ZSH_DISABLE_COMPFIX=true to avoid compfix errors during uninstallation
            if ! ZSH_DISABLE_COMPFIX=true sh "$HOME/.oh-my-zsh/tools/uninstall.sh" --yes; then
                log "$RED" "Oh My Zsh uninstall script failed."
                return 1
            fi
        else
            rm -rf "$HOME/.oh-my-zsh" || return 1
        fi
        log "$GREEN" "Oh My Zsh removed successfully"
    else
        log "$YELLOW" "Oh My Zsh not found"
    fi
    return 0
}

# Function to remove Zsh plugins
remove_zsh_plugins() {
    log "$BLUE" "Removing Zsh plugins..."

    local plugins_dir="$HOME/.oh-my-zsh/custom/plugins"
    if [ -d "$plugins_dir" ]; then
        rm -rf "$plugins_dir/zsh-autosuggestions"
        rm -rf "$plugins_dir/zsh-syntax-highlighting"
        rm -rf "$plugins_dir/zsh-completions"
        rm -rf "$plugins_dir/fzf-tab"
        rm -rf "$plugins_dir/fast-syntax-highlighting"
        rm -rf "$plugins_dir/zsh-history-substring-search"
        rm -rf "$plugins_dir/powerlevel10k"
        log "$GREEN" "Zsh plugins removed successfully"
    else
        log "$YELLOW" "Zsh plugins directory not found"
    fi

    # Remove any standalone plugins
    rm -rf "$HOME/.zsh-autosuggestions"
    rm -rf "$HOME/.zsh-syntax-highlighting"
    rm -rf "$HOME/.fast-syntax-highlighting"
    rm -rf "$HOME/.zsh-completions"
}

# Function to remove specific plugins interactively
remove_specific_plugins() {
    log "$BLUE" "Scanning for installed plugins..."
    local plugins_dir="$HOME/.oh-my-zsh/custom/plugins"
    local plugins=()
    
    # Check OMZ plugins
    if [ -d "$plugins_dir" ]; then
        for d in "$plugins_dir"/*; do
            if [ -d "$d" ]; then
                plugins+=("$(basename "$d")")
            fi
        done
    fi

    # Check standalone plugins (common ones)
    local standalone=("zsh-autosuggestions" "zsh-syntax-highlighting" "fast-syntax-highlighting" "zsh-completions")
    for p in "${standalone[@]}"; do
        if [ -d "$HOME/.$p" ]; then
            plugins+=(".$p") # Mark with dot to indicate dotfile in home
        fi
    done

    if [ ${#plugins[@]} -eq 0 ]; then
        log "$YELLOW" "No custom plugins found to uninstall."
        return 0
    fi

    log "$YELLOW" "Found ${#plugins[@]} plugins/extensions."
    echo "Select plugins to uninstall (toggle with number, press Enter to confirm removal):"
    
    local selected=()
    # Initialize selection array (false = not selected)
    for ((i=0; i<${#plugins[@]}; i++)); do
        selected[i]=false
    done

    while true; do
        # Display list
        for ((i=0; i<${#plugins[@]}; i++)); do
            local status="[ ]"
            if [ "${selected[i]}" = true ]; then
                status="[${RED}x${NC}]"
            else
                status="[ ]"
            fi
            echo -e "$((i+1)). $status ${plugins[i]}"
        done
        echo "c. Confirm and Uninstall Selected"
        echo "q. Cancel"
        
        read -p "Enter number to toggle, 'c' to confirm, 'q' to quit: " choice
        
        if [[ "$choice" == "q" ]]; then
            log "$BLUE" "Operation cancelled."
            return 0
        elif [[ "$choice" == "c" ]]; then
            break
        elif [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#plugins[@]})); then
            idx=$((choice-1))
            if [ "${selected[idx]}" = true ]; then
                selected[idx]=false
            else
                selected[idx]=true
            fi
            clear # Refresh list
            log "$YELLOW" "Toggle selection for: ${plugins[idx]}"
        else
            echo "Invalid selection."
        fi
    done

    # Process removal
    local removal_count=0
    for ((i=0; i<${#plugins[@]}; i++)); do
        if [ "${selected[i]}" = true ]; then
            local p_name="${plugins[i]}"
            log "$BLUE" "Removing $p_name..."
            
            if [[ "$p_name" == .* ]]; then
                # It's a dotfile plugin in $HOME
                rm -rf "$HOME/$p_name"
            else
                # It's in OMZ custom plugins
                rm -rf "$plugins_dir/$p_name"
            fi
            removal_count=$((removal_count+1))
        fi
    done

    if [ $removal_count -gt 0 ]; then
        log "$GREEN" "Successfully removed $removal_count plugins."
    else
        log "$YELLOW" "No plugins selected for removal."
    fi
}

# Function to remove fuzzy search tools
remove_fuzzy_search() {
    log "$BLUE" "Removing fuzzy search tools..."
    local fzf_removed=false
    local rg_removed=false
    local fd_removed=false

    # Remove fzf
    if [ -d "$HOME/.fzf" ]; then
        if [ -f "$HOME/.fzf/uninstall" ]; then
             log "$BLUE" "Running fzf uninstaller..."
            # Run uninstall script non-interactively if possible, otherwise just remove dir
            "$HOME/.fzf/uninstall" --force || rm -rf "$HOME/.fzf"
        else
            rm -rf "$HOME/.fzf"
        fi
        fzf_removed=true
        log "$GREEN" "fzf (local installation) removed successfully"
    elif command_exists fzf; then
        log "$BLUE" "Removing fzf package (apt)..."
        sudo apt remove -y fzf && fzf_removed=true
    fi
    if [ "$fzf_removed" = false ]; then
         log "$YELLOW" "fzf not found."
    fi

    # Remove ripgrep and fd-find if installed via apt
    if command_exists rg; then
        log "$BLUE" "Removing ripgrep package (apt)..."
        sudo apt remove -y ripgrep && rg_removed=true
    else
         log "$YELLOW" "ripgrep (rg) not found."
    fi

    if command_exists fdfind || command_exists fd; then
         log "$BLUE" "Removing fd-find package (apt)..."
        sudo apt remove -y fd-find && fd_removed=true
    else
        log "$YELLOW" "fd-find (fd) not found."
    fi

    # Remove symlinks if they exist
    if [ -L "$HOME/.local/bin/fd" ]; then
        rm "$HOME/.local/bin/fd" && fd_removed=true
    fi
    if [ -L "$HOME/.local/bin/fzf" ]; then
        rm "$HOME/.local/bin/fzf" && fzf_removed=true
    fi
    if [ -L "$HOME/.local/bin/rg" ]; then
        rm "$HOME/.local/bin/rg" && rg_removed=true
    fi

    if [ "$fzf_removed" = true ] || [ "$rg_removed" = true ] || [ "$fd_removed" = true ]; then
        log "$GREEN" "Fuzzy search tools removed."
    fi
}

# Function to remove Powerlevel10k theme
remove_powerlevel10k() {
    log "$BLUE" "Removing Powerlevel10k theme..."
    local p10k_removed=false

    if [ -d "$HOME/powerlevel10k" ]; then
        rm -rf "$HOME/powerlevel10k"
        p10k_removed=true
    fi

    if [ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
        rm -rf "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
        p10k_removed=true
    fi

    if [ -f "$HOME/.p10k.zsh" ]; then
        rm -f "$HOME/.p10k.zsh"
        p10k_removed=true
    fi

    if [ "$p10k_removed" = true ]; then
         log "$GREEN" "Powerlevel10k removed successfully"
    else
         log "$YELLOW" "Powerlevel10k not found"
    fi
}

# Function to remove Zsh
# Function to remove Zsh
remove_zsh() {
    log "$BLUE" "Removing Zsh..."

    if command_exists zsh; then
        # Change default shell back to bash before removing zsh
        if [ "$SHELL" = "$(command -v zsh)" ]; then
            log "$BLUE" "Changing default shell back to bash..."
            chsh -s "$(command -v bash)"
        fi

        if sudo apt remove -y zsh && sudo apt autoremove -y; then
            log "$GREEN" "Zsh removed successfully"
        else
            log "$RED" "Failed to remove Zsh package."
            return 1
        fi
    else
        log "$YELLOW" "Zsh not found"
    fi
    return 0
}

# Function to clean up configuration files
cleanup_configs() {
    log "$BLUE" "Cleaning up configuration files..."
    local cleaned_files=false

    # List of specific Zsh files to remove
    local zsh_files=(
        "$HOME/.zshrc"
        "$HOME/.zshrc.pre-oh-my-zsh"
        "$HOME/.zshenv"
        "$HOME/.zprofile"
        "$HOME/.zlogin"
        "$HOME/.zlogout"
        "$HOME/.zcompdump"
        "$HOME/.zsh_history"
        "$HOME/.p10k.zsh" # Also removed in remove_powerlevel10k, but good to be sure
    )
    for file in "${zsh_files[@]}"; do
        if [ -f "$file" ]; then
            rm -f "$file" && cleaned_files=true
        fi
    done

    # List of specific Zsh directories/patterns to remove
    local zsh_dirs=(
        "$HOME/.zsh"
        "$HOME/.zsh_sessions"
        "$HOME/.cache/zsh"
        "$HOME/.zcomp-"* # Keep wildcard for generated files
        "$HOME/.oh-my-posh" # General Oh My Posh config dir
        "$HOME/.poshthemes" # Also removed in remove_oh_my_posh
        "$HOME/.zsh_plugins" # Specific plugin cache/data
        "$HOME/.zinit" # Zinit data
        "$HOME/.antigen" # Antigen data
    )
     for item in "${zsh_dirs[@]}"; do
         # Handle wildcard matching for directories/files safe way
         # Expand glob manually
         for found_item in $item; do
            if [ -e "$found_item" ]; then
                rm -rf "$found_item" && cleaned_files=true
            fi
         done
     done

    # Keep only the latest backup
    local backup_count
    backup_count=$(find "$HOME" -maxdepth 1 -name "zsh_backup_*" -type d | wc -l)
    if [ "$backup_count" -gt 1 ]; then
        log "$BLUE" "Pruning old backups..."
        find "$HOME" -maxdepth 1 -name "zsh_backup_*" -type d | sort | head -n -1 | xargs rm -rf
    fi

    if [ "$cleaned_files" = true ]; then
        log "$GREEN" "Configuration cleanup completed"
    else
        log "$YELLOW" "No specific configuration files/directories found to clean"
    fi
}

# Function to clean up shell entries
cleanup_shell_entries() {
    log "$BLUE" "Attempting to change default shell back to Bash..."

    # First ensure bash is available
    BASH_PATH=$(command -v bash)
    if [ -z "$BASH_PATH" ]; then
        log "$RED" "Could not find bash executable! Cannot change default shell."
        exit 1
    fi

    # Get current user's default shell
    local current_shell
    current_shell=$(getent passwd "$USER" | cut -d: -f7)
    local zsh_path
    zsh_path=$(command -v zsh)

    # Only attempt to change if the current shell is Zsh
    if [ "$current_shell" = "$zsh_path" ]; then
        log "$BLUE" "Current shell is Zsh. Attempting to switch to $BASH_PATH using chsh..."
        if chsh -s "$BASH_PATH" "$USER"; then
            log "$GREEN" "Successfully changed default shell to $BASH_PATH using chsh."
            # Update SHELL variable for the rest of the script if needed, though restarting is required for system-wide effect
            export SHELL="$BASH_PATH"
        else
            log "$RED" "---------------------------------------------------------------------"
            log "$RED" "ERROR: Failed to change shell using 'chsh -s $BASH_PATH $USER'."
            log "$YELLOW" "This might be due to permissions or system configuration (e.g., PAM)."
            log "$YELLOW" "Your default shell might still be Zsh."
            log "$YELLOW" "Please try changing it manually AFTER this script finishes:"
            log "$YELLOW" "  sudo chsh -s $BASH_PATH $USER"
            log "$YELLOW" "You may need to enter your password."
            log "$YELLOW" "Alternatively, consult your system's documentation for changing shells."
            log "$RED" "---------------------------------------------------------------------"
            # Removed the risky /etc/passwd modification part.
            # Script will continue, but user needs to fix shell manually.
        fi
    elif [ -n "$zsh_path" ]; then
         log "$YELLOW" "Current default shell is not Zsh ($current_shell). No change needed."
    else
         log "$YELLOW" "Zsh not found. Assuming shell does not need changing."
    fi

    # Clean up and restore /etc/shells - This part is generally safe
    # Clean up and restore /etc/shells - Using safer grep approach
    log "$BLUE" "Removing Zsh entries from /etc/shells..."
    local temp_shells_file
    temp_shells_file=$(mktemp)

    # Filter out anything containing 'zsh' from the existing file
    grep -v "zsh" /etc/shells > "$temp_shells_file"

    # Check if changes are needed before writing
    if ! sudo cmp -s "$temp_shells_file" /etc/shells; then
        log "$BLUE" "Updating /etc/shells..."
        sudo cp "$temp_shells_file" /etc/shells
        sudo chmod 644 /etc/shells
        log "$GREEN" "/etc/shells updated."
    else
        log "$GREEN" "/etc/shells is already consistent."
    fi
    rm "$temp_shells_file"
}

# Main function
main() {
    log "$YELLOW" "⚠️  Warning: This will remove Zsh, Oh My Posh, and all related configurations"
    log "$YELLOW" "    Your existing configurations will be backed up first"

    # Selective uninstall options
    echo -e "${YELLOW}Select what you want to uninstall:${NC}"
    echo "  1) Everything (Zsh, Oh My Posh, plugins, configs)"
    echo "  2) Only Oh My Posh"
    echo "  3) Only plugins"
    echo "  4) Only Zsh"
    echo "  5) Uninstall specific plugins"
    echo "  6) Cancel"
    read -p "Enter your choice [1-6]: " uninstall_choice

    if [[ "$uninstall_choice" == "6" ]]; then
        log "$BLUE" "Uninstallation cancelled"
        exit 0
    fi

    # Confirm backup creation and location
    log "$BLUE" "A backup of your configs will be created before any destructive actions."
    read -p "Proceed with backup and uninstall? (y/n): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log "$BLUE" "Uninstallation cancelled"
        exit 0
    fi

    # Create backup
    backup_configs
    local backup_dir="$HOME/zsh_backup_$(date +%Y%m%d_%H%M%S)"
    log "$GREEN" "Backup created at: $backup_dir"

    # Temporarily disable error handling for specific operations
    set +e

    # Clean up shell entries BEFORE removing zsh (if needed)
    if [[ "$uninstall_choice" == "1" || "$uninstall_choice" == "4" ]]; then
        cleanup_shell_entries
    fi

    # Remove components based on choice
    local uninstall_success=true
    if [[ "$uninstall_choice" == "1" ]]; then
        remove_oh_my_posh || uninstall_success=false
        remove_zsh_plugins || uninstall_success=false
        remove_powerlevel10k || uninstall_success=false
        remove_oh_my_zsh || uninstall_success=false
        remove_fuzzy_search || uninstall_success=false
        remove_zsh || uninstall_success=false
        cleanup_configs || uninstall_success=false
    elif [[ "$uninstall_choice" == "2" ]]; then
        remove_oh_my_posh || uninstall_success=false
    elif [[ "$uninstall_choice" == "3" ]]; then
        remove_zsh_plugins || uninstall_success=false
    elif [[ "$uninstall_choice" == "4" ]]; then
        remove_zsh || uninstall_success=false
        cleanup_configs || uninstall_success=false
    elif [[ "$uninstall_choice" == "5" ]]; then
        remove_specific_plugins || uninstall_success=false
    fi

    # Re-enable error handling
    set -e

    # Rollback option if any uninstall step failed
    if [[ "$uninstall_success" == "false" ]]; then
        log "$RED" "Some uninstall steps failed. Would you like to rollback and restore your backup?"
        read -p "Restore backup from $backup_dir? (y/n): " rollback_confirm
        if [[ "$rollback_confirm" =~ ^[Yy]$ ]]; then
            cp -r "$backup_dir/." "$HOME/"
            log "$GREEN" "Rollback complete. Backup restored from $backup_dir."
        else
            log "$YELLOW" "Rollback skipped. Manual restoration is possible from $backup_dir."
        fi
    else
        log "$GREEN" "✨ Uninstallation completed successfully!"
    fi

    log "$YELLOW" "Please log out and log back in for the default shell change to take effect."
    log "$YELLOW" "Restarting your terminal window will reflect other removals (commands, files)."
    log "$BLUE" "Your backup can be found in the directory: $backup_dir"
}

# Run main function
main
