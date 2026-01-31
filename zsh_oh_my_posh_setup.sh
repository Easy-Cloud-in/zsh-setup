#!/bin/bash

LOG_FILE=~/.zsh-setup.log
mkdir -p "$(dirname "$LOG_FILE")" || true
touch "$LOG_FILE" || true
chmod 600 "$LOG_FILE" || true

# Disk space and network checks (minimum 100MB, github.com reachable)
check_disk_and_network() {
    local avail_space
    avail_space=$(df "$HOME" | awk 'NR==2 {print $4}')
    if [ "$avail_space" -lt 102400 ]; then
        echo "Insufficient disk space. At least 100MB required in $HOME." | tee -a "$LOG_FILE"
        exit 1
    fi
    if ! ping -c 1 github.com &>/dev/null; then
        echo "Network check failed. Cannot reach github.com. Please check your internet connection." | tee -a "$LOG_FILE"
        exit 1
    fi
}

# Exit on error, undefined vars, and pipe failures
set -euo pipefail

# Error handler
trap '{
    echo "Error on line $LINENO. Previous command exited with status $?" >&2
    echo "Error on line $LINENO. Previous command exited with status $?" >> "$LOG_FILE"
    # Rollback prompt on error
    if [ -f ~/.zshrc.backup.* ]; then
        echo "An error occurred. Would you like to rollback and restore your previous .zshrc backup? (y/n): "
        read -r rollback_confirm
        if [[ "$rollback_confirm" =~ ^[Yy]$ ]]; then
            latest_backup=$(ls -t ~/.zshrc.backup.* | head -n 1)
            cp "$latest_backup" ~/.zshrc
            echo "Rollback complete. Restored from $latest_backup" | tee -a "$LOG_FILE"
        else
            echo "Rollback skipped. Manual restoration is possible from ~/.zshrc.backup.*" | tee -a "$LOG_FILE"
        fi
    fi
}' ERR

# Add debug output if needed
# set -x

# Add a new force update flag
FORCE_UPDATE=false
# Add a flag to only update .zshrc
UPDATE_RC=false

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
    echo "$(date '+%Y-%m-%d %H:%M:%S') $message" >> "$LOG_FILE"
}

# Add argument parsing
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--force)
                FORCE_UPDATE=true
                shift
                ;;
            --update-rc)
                UPDATE_RC=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --no-prompt)
                NO_PROMPT=true
                shift
                ;;
            --self-check|--test)
                SELF_CHECK=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Show help message
show_help() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -f, --force       Force reinstallation/reconfiguration of all components."
    echo "  --update-rc       Only update the ~/.zshrc configuration file based on the selected theme."
    echo "  --dry-run         Preview changes without applying them."
    echo "  --no-prompt       Run non-interactively (for automation)."
    echo "  --self-check      Run environment and config self-checks."
    echo "  -h, --help        Show this help message."
    echo
    echo "This script installs and configures Zsh, Oh My Zsh, Oh My Posh, and recommended plugins."
}

# Check for required commands
check_requirements() {
    local requirements=(curl wget git unzip)
    for cmd in "${requirements[@]}"; do
        if ! command -v "$cmd" > /dev/null; then
            log "$RED" "Error: $cmd is not installed. Installing..."
            sudo apt update && sudo apt install -y "$cmd"
        fi
    done
    # Disk and network checks before proceeding
    check_disk_and_network
}

# Add new function to install fzf and related utilities
# Install modern CLI tools
install_modern_tools() {
    log "$BLUE" "Checking for modern CLI tools..."
    
    local install_all="n"
    if [ "$NO_PROMPT" != true ]; then
        log "$YELLOW" "Modern Tools Suite: zoxide (smart cd), eza (modern ls), bat (modern cat), delta (git diff), tldr (docs), atuin (magic history)"
        read -p "Install all recommended modern tools? (y/N): " install_all
    else
        install_all="y"
    fi

    should_install() {
        local tool=$1
        [[ "$install_all" =~ ^[Yy]$ ]] && return 0
        local ans
        if [ "$NO_PROMPT" != true ]; then
            read -p "  Install $tool? (y/N): " ans
            [[ "$ans" =~ ^[Yy]$ ]]
        else
            return 1 # Default no if not all and no prompt
        fi
    }

    # Common requirement for many tools
    sudo apt update -y

    # zoxide
    if command -v zoxide > /dev/null; then
        log "$GREEN" "zoxide is already installed."
    elif should_install "zoxide"; then
        log "$BLUE" "Installing zoxide..."
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    fi

    # eza
    if command -v eza > /dev/null; then
        log "$GREEN" "eza is already installed."
    elif should_install "eza"; then
        log "$BLUE" "Installing eza..."
        sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
        sudo apt update
        sudo apt install -y eza
    fi

    # bat
    if command -v batcat > /dev/null || command -v bat > /dev/null; then
        log "$GREEN" "bat is already installed."
    elif should_install "bat"; then
        log "$BLUE" "Installing bat..."
        sudo apt install -y bat
        mkdir -p ~/.local/bin
        ln -sf /usr/bin/batcat ~/.local/bin/bat
    fi

    # git-delta
    if command -v delta > /dev/null; then
        log "$GREEN" "delta is already installed."
    elif should_install "delta"; then
        log "$BLUE" "Installing git-delta..."
        # Delta is not always in apt for older versions, try binary or apt
        if apt-cache search git-delta | grep -q git-delta; then
             sudo apt install -y git-delta
        else
             # Failover to cargo if available or script? Let's use a common release deb if needed, 
             # but to keep it safe let's assume apt or cargo.
             if command -v cargo > /dev/null; then
                 cargo install git-delta
             else
                 log "$YELLOW" "Skipping delta: not in apt and cargo not found."
             fi
        fi
    fi

    # tldr
    if command -v tldr > /dev/null; then
        log "$GREEN" "tldr is already installed."
    elif should_install "tldr"; then
        log "$BLUE" "Installing tldr..."
        sudo apt install -y tldr || sudo apt install -y tealdeer
        tldr --update 2>/dev/null || true
    fi

    # atuin
    if command -v atuin > /dev/null; then
        log "$GREEN" "atuin is already installed."
    elif should_install "atuin"; then
        log "$BLUE" "Installing atuin..."
        curl --proto '=https' --tlsv1.2 -lsSf https://setup.atuin.sh | sh
    fi
    
    # fzf, ripgrep, fd (Original utils)
    if should_install "fzf (fuzzy finder)"; then
         if ! command -v fzf > /dev/null; then
            git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
            ~/.fzf/install --all
         fi
    fi

    if should_install "ripgrep"; then
         sudo apt install -y ripgrep
    fi

    if should_install "fd-find"; then
         sudo apt install -y fd-find
         mkdir -p ~/.local/bin
         ln -sf $(which fdfind) ~/.local/bin/fd
    fi

    export PATH="$HOME/.local/bin:$PATH"
}

# Robust backup function
backup_zshrc() {
    local backup_dir="$HOME/.zsh-backups"
    mkdir -p "$backup_dir"

    if [ -f ~/.zshrc ]; then
        local timestamp=$(date +%Y%m%d_%H%M%S)
        local backup_file="$backup_dir/.zshrc.backup.$timestamp"
        
        log "$BLUE" "Creating backup of existing .zshrc to $backup_file"
        cp ~/.zshrc "$backup_file"
        
        # Rotate backups: keep only the last 5
        local backups=($(ls -t "$backup_dir"/.zshrc.backup.* 2>/dev/null))
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

# Install Zsh and set as default shell
install_zsh() {
    if ! command -v zsh > /dev/null || [ "$FORCE_UPDATE" = true ]; then
        log "$BLUE" "Installing/Updating Zsh..."
    if [ "$DRY_RUN" != true ]; then
        sudo apt update -y
        sudo apt install -y zsh
    else
        log "$YELLOW" "Dry run: Skipping apt install of Zsh."
    fi
    else
        log "$GREEN" "Zsh is already installed."
    fi

    # Ensure Zsh is in /etc/shells
    local zsh_path="$(command -v zsh)"
    if [ -n "$zsh_path" ]; then
        if ! grep -q "^${zsh_path}$" /etc/shells; then
            log "$BLUE" "Adding Zsh to valid login shells..."
            echo "${zsh_path}" | sudo tee -a /etc/shells > /dev/null
            log "$GREEN" "Added $zsh_path to /etc/shells"
        else
            log "$GREEN" "Zsh is already in /etc/shells"
        fi
    else
        log "$RED" "Error: Zsh binary not found after installation!"
        return 1
    fi

    # Ensure Zsh is in the list of valid login shells
    zsh_path="$(command -v zsh)"
    if [ -n "$zsh_path" ] && ! grep -q "^${zsh_path}$" /etc/shells; then
        log "$BLUE" "Adding Zsh to valid login shells..."
        echo "${zsh_path}" | sudo tee -a /etc/shells > /dev/null
    fi

    # Set Zsh as default shell if it's not already
    if [ "$SHELL" != "$zsh_path" ]; then
        log "$BLUE" "Setting Zsh as default shell..."
        chsh -s "$zsh_path" "$USER"

        log "$YELLOW" "⚠️  Zsh has been set as your default shell."
        log "$YELLOW" "Please log out and log back in for the change to take effect."
        log "$YELLOW" "Alternatively, you can run 'zsh' now to switch to Zsh for the current session."
    else
        log "$GREEN" "Zsh is already the default shell."
    fi

    log "$GREEN" "Zsh setup completed."
}

# Install Oh My Zsh
install_oh_my_zsh() {
    if [ ! -d "$HOME/.oh-my-zsh" ] || [ "$FORCE_UPDATE" = true ]; then
        if [ -d "$HOME/.oh-my-zsh" ]; then
            log "$BLUE" "Removing existing Oh My Zsh installation..."
            rm -rf "$HOME/.oh-my-zsh"
        fi

        # Create a minimal .zshrc first to prevent the new user setup
        log "$BLUE" "Creating initial .zshrc..."
        echo "# Initial .zshrc to prevent new user setup" > "$HOME/.zshrc"

        log "$BLUE" "Installing Oh My Zsh..."
        # Use RUNZSH=no to prevent automatic shell switch
        export RUNZSH=no
        # Use --unattended and --keep-zshrc flags
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc

        if [ $? -ne 0 ]; then
            log "$RED" "Oh My Zsh installation failed!"
            exit 1
        fi
    else
        log "$GREEN" "Oh My Zsh is already installed."
    fi
}

# Install Oh My Posh
install_oh_my_posh() {
    if ! command -v oh-my-posh > /dev/null || [ "$FORCE_UPDATE" = true ]; then
        log "$BLUE" "Installing/Updating Oh My Posh..."
        sudo wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh
        sudo chmod +x /usr/local/bin/oh-my-posh
    else
        log "$GREEN" "Oh My Posh is already installed."
    fi
}

# Modified setup_themes function
setup_themes() {
    local THEMES_DIR="$HOME/.oh-my-posh-themes"

    log "$BLUE" "Setting up themes in directory: $THEMES_DIR"

    # Create themes directory if it doesn't exist
    if [ ! -d "$THEMES_DIR" ]; then
        mkdir -p "$THEMES_DIR"
    fi

    # Force redownload themes (suppress output with -q flag)
    log "$BLUE" "Downloading Oh My Posh themes..."
    rm -rf "$THEMES_DIR"/*
    wget -q https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip -O "$THEMES_DIR/themes.zip"
    unzip -q -o "$THEMES_DIR/themes.zip" -d "$THEMES_DIR"
    rm "$THEMES_DIR/themes.zip"

    # Verify themes were downloaded
    local theme_count=$(find "$THEMES_DIR" -name "*.json" -type f | wc -l)
    log "$GREEN" "✨ Downloaded $theme_count themes successfully!\n"
}

# Function to install plugins
install_plugins() {
    local plugins_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    local install_status=0

    mkdir -p "$plugins_dir"

    # Helper function to install or update a plugin
    install_or_update_plugin() {
        local plugin_name=$1
        local plugin_url=$2
        local plugin_dir="$plugins_dir/$plugin_name"

        if [ ! -d "$plugin_dir" ]; then
            log "$BLUE" "Installing $plugin_name..."
            if git clone --quiet "$plugin_url" "$plugin_dir" 2>/dev/null; then
                log "$GREEN" "✓ Successfully installed $plugin_name"
            else
                log "$RED" "✗ Failed to install $plugin_name"
                install_status=1
            fi
        else
            log "$BLUE" "Updating $plugin_name..."
            if (cd "$plugin_dir" && git pull --quiet 2>/dev/null); then
                log "$GREEN" "✓ Successfully updated $plugin_name"
            else
                log "$RED" "✗ Failed to update $plugin_name"
                install_status=1
            fi
        fi
    }

    # Install plugins in the correct order
    install_or_update_plugin "zsh-completions" "https://github.com/zsh-users/zsh-completions"
    install_or_update_plugin "fzf-tab" "https://github.com/Aloxaf/fzf-tab"
    install_or_update_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
    install_or_update_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting"
    install_or_update_plugin "zsh-history-substring-search" "https://github.com/zsh-users/zsh-history-substring-search"

    return $install_status
}

# Function to configure .zshrc
configure_zshrc() {
    local themes_dir=$1
    local selected_theme=$2

    # Backup existing .zshrc if it exists
    backup_zshrc

    # Create new .zshrc with the correct configuration
    cat > ~/.zshrc << 'EOL'
# ==============================================================================
# Zsh Configuration - Generated by zsh_oh_my_posh_setup.sh
# ==============================================================================

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set theme (handled by Oh My Posh below)
ZSH_THEME=""

# --- Performance Tuning ---
# Tip: Too many plugins loaded synchronously can slow down Zsh startup.
# Consider using a plugin manager with async support (Zinit, Zplug, Antigen, Antidote)
# or manually deferring plugin loading if startup feels slow.
# The plugins listed here are generally useful and reasonably fast.
# --------------------------
    git
    zsh-completions
    zsh-autosuggestions
    fzf-tab
    zsh-history-substring-search
    zsh-syntax-highlighting # Note: zsh-syntax-highlighting must be the last plugin loaded

# Initialize Oh My Zsh (loads plugins etc.)
source $ZSH/oh-my-zsh.sh

# --- Completion System ---
# Tip: Ensure compinit runs efficiently. OMZ generally handles this well.
# The .zcompdump file caches completions. Remove it if completions seem broken.
# -------------------------
autoload -U compinit
compinit -u # Use -u to update if needed, -C might be used by OMZ internally

# --- Plugin Configurations (after Oh My Zsh initialization) ---
# Autosuggestions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#8a8a8a"

# Syntax highlighting
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)
ZSH_HIGHLIGHT_STYLES[cursor]='bg=red'

# FZF Tab Completion
# Tip: fzf-tab enhances completion with fzf. Ensure fzf is installed.
# --------------------------------------------------------------------
zstyle ':fzf-tab:*' fzf-command fzf # Use default fzf
zstyle ':fzf-tab:*' fzf-flags '--height=40%' # Adjust popup height
zstyle ':fzf-tab:*' fzf-bindings 'tab:accept' # Use Tab to accept completion
zstyle ':fzf-tab:*' switch-group ',' '.' # Keys to switch completion groups

# --- PATH Configuration ---
# Ensure PATH is set correctly and prevent duplicates.
# Add user-specific bin directories first.
# -------------------------------------------------
typeset -U PATH path # Makes PATH array unique
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH" # Rust/Cargo
export PATH="$HOME/go/bin:$PATH"     # Go
export PATH="./node_modules/.bin:$PATH" # Node project local bins

# --- FZF Configuration ---
# Tip: These commands run when FZF is invoked (Ctrl+T, Alt+C, etc.)
# Using 'fd' and 'bat' can enhance FZF but ensure they are installed.
# Complex preview commands can slightly slow down FZF operations.
# -----------------------------------------------------------------
if command -v fzf &> /dev/null; then
    # Use fd if available, otherwise default FZF finder
    if command -v fd &> /dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    else
        # Default FZF command if fd is not found
        export FZF_DEFAULT_COMMAND='find . -type f -not -path "*/.git/*"'
        export FZF_ALT_C_COMMAND='find . -type d -not -path "*/.git/*"'
    fi
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

    # Preview settings: Use bat if available, otherwise use head/cat/tree
    local preview_cmd="head -n 100 {}" # Default preview
    if command -v bat &> /dev/null; then
        preview_cmd="bat --style=numbers --color=always --line-range :500 {}"
    elif command -v tree &> /dev/null; then
         preview_cmd="if [[ -d {} ]]; then tree -C {} | head -n 100; else head -n 100 {}; fi"
    fi
    export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --preview '$preview_cmd'"
    export FZF_CTRL_T_OPTS="--preview '$preview_cmd'"

    # Source the FZF keybindings and completions
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
fi

# --- NVM (Node Version Manager) ---
# Load NVM script if it exists. This might slightly increase shell startup time
# compared to lazy loading, but ensures Node is available immediately.
# --------------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # Load nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # Load nvm bash_completion (works in Zsh too)
# The nvm script should handle adding the correct Node version to the PATH

# --- Other Environment Settings ---
# Add custom aliases, environment variables, etc. here or source them.
# --------------------------------------------------------------------

# PNPM setup (adjust if needed, ensure PNPM_HOME is correct)
export PNPM_HOME="$HOME/.local/share/pnpm"
if [ -d "$PNPM_HOME" ] && [[ ":$PATH:" != *":$PNPM_HOME:"* ]]; then
    export PATH="$PNPM_HOME:$PATH"
fi

# Yarn setup (adjust if needed)
if [ -d "$HOME/.yarn/bin" ] && [[ ":$PATH:" != *"$HOME/.yarn/bin:"* ]]; then
    export PATH="$HOME/.yarn/bin:$PATH"
fi
if [ -d "$HOME/.config/yarn/global/node_modules/.bin" ] && [[ ":$PATH:" != *"$HOME/.config/yarn/global/node_modules/.bin:"* ]]; then
    export PATH="$HOME/.config/yarn/global/node_modules/.bin:$PATH"
fi

# Source custom aliases if they exist
[[ -f ~/.aliases ]] && source ~/.aliases

# Custom environment variables from bash (if any were migrated)
# BEGIN BASH MIGRATION
# (Content added by migrate_bash_environment function if needed)
# END BASH MIGRATION

EOL

    # --- Modern Tools Configuration ---
    cat >> ~/.zshrc << 'EOZC'
    
# --- Modern Tools Aliases & Config ---
if command -v zoxide > /dev/null; then
    eval "$(zoxide init zsh)"
    alias cd="z"
fi

if command -v eza > /dev/null; then
    alias ls="eza --icons"
    alias ll="eza -l --icons --git"
    alias la="eza -la --icons --git"
    alias lt="eza --tree --icons"
fi

if command -v bat > /dev/null; then
    alias cat="bat"
fi

if command -v atuin > /dev/null; then
    eval "$(atuin init zsh)"
fi

# History Substring Search Keybindings
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
# Also bind for non-standard terminals or modes if needed
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down
EOZC


    # --- Oh My Posh Initialization ---
    # Tip: This sets your prompt. Complex themes can *slightly* impact startup.
    # The selected theme is applied here.
    # -----------------------------------------------------------------------
    cat >> ~/.zshrc << EOL

# Initialize Oh My Posh if installed
if command -v oh-my-posh &> /dev/null; then
    eval "\$(oh-my-posh init zsh --config $themes_dir/$selected_theme)"
else
    # Fallback prompt if Oh My Posh isn't found
    PROMPT='%{%F{blue}%}%~%{%f%} %# '
    echo "Oh My Posh not found. Using basic prompt. Install Oh My Posh for a better experience."
fi

# Final confirmation message for Zsh load
# echo "Zsh setup loaded successfully!" # Optional: uncomment for load confirmation
EOL

    # Set proper permissions
    chmod 600 ~/.zshrc

    log "$GREEN" "Zsh configuration written to ~/.zshrc successfully!"
    log "$YELLOW" "Performance tips and lazy-loading for NVM have been added."
}

# Add this new function after install_plugins() function
migrate_bash_environment() {
    log "$BLUE" "Migrating bash environment to zsh..."

    # Create a temporary file to store environment variables
    local temp_env_file="/tmp/zsh_env_migration"

    # Clear the temp file if it exists
    > "$temp_env_file"

    # Extract environment setup from bash files with more comprehensive patterns
    for file in ~/.bashrc ~/.bash_profile ~/.profile; do
        if [ -f "$file" ]; then
            log "$BLUE" "Processing $file..."
            # Extract only exports and path modifications, skip bash-specific commands
            grep -E '^[[:space:]]*(export|PATH=|alias)' "$file" >> "$temp_env_file"
        fi
    done

    # Remove existing environment section if it exists
    sed -i '/# BEGIN BASH MIGRATION/,/# END BASH MIGRATION/d' ~/.zshrc

    # Add the new environment section
    cat <<'EOL' >> ~/.zshrc

# BEGIN BASH MIGRATION
# Zsh-specific settings
setopt NO_CASE_GLOB        # Case insensitive globbing
setopt AUTO_CD            # Auto change directory without cd
setopt EXTENDED_GLOB      # Extended globbing
setopt NOTIFY            # Report status of background jobs immediately
setopt APPEND_HISTORY    # Append history instead of overwriting

# Initialize completion system
autoload -Uz compinit && compinit

# Common development tools setup
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/bin:$PATH"
export PATH="./node_modules/.bin:$PATH"

# Ensure PATH entries are unique
typeset -U PATH path

# NVM setup
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    source "$NVM_DIR/nvm.sh"
fi

# PNPM setup
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Yarn setup
if [ -d "$HOME/.yarn" ]; then
    export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
fi

# Cargo (Rust) setup
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Go setup
if [ -d "/usr/local/go" ]; then
    export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"
fi

# Load custom aliases if they exist
[[ -f ~/.aliases ]] && source ~/.aliases

# Custom environment variables from bash (filtered)
EOL

    # Append filtered environment variables from bash
    if [ -s "$temp_env_file" ]; then
        log "$BLUE" "Adding compatible environment variables..."
        sort -u "$temp_env_file" | while read -r line; do
            # Skip lines that are already handled above or contain bash-specific commands
            if ! grep -q "^$line" ~/.zshrc && ! echo "$line" | grep -qE 'shopt|complete|bash'; then
                echo "$line" >> ~/.zshrc
            fi
        done
    fi

    # Create a new aliases file if it doesn't exist
    if [ ! -f ~/.aliases ]; then
        touch ~/.aliases
        # Extract aliases from .bashrc and add them to .aliases
        grep -E '^[[:space:]]*alias' ~/.bashrc 2>/dev/null >> ~/.aliases
    fi

    echo "# END BASH MIGRATION" >> ~/.zshrc

    # Clean up
    rm -f "$temp_env_file"

    # Fix permissions
    chmod 600 ~/.zshrc
    chmod 600 ~/.aliases

    log "$GREEN" "Environment migration completed!"
}

# Function to preview a theme
preview_theme() {
    local theme_path=$1
    local theme_name=$(basename "$theme_path")

    log "$BLUE" "\nPreviewing theme: $theme_name"
    log "$YELLOW" "Preview will last for 5 seconds..."

    # Create a temporary script
    local temp_script=$(mktemp)
    cat << EOF > "$temp_script"
#!/usr/bin/env zsh
# Apply the theme directly
eval "\$(oh-my-posh init zsh --config '$theme_path')"

# Clear screen and show theme
clear
echo "🎨 Theme Preview: $theme_name"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Show prompt in different contexts
echo "\n📁 Regular directory:"
cd \$HOME
pwd

echo "\n📦 Git repository:"
cd "\$(git rev-parse --show-toplevel 2>/dev/null || echo \$HOME)"
git status 2>/dev/null

echo "\n💻 Command examples:"
echo "$ docker ps"
echo "$ npm install"
echo "$ sudo systemctl status nginx"

echo "\n⚡ Root context example:"
echo "# apt update && apt upgrade"

echo "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Press Enter to return to theme selection..."
read
EOF

    # Make the script executable
    chmod +x "$temp_script"

    # Run the preview in interactive mode
    zsh -i "$temp_script"

    # Clean up
    rm "$temp_script"
    clear

    return 0
}

# Modified theme selection function with debug information
select_theme() {
    local THEMES_DIR="$HOME/.oh-my-posh-themes"
    local themes=($(find "$THEMES_DIR" -name "*.json" -type f | sort))
    local columns=3  # Number of columns to display
    local width=30   # Width of each column

    # Clear screen for better presentation
    clear

    log "$BLUE" "\n📚 Oh My Posh Theme Selection"
    log "$YELLOW" "══════════════════════════════════════════════════════════════"

    # Calculate total themes and rows
    local total=${#themes[@]}
    local rows=$(( (total + columns - 1) / columns ))

    # Display themes in columns with padding
    for ((i = 0; i < rows; i++)); do
        for ((j = 0; j < columns; j++)); do
            local index=$((j * rows + i))
            if [ $index -lt $total ]; then
                local theme_name=$(basename "${themes[$index]}" .omp.json)
                # Format: [001] theme_name
                printf "${GREEN}[%03d]${NC} %-${width}s" $((index + 1)) "$theme_name"
            fi
        done
        echo  # New line after each row
    done

    log "$YELLOW" "══════════════════════════════════════════════════════════════"
    log "$BLUE" "\n🎨 Options:"
    echo "  • Enter a number (1-$total) to select a theme"
    echo "  • Enter 'p' + number to preview (e.g., 'p1')"
    echo "  • Enter 'q' to quit"
    echo
    read -p "💫 Your choice: " choice

    # Rest of the selection logic remains the same
    if [[ "$choice" == "q" ]]; then
        log "$RED" "Theme selection cancelled."
        exit 1
    fi

    if [[ "$choice" =~ ^p[0-9]+$ ]]; then
        number=${choice:1}
        if ((number >= 1 && number <= total)); then
            preview_theme "${themes[number-1]}"
            return
        else
            log "$RED" "❌ Invalid theme number. Please try again."
        fi
        return
    fi

    if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= total)); then
        selected_theme="${themes[choice-1]}"
        theme_name=$(basename "$selected_theme" .omp.json)
        log "$YELLOW" "\n✨ You selected: $theme_name"
        read -p "📝 Do you want to apply this theme? (y/n): " confirm

        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            echo "$selected_theme"
            return
        fi
    else
        log "$RED" "❌ Invalid selection. Please try again."
    fi
}

main() {
    # Parse command line arguments
    parse_arguments "$@"

    if [ "$FORCE_UPDATE" = true ]; then
        log "$YELLOW" "⚡ Force update mode enabled - will reinstall/reconfigure all components"
    elif [ "$UPDATE_RC" = true ]; then
        log "$YELLOW" "⚙️ Update .zshrc mode enabled - only configuration will be updated"
    fi

    # Always backup existing .zshrc before potentially modifying it
    backup_zshrc

    # If only updating rc, skip installations/checks
    if [ "$UPDATE_RC" = true ] && [ "$FORCE_UPDATE" = false ]; then
        log "$BLUE" "Skipping installation checks and plugin updates for --update-rc mode."
        # Ensure themes are available for selection, even in update-only mode
        setup_themes
        # Ensure migration logic runs if needed
        migrate_bash_environment
    else
        # Full run (or force run): check requirements, install/update everything
        check_requirements
        install_zsh
        install_oh_my_zsh
        install_oh_my_posh
        install_modern_tools
        # Install/Update plugins
        if install_plugins; then
             log "$GREEN" "All plugins installed/updated successfully."
        else
             log "$YELLOW" "⚠️ Some plugins failed to install or update. Check logs above."
        fi
        setup_themes
        migrate_bash_environment
    fi

    # --- Theme Selection and .zshrc Configuration (Common to all modes) ---
    # Clear screen before showing themes
    clear

    # Show themes and get selection
    while true; do
        local THEMES_DIR="$HOME/.oh-my-posh-themes"
        local themes=($(find "$THEMES_DIR" -name "*.json" -type f | sort))
        local columns=3
        local width=30

        log "$BLUE" "\n📚 Oh My Posh Theme Selection"
        log "$YELLOW" "══════════════════════════════════════════════════════════════"

        # Calculate total themes and rows
        local total=${#themes[@]}
        local rows=$(( (total + columns - 1) / columns ))

        # Display themes in columns with padding
        for ((i = 0; i < rows; i++)); do
            for ((j = 0; j < columns; j++)); do
                local index=$((j * rows + i))
                if [ $index -lt $total ]; then
                    local theme_name=$(basename "${themes[$index]}" .omp.json)
                    printf "${GREEN}[%03d]${NC} %-${width}s" $((index + 1)) "$theme_name"
                fi
            done
            echo
        done

        log "$YELLOW" "══════════════════════════════════════════════════════════════"
        log "$BLUE" "\n🎨 Options:"
        echo "  • Enter a number (1-$total) to select a theme"
        echo "  • Enter 'p' + number to preview (e.g., 'p1')"
        echo "  • Enter 'q' to quit"
        echo
        read -p "💫 Your choice: " choice

        # Handle selection
        if [[ "$choice" == "q" ]]; then
            log "$RED" "Theme selection cancelled."
            exit 1
        fi

        if [[ "$choice" =~ ^p[0-9]+$ ]]; then
            number=${choice:1}
            if ((number >= 1 && number <= total)); then
                preview_theme "${themes[number-1]}"
                continue
            else
                log "$RED" "❌ Invalid theme number for preview. Please try again."
            fi
            continue
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= total)); then
            selected_theme="${themes[choice-1]}"
            theme_name=$(basename "$selected_theme" .omp.json)
            log "$YELLOW" "\n✨ You selected: $theme_name"
            read -p "📝 Do you want to apply this theme? (y/n): " confirm

            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                configure_zshrc "$THEMES_DIR" "$(basename "$selected_theme")"
                log "$GREEN" "✅ Setup completed successfully!"
                log "$YELLOW" "Please restart your terminal or run 'exec zsh' to apply the changes."
                break
            fi
        else
            log "$RED" "❌ Invalid selection. Please try again."
        fi
    done
}

main "$@"
