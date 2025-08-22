zsh-setup/build/package.sh
#!/bin/bash
set -e

# Show help information
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Create a local distribution package (zip file only)"
    echo ""
    echo "Options:"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                   # Create local zip package"
    echo ""
    echo "Note: This script only creates the zip file locally in dist/"
    echo "      For GitHub releases, use: ./build/create-distribution.sh --create-release"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
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
    shift
done

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to project root directory
cd "$SCRIPT_DIR/.."

echo "🔍 Performing pre-package checks..."

# Check if we're on the main branch
current_branch=$(git branch --show-current)
if [ "$current_branch" != "main" ]; then
    echo "❌ Error: Not on main branch. Current branch: $current_branch"
    echo "   Please switch to main branch before packaging."
    exit 1
fi

# Fetch latest changes from origin
echo "📡 Fetching latest changes from origin..."
git fetch origin

# Check if local main is behind origin/main (being ahead is OK)
local_commit=$(git rev-parse main)
remote_commit=$(git rev-parse origin/main)
base_commit=$(git merge-base main origin/main)

# Only fail if local is behind remote (missing commits from remote)
if [ "$local_commit" = "$base_commit" ] && [ "$local_commit" != "$remote_commit" ]; then
    echo "❌ Error: Local main branch is behind origin/main"
    echo "   Local:  $local_commit"
    echo "   Remote: $remote_commit"
    echo "   Please pull latest changes: git pull origin main"
    exit 1
elif [ "$local_commit" != "$remote_commit" ]; then
    # Local is ahead of remote - this is fine for development
    echo "ℹ️  Note: Local main is ahead of origin/main (this is OK for development)"
    echo "   Local:  $local_commit"
    echo "   Remote: $remote_commit"
fi

# Check working tree status
git_status=$(git status --porcelain)

# Filter out CHANGELOG.md from status check
filtered_status=$(echo "$git_status" | grep -v "CHANGELOG.md" || true)

if [ -n "$filtered_status" ]; then
    echo "❌ Error: Working tree is not clean (excluding CHANGELOG.md)"
    echo "   Uncommitted changes:"
    echo "$filtered_status"
    echo "   Please commit or stash your changes before packaging."
    exit 1
fi

# Check if only CHANGELOG.md has changes (this is allowed)
changelog_changes=$(echo "$git_status" | grep "CHANGELOG.md" || true)
if [ -n "$changelog_changes" ]; then
    echo "ℹ️  Note: CHANGELOG.md has uncommitted changes (this is allowed)"
    echo "   Changes: $changelog_changes"
fi

echo "✅ All pre-package checks passed!"
echo "   - On main branch: $current_branch"
echo "   - Up to date with origin/main"
echo "   - Working tree clean (CHANGELOG.md changes allowed)"
echo ""

# Create dist directory if it doesn't exist
mkdir -p "$SCRIPT_DIR/../dist"

# Create a temporary directory for the distribution
temp_dir=$(mktemp -d)
dist_dir="$temp_dir/zsh-setup"

# Create directory structure
mkdir -p "$dist_dir"

# Get version for filename
VERSION=$(grep -m 1 '^## \[v[0-9]' CHANGELOG.md | sed -E 's/^## \[v([0-9]+\.[0-9]+\.[0-9]+).*/\1/' || echo "1.0.0")

# Copy files based on templates/files.list
while IFS=':' read -r source_path dest_path || [[ -n "$source_path" ]]; do
    # Skip comments and empty lines
    [[ "$source_path" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$source_path" ]] && continue

    # Handle default destination path
    if [[ -z "$dest_path" ]]; then
        dest_path="$(basename "$source_path")"
    fi

    full_source="$source_path"
    full_dest="$dist_dir/$dest_path"

    # Create destination directory if needed
    mkdir -p "$(dirname "$full_dest")"

    # Copy file
    if [[ -f "$full_source" ]]; then
        cp "$full_source" "$full_dest"
        echo "  ✓ $source_path → $dest_path"
    else
        echo "❌ Error: Source file not found: $full_source"
        exit 1
    fi
done < "$SCRIPT_DIR/templates/files.list"

# Set proper permissions
find "$dist_dir" -name "*.sh" -exec chmod +x {} \;
find "$dist_dir" -name "*.conf" -exec chmod 644 {} \;

# Create zip file
cd "$temp_dir"
zip -r "$SCRIPT_DIR/../dist/zsh-setup-v$VERSION.zip" zsh-setup

# Clean up
cd - >/dev/null
rm -rf "$temp_dir"

echo "Distribution package created: dist/zsh-setup-v$VERSION.zip"
