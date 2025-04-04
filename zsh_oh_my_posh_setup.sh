#!/bin/bash

# Exit on error, undefined vars, and pipe failures
set -euo pipefail

# Error handler
trap 'echo "Error on line $LINENO. Previous command exited with status $?"' ERR

# Add debug output if needed
# set -x

# Add a new force update flag
FORCE_UPDATE=false

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

# Add argument parsing
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--force)
                FORCE_UPDATE=true
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

# Check for required commands
check_requirements() {
    local requirements=(curl wget git unzip)
    for cmd in "${requirements[@]}"; do
        if ! command -v "$cmd" > /dev/null; then
            log "$RED" "Error: $cmd is not installed. Installing..."
            sudo apt update && sudo apt install -y "$cmd"
        fi
    done
}

# Add new function to install fzf and related utilities
install_search_utilities() {
    # Install fzf
    if ! command -v fzf > /dev/null; then
        if [ -d ~/.fzf ]; then
            log "$BLUE" "Found existing fzf directory. Updating..."
            cd ~/.fzf
            git pull
            ./install --all
            cd - > /dev/null
        else
            log "$BLUE" "Installing fzf..."
            git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
            ~/.fzf/install --all
        fi
    else
        log "$GREEN" "fzf is already installed."
    fi

    # Install ripgrep for better searching
    if ! command -v rg > /dev/null; then
        log "$BLUE" "Installing ripgrep..."
        sudo apt install -y ripgrep
    else
        log "$GREEN" "ripgrep is already installed."
    fi

    # Install fd-find for better file finding
    if ! command -v fdfind > /dev/null; then
        log "$BLUE" "Installing fd-find..."
        sudo apt install -y fd-find
        # Create symlink to make it available as 'fd'
        if [ ! -f ~/.local/bin/fd ]; then
            mkdir -p ~/.local/bin
            ln -s $(which fdfind) ~/.local/bin/fd
        fi
    else
        log "$GREEN" "fd-find is already installed."
    fi
}

# Backup existing .zshrc if it exists
backup_zshrc() {
    if [ -f ~/.zshrc ]; then
        local backup_file=~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)
        log "$BLUE" "Creating backup of existing .zshrc to $backup_file"
        cp ~/.zshrc "$backup_file"
    fi
}

# Install Zsh and set as default shell
install_zsh() {
    if ! command -v zsh > /dev/null || [ "$FORCE_UPDATE" = true ]; then
        log "$BLUE" "Installing/Updating Zsh..."
        sudo apt update -y
        sudo apt install -y zsh
    else
        log "$GREEN" "Zsh is already installed."
    fi

    # Clean up and normalize /etc/shells
    log "$BLUE" "Cleaning up duplicate shell entries..."
    
    # Create a temporary file
    TEMP_SHELLS=$(mktemp)
    
    # Add header
    echo "# /etc/shells: valid login shells" > "$TEMP_SHELLS"
    
    # Add unique shell entries
    {
        echo "/bin/sh"
        echo "/bin/bash"
        echo "/usr/bin/bash"
        echo "/bin/rbash"
        echo "/usr/bin/rbash"
        echo "/bin/dash"
        echo "/usr/bin/dash"
        echo "/bin/zsh"
        echo "/usr/bin/zsh"
    } | while read shell; do
        if [ -f "$shell" ]; then
            echo "$shell" >> "$TEMP_SHELLS"
        fi
    done | sort -u

    # Replace /etc/shells safely
    if [ -w /etc/shells ]; then
        sudo mv "$TEMP_SHELLS" /etc/shells
        sudo chmod 644 /etc/shells
        log "$GREEN" "Updated /etc/shells successfully"
    else
        sudo bash -c "cat $TEMP_SHELLS > /etc/shells"
        rm -f "$TEMP_SHELLS"
        log "$GREEN" "Updated /etc/shells successfully"
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
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set theme (change this if needed)
ZSH_THEME=""

# Load plugins correctly using Oh My Zsh's plugin system
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    fzf-tab
    zsh-completions
)

# Initialize Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Ensure compinit runs correctly and clean up any corruption
autoload -U compinit
rm -f ~/.zcompdump*
compinit -u

# Plugin configurations (after Oh My Zsh initialization)
# Autosuggestions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#8a8a8a"

# Syntax highlighting
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)

# FZF Tab Completion
zstyle ':fzf-tab:*' fzf-command fzf
zstyle ':fzf-tab:*' fzf-flags '--height=40%'
zstyle ':fzf-tab:*' fzf-bindings 'tab:accept'
zstyle ':fzf-tab:*' switch-group ',' '.'

# Ensure PATH is set correctly (with typeset -U to prevent duplicates)
typeset -U PATH path
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"

# Load fzf if installed (with all configurations)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
if command -v fzf &> /dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    # Add preview support if bat is available
    if command -v bat &> /dev/null; then
        export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always {}'"
    fi
fi

# Source custom aliases if they exist
[[ -f ~/.aliases ]] && source ~/.aliases

# Final message
echo "Zsh setup loaded successfully!"
EOL

    # Add Oh My Posh theme configuration with existence check
    cat >> ~/.zshrc << EOL

# Initialize Oh My Posh if installed
if command -v oh-my-posh &> /dev/null; then
    eval "\$(oh-my-posh init zsh --config $themes_dir/$selected_theme)" # Oh My Posh Theme
else
    echo "Oh My Posh not found. Install it for better prompts."
fi
EOL

    # Set proper permissions
    chmod 600 ~/.zshrc

    log "$GREEN" "Zsh configuration completed successfully!"
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

# Configure .zshrc
configure_zshrc() {
    local themes_dir=$1
    local selected_theme=$2

    # First backup the existing .zshrc
    backup_zshrc

    # If .zshrc doesn't exist, create it
    if [ ! -f ~/.zshrc ]; then
        cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
    fi

    # Add key bindings for history search
    cat <<'EOL' >> ~/.zshrc
# Key bindings
bindkey '^[[A' up-line-or-history    # Up arrow
bindkey '^[[B' down-line-or-history  # Down arrow
bindkey '^[[1;5C' forward-word       # Ctrl + Right arrow
bindkey '^[[1;5D' backward-word      # Ctrl + Left arrow
bindkey '^[[H' beginning-of-line     # Home
bindkey '^[[F' end-of-line          # End
bindkey '^[[3~' delete-char         # Delete
bindkey '^H' backward-delete-char   # Backspace
bindkey '^?' backward-delete-char   # Backspace alternative
bindkey '^[[Z' reverse-menu-complete # Shift + Tab

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS  # Don't record duplicates in history
setopt HIST_SAVE_NO_DUPS     # Don't save duplicates
setopt HIST_REDUCE_BLANKS    # Remove blank lines
setopt HIST_VERIFY           # Show command before executing from history
setopt SHARE_HISTORY         # Share history between sessions
setopt EXTENDED_HISTORY      # Add timestamps to history
setopt INC_APPEND_HISTORY    # Add commands to history as they are typed
setopt HIST_FIND_NO_DUPS     # Don't show duplicates when searching

# Enable history search
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search    # Up arrow
bindkey '^[[B' down-line-or-beginning-search  # Down arrow
EOL

    # Update plugins with correct order
    log "$BLUE" "Configuring plugins in .zshrc..."
    # Note: zsh-syntax-highlighting must be last
    sed -i 's/^plugins=(.*)$/plugins=(git zsh-completions zsh-autosuggestions fzf-tab zsh-syntax-highlighting)/' ~/.zshrc

    # Add completion configuration
    if ! grep -q "# Completion Configuration" ~/.zshrc; then
        cat <<'EOL' >> ~/.zshrc

# Completion Configuration
autoload -U compinit; compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' verbose yes
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}[%d]%f'
zstyle ':completion:*:messages' format '%F{purple}%d%f'
zstyle ':completion:*:warnings' format '%F{red}No matches found%f'
zstyle ':completion:*:corrections' format '%F{yellow}%d (errors: %e)%f'

# Load completions from zsh-completions plugin
fpath=($ZSH_CUSTOM/plugins/zsh-completions/src $fpath)

# Force reload completions
rm -f ~/.zcompdump*; compinit

# Enable menu-style completion
zstyle ':completion:*' menu yes select

# Configure fzf-tab
zstyle ':fzf-tab:*' fzf-command fzf
zstyle ':fzf-tab:*' fzf-flags '--height=40%'
zstyle ':fzf-tab:*' fzf-bindings 'tab:accept'
zstyle ':fzf-tab:*' switch-group ',' '.'
EOL
    fi

    # Update Oh My Posh configuration
    sed -i '/eval.*oh-my-posh.*config.*/d' ~/.zshrc
    echo "eval \"\$(oh-my-posh init zsh --config $themes_dir/$selected_theme)\" # Oh My Posh Theme" >> ~/.zshrc

    # Remove explicit plugin sourcing as it can conflict with Oh My Zsh's plugin system
    sed -i '/# Source plugins explicitly/,/zsh-syntax-highlighting.plugin.zsh/d' ~/.zshrc
    
    # Add proper plugin initialization
    if ! grep -q "# Plugin initialization" ~/.zshrc; then
        cat <<'EOL' >> ~/.zshrc

# Plugin initialization
# Enable autosuggestions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#8a8a8a"

# Enable syntax highlighting options
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)
EOL
    fi
}

# Add fzf configuration to configure_zshrc function
# Add additional plugins for better integration
install_additional_plugins() {
    local plugin_name
    local plugin_dir
    
    # Install fzf-tab plugin
    plugin_name="fzf-tab"
    plugin_dir="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/$plugin_name"
    
    if [ ! -d "$plugin_dir" ]; then
        log "$BLUE" "Installing plugin: $plugin_name..."
        git clone "https://github.com/Aloxaf/fzf-tab" "$plugin_dir"
    fi
}

configure_search_utilities() {
    if ! grep -q "FZF Configuration" ~/.zshrc; then
        cat <<'EOL' >> ~/.zshrc

# FZF Configuration
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --preview '([[ -f {} ]] && (bat --style=numbers --color=always {} || cat {})) || ([[ -d {} ]] && (tree -C {} | less)) || echo {} 2> /dev/null | head -200'"

# FZF Key Bindings
bindkey '^P' fzf-file-widget
bindkey '^R' fzf-history-widget
bindkey '^F' fzf-cd-widget

# Additional FZF Functions
fif() {
    if [ ! "$#" -gt 0 ]; then echo "Need a string to search for!"; return 1; fi
    rg --files-with-matches --no-messages "$1" | fzf --preview "highlight -O ansi -l {} 2> /dev/null | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$1' || rg --ignore-case --pretty --context 10 '$1' {}"
}

# Use fd (find alternative) if available
if command -v fd > /dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Use bat for preview if available
if command -v bat > /dev/null; then
    export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always {}'"
    alias cat='bat --paging=never'
fi
EOL
    fi

    # Install additional plugins
    install_additional_plugins

    # Update plugins line to include fzf-tab
    sed -i '/^plugins=/c\plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions fzf-tab)' ~/.zshrc
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
        log "$YELLOW" "Force update mode enabled - will reinstall/reconfigure all components"
    fi

    check_requirements
    backup_zshrc
    install_zsh
    install_oh_my_zsh
    install_oh_my_posh
    install_search_utilities
    install_plugins
    setup_themes
    
    # Always run these functions regardless of installation status
    migrate_bash_environment
    
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
                log "$GREEN" "Setup completed successfully!"
                log "$YELLOW" "Restart your terminal or run 'zsh' to apply the changes."
                break
            fi
        else
            log "$RED" "❌ Invalid selection. Please try again."
        fi
    done
}

main "$@"
