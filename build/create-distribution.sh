#!/bin/bash
set -e

# Parse command line arguments
IGNORE_CHANGELOG=false
SKIP_CHECKS=false
CREATE_RELEASE=false

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Create a distribution package from the latest version in CHANGELOG.md"
    echo ""
    echo "Options:"
    echo "  --ignore-changelog    Ignore uncommitted changes in CHANGELOG.md"
    echo "  --skip-checks        Skip all git checks (uncommitted changes, branch, sync)"
    echo "  --create-release     Automatically create GitHub release after packaging"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                           # Standard distribution creation"
    echo "  $0 --ignore-changelog        # Allow CHANGELOG.md changes"
    echo "  $0 --skip-checks            # Skip all git validation checks"
    echo "  $0 --create-release         # Create package and GitHub release"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --ignore-changelog)
            IGNORE_CHANGELOG=true
            shift
            ;;
        --skip-checks)
            SKIP_CHECKS=true
            shift
            ;;
        --create-release)
            CREATE_RELEASE=true
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

# Get the latest version from CHANGELOG.md
LATEST_VERSION=$(grep -m 1 '^## \[v[0-9]' CHANGELOG.md | sed -E 's/^## \[v([0-9]+\.[0-9]+\.[0-9]+).*/\1/')

if [ -z "$LATEST_VERSION" ]; then
    echo "Error: Could not determine latest version from CHANGELOG.md"
    exit 1
fi

echo "Creating distribution package for version v$LATEST_VERSION"

# Ensure we're in the root directory
cd "$(dirname "$0")/.."

# Skip all checks if requested
if [ "$SKIP_CHECKS" = true ]; then
    echo "⚠️  Warning: Skipping all git validation checks as requested"
else
    # Check for uncommitted changes
    if [ "$IGNORE_CHANGELOG" = true ]; then
        # Check for uncommitted changes (IGNORING CHANGELOG.md)
        HAS_CHANGES=$(git status --porcelain | grep -v "^[AM]  CHANGELOG.md$" | grep -v "^ M CHANGELOG.md$" || true)
        if [ -n "$HAS_CHANGES" ]; then
            echo "❌ Error: You have uncommitted changes in your working directory (excluding CHANGELOG.md)."
            echo "   Please commit or stash your changes before running this script."
            echo "   Run 'git status' to see the uncommitted changes."
            echo "   Uncommitted files (excluding CHANGELOG.md):"
            git status --porcelain | grep -v "CHANGELOG.md"
            exit 1
        fi

        # Show warning if CHANGELOG.md has changes but continue
        CHANGELOG_CHANGES=$(git status --porcelain | grep "CHANGELOG.md" || true)
        if [ -n "$CHANGELOG_CHANGES" ]; then
            echo "⚠️  Warning: CHANGELOG.md has uncommitted changes - ignoring as requested"
            echo "   Changes: $CHANGELOG_CHANGES"
        fi
    else
        # Standard check for any uncommitted changes
        HAS_CHANGES=$(git status --porcelain)
        if [ -n "$HAS_CHANGES" ]; then
            echo "❌ Error: You have uncommitted changes in your working directory."
            echo "   Please commit or stash your changes before running this script."
            echo "   Run 'git status' to see the uncommitted changes."
            exit 1
        fi
    fi
fi

# Continue with git checks if not skipping
if [ "$SKIP_CHECKS" = false ]; then
    # Check if we're on the main branch
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    if [ "$CURRENT_BRANCH" != "main" ]; then
        echo "❌ Error: This script must be run from the 'main' branch."
        echo "   Current branch: $CURRENT_BRANCH"
        echo "   Please switch to the main branch and try again."
        exit 1
    fi

    # Fetch the latest changes from origin
    echo "🔍 Checking for updates from remote..."
    git fetch origin

    # Check if local main is behind remote main
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u})
    if [ "$LOCAL" != "$REMOTE" ]; then
        echo "❌ Error: Your local main branch is not in sync with origin/main."
        echo "   Please pull the latest changes and try again."
        echo "   Run 'git pull origin main' to update your local branch."
        exit 1
    fi

    # Check for unpushed commits
    UNPUSHED_COMMITS=$(git log @{u}..@ --oneline)
    if [ -n "$UNPUSHED_COMMITS" ]; then
        if [ "$IGNORE_CHANGELOG" = true ]; then
            # Check if unpushed commits only modify CHANGELOG.md
            UNPUSHED_NON_CHANGELOG=$(git log @{u}..@ --name-only --pretty=format: | grep -v "^$" | grep -v "^CHANGELOG.md$" | head -1)
            if [ -n "$UNPUSHED_NON_CHANGELOG" ]; then
                echo "❌ Error: You have unpushed commits in your local main branch that affect files other than CHANGELOG.md."
                echo "   Please push your changes to origin/main and try again."
                echo "   Unpushed commits:"
                echo "   $UNPUSHED_COMMITS"
                exit 1
            else
                echo "⚠️  Warning: You have unpushed commits that only modify CHANGELOG.md - continuing..."
                echo "   Unpushed commits:"
                echo "   $UNPUSHED_COMMITS"
            fi
        else
            echo "❌ Error: You have unpushed commits in your local main branch."
            echo "   Please push your changes to origin/main and try again."
            echo "   Unpushed commits:"
            echo "   $UNPUSHED_COMMITS"
            exit 1
        fi
    fi

    if [ "$IGNORE_CHANGELOG" = true ]; then
        echo "✅ Local repository is up-to-date with origin/main (ignoring CHANGELOG.md)"
    else
        echo "✅ Local repository is up-to-date with origin/main"
    fi
fi

# Fetch all tags from remote
if ! git fetch --tags 2>/dev/null; then
    echo "Warning: Could not fetch tags from remote"
fi

# Check if the tag exists locally or in remote
if ! git rev-parse "v$LATEST_VERSION" >/dev/null 2>&1; then
    echo "Error: Tag v$LATEST_VERSION not found in the repository"
    echo "Available tags: $(git tag -l | tr '\n' ' ')"
    exit 1
fi

# Temporarily stash CHANGELOG.md changes if any and ignoring changelog
STASH_CREATED=false
# (Stashing will be done after packaging step if needed)

# Check if we're already on the right tag
CURRENT_TAG=$(git describe --tags --exact-match 2>/dev/null || echo "")
if [ "$CURRENT_TAG" != "v$LATEST_VERSION" ]; then
    # If not on the tag, check it out
    echo "Checking out tag v$LATEST_VERSION..."

    # First try to checkout the tag
    if ! git checkout "v$LATEST_VERSION" 2>/dev/null; then
        echo "Tag not found locally, trying to fetch from remote..."

        # Fetch just this specific tag
        if ! git fetch origin tag "v$LATEST_VERSION" --no-tags; then
            echo "Error: Could not fetch tag v$LATEST_VERSION from remote"
            echo "Available remote tags: $(git ls-remote --tags origin | cut -d'/' -f3 | sort -V | tr '\n' ' ')"

            # Restore stashed changes before exit
            if [ "$STASH_CREATED" = true ]; then
                echo "🔄 Restoring CHANGELOG.md changes..."
                git checkout main
                git stash pop
            fi
            exit 1
        fi

        # Now try to checkout the fetched tag
        if ! git checkout "v$LATEST_VERSION" 2>/dev/null; then
            echo "Error: Still could not checkout tag v$LATEST_VERSION"
            echo "Please make sure the tag exists in the remote repository"

            # Restore stashed changes before exit
            if [ "$STASH_CREATED" = true ]; then
                echo "🔄 Restoring CHANGELOG.md changes..."
                git checkout main
                git stash pop
            fi
            exit 1
        fi
    fi

    # Set up cleanup to return to previous branch and restore stash
    cleanup() {
        echo "Returning to branch main..."
        git checkout main
        if [ "$STASH_CREATED" = true ]; then
            echo "🔄 Restoring CHANGELOG.md changes..."
            git stash pop
        fi
    }
    trap cleanup EXIT
else
    # We're already on the right tag, but still need to restore stash on exit
    if [ "$STASH_CREATED" = true ]; then
        cleanup() {
            echo "🔄 Restoring CHANGELOG.md changes..."
            git stash pop
        }
        trap cleanup EXIT
    fi
fi

# Create the distribution package
chmod +x build/package.sh
./build/package.sh

# Get the created zip file
ZIP_FILE=$(ls -t dist/zsh-setup-*.zip | head -1)

if [ -z "$ZIP_FILE" ]; then
    echo "Error: Failed to create distribution package"
    exit 1
fi

echo "\n🎉 Distribution package created: $ZIP_FILE"

# Now stash CHANGELOG.md changes if needed (after packaging)
if [ "$IGNORE_CHANGELOG" = true ] && [ -n "${CHANGELOG_CHANGES:-}" ] && [ "$STASH_CREATED" = false ]; then
    echo "📦 Temporarily stashing CHANGELOG.md changes..."
    git stash push -m "Temporary stash for distribution creation - CHANGELOG.md" CHANGELOG.md
    STASH_CREATED=true
fi

# Create GitHub release if requested
if [ "$CREATE_RELEASE" = true ]; then
    echo "\n🚀 Creating GitHub release..."

    # Check if release already exists
    if gh release view "v$LATEST_VERSION" >/dev/null 2>&1; then
        echo "⚠️  Warning: Release v$LATEST_VERSION already exists"
        echo "   Uploading asset to existing release..."
        gh release upload "v$LATEST_VERSION" "$ZIP_FILE" --clobber
    else
        # Get release notes from the tag
        # Extract release notes for the current version from CHANGELOG.md
        RELEASE_NOTES=$(awk -v ver="v$LATEST_VERSION" '
            BEGIN {found=0}
            /^\#\# \[v[0-9]+\.[0-9]+\.[0-9]+\]/ {
                if (found) exit
                if ($0 ~ "\\[" ver "\\]") {found=1; print; next}
            }
            found {print}
        ' CHANGELOG.md | sed '/^$/q')
        # If no notes found, fallback to default
        if [ -z "$RELEASE_NOTES" ]; then
            RELEASE_NOTES="Release $LATEST_VERSION"
        fi

        # Create the release
        gh release create "v$LATEST_VERSION" \
            --title "v$LATEST_VERSION" \
            --notes "$RELEASE_NOTES" \
            "$ZIP_FILE"
    fi

    if [ $? -eq 0 ]; then
        echo "✅ GitHub release created successfully!"
        echo "🔗 View release: https://github.com/$(gh repo view --json owner,name -q '.owner.login + "/" + .name')/releases/tag/v$LATEST_VERSION"
    else
        echo "❌ Failed to create GitHub release"
        echo "   You can create it manually with:"
        echo "   gh release create v$LATEST_VERSION --title \"v$LATEST_VERSION\" --notes-file <(git log -1 --pretty=%B v$LATEST_VERSION) $ZIP_FILE"
    fi
else
    echo "\nTo create a GitHub release, run:"
    echo "gh release create v$LATEST_VERSION \\"
    echo "  --title \"v$LATEST_VERSION\" \\"
    echo "  --notes-file <(git log -1 --pretty=%B v$LATEST_VERSION) \\"
    echo "  $ZIP_FILE"
    echo "\nOr use the --create-release flag next time to do this automatically."
fi

echo "\n📋 Summary:"
echo "✅ Distribution package created successfully"
if [ "$CREATE_RELEASE" = true ]; then
    echo "🚀 GitHub release creation attempted"
fi
if [ "$STASH_CREATED" = true ]; then
    echo "ℹ️  CHANGELOG.md changes were temporarily stashed and will be restored"
fi
if [ "$SKIP_CHECKS" = true ]; then
    echo "⚠️  Git validation checks were skipped"
elif [ "$IGNORE_CHANGELOG" = true ]; then
    echo "ℹ️  CHANGELOG.md changes were ignored during validation"
fi
echo "🏷️  Version: v$LATEST_VERSION"
echo "📦 Package: $ZIP_FILE"
