# ~/.zshrc Example - Best Practices for zsh-setup
# ------------------------------------------------
# This file demonstrates recommended config structure, safety, and extensibility.
# All auto-generated sections are clearly marked. Manual edits should be outside these blocks.

# ------------------------------------------------
# User Customizations (Manual Section)
# ------------------------------------------------
# Add your personal aliases, exports, and customizations below.
# These will NOT be overwritten by zsh-setup scripts.

# Example:
alias ll='ls -alF'
export EDITOR='vim'

# ------------------------------------------------
# BEGIN: Oh My Posh Theme Block (Auto-Generated)
# ------------------------------------------------
# This section is managed by zsh-setup scripts.
# It applies your selected Oh My Posh theme.
# Idempotent: Only one block will be present, even after repeated runs.

eval "$(oh-my-posh init zsh --config '$HOME/.oh-my-posh-themes/your-theme.omp.json')"

# NVM Segment Usage:
# If your theme includes the NVM segment, Node version will display in your prompt.
# NOTE: You must install NVM yourself and ensure it's loaded before this block.
# Example NVM initialization (uncomment if you use NVM):
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# ------------------------------------------------
# END: Oh My Posh Theme Block (Auto-Generated)
# ------------------------------------------------

# ------------------------------------------------
# BEGIN: Zsh Plugins Block (Auto-Generated)
# ------------------------------------------------
# This section is managed by zsh-setup scripts.
# It installs and enables recommended plugins.
# Idempotent: Only one block will be present, even after repeated runs.

# Enable autosuggestions
if [ -f "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Enable syntax highlighting
if [ -f "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# Enable completions
if [ -f "$HOME/.oh-my-zsh/custom/plugins/zsh-completions/zsh-completions.plugin.zsh" ]; then
  source "$HOME/.oh-my-zsh/custom/plugins/zsh-completions/zsh-completions.plugin.zsh"
fi

# Enable fzf-tab (fuzzy completion)
if [ -f "$HOME/.oh-my-zsh/custom/plugins/fzf-tab/fzf-tab.plugin.zsh" ]; then
  source "$HOME/.oh-my-zsh/custom/plugins/fzf-tab/fzf-tab.plugin.zsh"
fi

# ------------------------------------------------
# END: Zsh Plugins Block (Auto-Generated)
# ------------------------------------------------

# ------------------------------------------------
# BEGIN: Fuzzy Search Functions (Manual/Optional)
# ------------------------------------------------
# These functions are safe to add manually and will not be overwritten.

# Search file contents
fif() { rg --color=always --line-number "$*" || echo "No matches found"; }

# Find files
fd() { fdfind "$@" || echo "No matches found"; }

# ------------------------------------------------
# END: Fuzzy Search Functions
# ------------------------------------------------

# ------------------------------------------------
# BEGIN: Safety & Idempotency Checks
# ------------------------------------------------
# Validate config syntax after changes (recommended)
if command -v zsh > /dev/null; then
  zsh -n "$HOME/.zshrc" || echo "Warning: Syntax errors detected in .zshrc"
fi

# ------------------------------------------------
# END: Safety & Idempotency Checks
# ------------------------------------------------

# ------------------------------------------------
# Additional Notes
# ------------------------------------------------
# - All auto-generated blocks are wrapped in clear markers for easy identification.
# - You can safely update your .zshrc using zsh-setup scripts; manual edits outside blocks are preserved.
# - For troubleshooting, see ~/.zsh-setup.log and restore from backups if needed.
# - For NVM segment support, ensure NVM is installed and initialized before the Oh My Posh block.
# - For more info, see README.md and CONTRIBUTING.md in the project root.
