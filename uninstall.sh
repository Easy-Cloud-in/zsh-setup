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
    
    # Remove Oh My Posh binary and configs
    sudo rm -f /usr/local/bin/oh-my-posh
    sudo rm -f /usr/bin/oh-my-posh
    rm -rf "$HOME/.oh-my-posh-themes"
    rm -rf "$HOME/.poshthemes"
    
    # Remove from all possible shell configs
    for file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" "$HOME/.bash_profile" "$HOME/.zshenv" "$HOME/.zprofile"; do
        if [ -f "$file" ]; then
            # Create a temporary file
            temp_file=$(mktemp)
            # Remove Oh My Posh related lines more comprehensively
            grep -v -E "(oh-my-posh|poshthemes)" "$file" > "$temp_file" || true
            mv "$temp_file" "$file"
        fi
    done
    
    # Remove any cached files
    rm -rf "$HOME/.cache/oh-my-posh"
    
    log "$GREEN" "Oh My Posh removed successfully"
}

# Function to remove Oh My Zsh
remove_oh_my_zsh() {
    log "$BLUE" "Removing Oh My Zsh..."
    
    if [ -d "$HOME/.oh-my-zsh" ]; then
        if [ -f "$HOME/.oh-my-zsh/tools/uninstall.sh" ]; then
            # Use ZSH_DISABLE_COMPFIX=true to avoid compfix errors during uninstallation
            ZSH_DISABLE_COMPFIX=true sh "$HOME/.oh-my-zsh/tools/uninstall.sh" --yes
        else
            rm -rf "$HOME/.oh-my-zsh"
        fi
        log "$GREEN" "Oh My Zsh removed successfully"
    else
        log "$YELLOW" "Oh My Zsh not found"
    fi
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

# Function to remove fuzzy search tools
remove_fuzzy_search() {
    log "$BLUE" "Removing fuzzy search tools..."
    
    # Remove fzf
    if [ -d "$HOME/.fzf" ]; then
        # Fix: Remove the --all flag which is causing the error
        if [ -f "$HOME/.fzf/uninstall" ]; then
            "$HOME/.fzf/uninstall"
        fi
        rm -rf "$HOME/.fzf"
        log "$GREEN" "fzf removed successfully"
    elif command_exists fzf; then
        sudo apt remove -y fzf
    fi

    # Remove ripgrep and fd-find if installed via apt
    if command_exists rg; then
        sudo apt remove -y ripgrep
    fi
    if command_exists fdfind; then
        sudo apt remove -y fd-find
    fi
    
    # Remove symlinks if they exist
    if [ -L "$HOME/.local/bin/fd" ]; then
        rm "$HOME/.local/bin/fd"
    fi
    if [ -L "$HOME/.local/bin/fzf" ]; then
        rm "$HOME/.local/bin/fzf"
    fi
    if [ -L "$HOME/.local/bin/rg" ]; then
        rm "$HOME/.local/bin/rg"
    fi
}

# Function to remove Powerlevel10k theme
remove_powerlevel10k() {
    log "$BLUE" "Removing Powerlevel10k theme..."
    
    if [ -d "$HOME/powerlevel10k" ]; then
        rm -rf "$HOME/powerlevel10k"
        log "$GREEN" "Powerlevel10k removed successfully"
    fi
    
    if [ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
        rm -rf "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
    fi
    
    rm -f "$HOME/.p10k.zsh"
}

# Function to remove Zsh
remove_zsh() {
    log "$BLUE" "Removing Zsh..."
    
    if command_exists zsh; then
        # Change default shell back to bash before removing zsh
        if [ "$SHELL" = "$(command -v zsh)" ]; then
            log "$BLUE" "Changing default shell back to bash..."
            chsh -s "$(command -v bash)"
        fi
        
        sudo apt remove -y zsh
        sudo apt autoremove -y
        log "$GREEN" "Zsh removed successfully"
    else
        log "$YELLOW" "Zsh not found"
    fi
}

# Function to clean up configuration files
cleanup_configs() {
    log "$BLUE" "Cleaning up configuration files..."
    
    # Remove Zsh related files
    rm -f "$HOME/.zshrc"*
    rm -f "$HOME/.zshenv"*
    rm -f "$HOME/.zprofile"*
    rm -f "$HOME/.zlogin"*
    rm -f "$HOME/.zlogout"*
    rm -rf "$HOME/.zsh"*
    rm -rf "$HOME/.zsh_sessions"
    rm -f "$HOME/.zcompdump"*
    rm -f "$HOME/.zsh_history"
    rm -rf "$HOME/.zcomp-"*
    
    # Remove all theme related files
    rm -rf "$HOME/.oh-my-posh"*
    rm -rf "$HOME/.poshthemes"*
    rm -rf "$HOME/.p10k.zsh"*
    
    # Remove plugin caches
    rm -rf "$HOME/.zsh_plugins"*
    rm -rf "$HOME/.zinit"*
    rm -rf "$HOME/.antigen"*
    
    # Keep only the latest backup
    find "$HOME" -name "zsh_backup_*" -type d | sort | head -n -1 | xargs rm -rf
    
    log "$GREEN" "Configuration cleanup completed"
}

# Function to clean up shell entries
cleanup_shell_entries() {
    log "$BLUE" "Cleaning up shell entries..."
    
    # First ensure bash is available
    BASH_PATH=$(command -v bash)
    if [ -z "$BASH_PATH" ]; then
        log "$RED" "Could not find bash executable!"
        exit 1
    fi

    # Try changing shell using chsh first
    if chsh -s "$BASH_PATH" "$USER"; then
        log "$GREEN" "Successfully changed shell using chsh"
    else
        log "$YELLOW" "chsh failed, attempting direct /etc/passwd modification..."
        
        # Create backup of /etc/passwd with timestamp
        PASSWD_BACKUP="/etc/passwd.backup.$(date +%Y%m%d_%H%M%S)"
        log "$BLUE" "Creating backup of /etc/passwd at $PASSWD_BACKUP"
        sudo cp /etc/passwd "$PASSWD_BACKUP"
        sudo chmod 644 "$PASSWD_BACKUP"
        
        # Create a temporary file
        TEMP_PASSWD=$(mktemp)
        
        # Modify user's shell in /etc/passwd
        sudo sed "s|^\($USER:.*:\)/bin/zsh$|\1$BASH_PATH|" /etc/passwd > "$TEMP_PASSWD"
        
        # Verify the changes look correct
        if grep "^$USER:" "$TEMP_PASSWD" | grep -q "$BASH_PATH"; then
            # Apply the changes
            sudo cp "$TEMP_PASSWD" /etc/passwd
            sudo chmod 644 /etc/passwd
            log "$GREEN" "Successfully updated shell in /etc/passwd"
            log "$BLUE" "Backup saved at $PASSWD_BACKUP"
        else
            log "$RED" "Failed to modify /etc/passwd. Please change your shell manually"
            log "$BLUE" "Original passwd file was not modified"
            rm -f "$TEMP_PASSWD"
            exit 1
        fi
        
        # Clean up
        rm -f "$TEMP_PASSWD"
    fi
    
    # Clean up and restore /etc/shells
    log "$BLUE" "Restoring shell entries..."
    echo "# /etc/shells: valid login shells" | sudo tee /etc/shells > /dev/null
    for shell in "/bin/sh" "/bin/bash" "/usr/bin/bash" "/bin/rbash" "/usr/bin/rbash" "/usr/bin/dash" "/bin/dash" "/bin/zsh" "/usr/bin/zsh"; do
        if [ -f "$shell" ]; then
            echo "$shell" | sudo tee -a /etc/shells > /dev/null
        fi
    done
    
    log "$GREEN" "Shell entries restored"
    
    # Add recovery instructions to the backup location
    echo "# To restore this backup, use: sudo cp $PASSWD_BACKUP /etc/passwd" > "${PASSWD_BACKUP}.README"
}

# Main function
main() {
    log "$YELLOW" "⚠️  Warning: This will remove Zsh, Oh My Posh, and all related configurations"
    log "$YELLOW" "    Your existing configurations will be backed up first"
    read -p "Do you want to continue? (y/n): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log "$BLUE" "Uninstallation cancelled"
        exit 0
    fi
    
    # Create backup
    backup_configs
    
    # Fix: Temporarily disable error handling for specific operations
    set +e
    
    # Clean up shell entries BEFORE removing zsh
    cleanup_shell_entries
    
    # Remove components
    remove_oh_my_posh
    remove_zsh_plugins
    remove_powerlevel10k
    remove_oh_my_zsh
    remove_fuzzy_search
    remove_zsh
    cleanup_configs
    
    # Re-enable error handling
    set -e
    
    log "$GREEN" "✨ Uninstallation completed successfully!"
    log "$YELLOW" "Please restart your terminal for changes to take effect"
    log "$BLUE" "Your backup can be found in the directory: $HOME/zsh_backup_*"
}

# Run main function
main