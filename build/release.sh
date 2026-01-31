#!/bin/bash
set -e

# release.sh - Automates the release process for zsh-setup
# Usage: ./build/release.sh [major|minor|patch]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
CHANGELOG_FILE="$ROOT_DIR/CHANGELOG.md"

cd "$ROOT_DIR"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Release Automation...${NC}"

# 1. Verification Checks
echo -e "\n${YELLOW}🔍 Performing checks...${NC}"

# Check branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo -e "${RED}❌ Error: You must be on the 'main' branch to release.${NC}"
    echo "   Current branch: $CURRENT_BRANCH"
    exit 1
fi

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${RED}❌ Error: Working directory is not clean.${NC}"
    echo "   Please commit or stash your changes before releasing."
    exit 1
fi

# Fetch and check sync
echo "   Fetching origin..."
git fetch origin
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u})
BASE=$(git merge-base @ @{u})

if [ "$LOCAL" != "$REMOTE" ] && [ "$LOCAL" == "$BASE" ]; then
    echo -e "${RED}❌ Error: Local branch is behind origin.${NC}"
    echo "   Please pull changes first."
    exit 1
fi
echo -e "${GREEN}✅ Checks passed.${NC}"

# 2. Determine Version
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
CURRENT_VERSION=${LATEST_TAG#v}

echo -e "\n${BLUE}📌 Current Version: $LATEST_TAG${NC}"

# Parse argument or prompt
BUMP_TYPE=$1
if [ -z "$BUMP_TYPE" ]; then
    echo "Select release type:"
    select type in "patch" "minor" "major"; do
        BUMP_TYPE=$type
        break
    done
fi

IFS='.' read -r major minor patch <<< "$CURRENT_VERSION"

if [ "$BUMP_TYPE" == "major" ]; then
    NEW_VERSION="$((major + 1)).0.0"
elif [ "$BUMP_TYPE" == "minor" ]; then
    NEW_VERSION="${major}.$((minor + 1)).0"
else
    NEW_VERSION="${major}.${minor}.$((patch + 1))"
fi

echo -e "${GREEN}✨ New Version: v$NEW_VERSION${NC}"
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# 3. Update CHANGELOG.md
echo -e "\n${YELLOW}📝 Updating CHANGELOG.md...${NC}"
DATE=$(date +%Y-%m-%d)

# Generate commit log since last tag
CHANGES=$(git log "$LATEST_TAG"..HEAD --pretty=format:"- %s" --no-merges)

if [ -z "$CHANGES" ]; then
    CHANGES="- Routine maintenance and updates"
fi

# Create temporary changelog content
TEMP_CHANGELOG=$(mktemp)
echo "## [v$NEW_VERSION] - $DATE" > "$TEMP_CHANGELOG"
echo "" >> "$TEMP_CHANGELOG"
echo "### Changes" >> "$TEMP_CHANGELOG"
echo "$CHANGES" >> "$TEMP_CHANGELOG"
echo "" >> "$TEMP_CHANGELOG"
echo "" >> "$TEMP_CHANGELOG"
cat "$CHANGELOG_FILE" >> "$TEMP_CHANGELOG"

mv "$TEMP_CHANGELOG" "$CHANGELOG_FILE"

echo -e "${GREEN}✅ CHANGELOG.md updated.${NC}"

# 4. Commit and Push
echo -e "\n${YELLOW}💾 Committing and Pushing...${NC}"
git add CHANGELOG.md
git commit -m "chore: release v$NEW_VERSION"

echo "   Pushing to origin (hooks handles tagging)..."
git push origin main

echo -e "${GREEN}✅ Pushed successfully.${NC}"

# 5. Build Distribution
echo -e "\n${YELLOW}📦 Building Distribution...${NC}"
./build/create-distribution.sh --create-release

echo -e "\n${GREEN}🎉 Release v$NEW_VERSION completed successfully!${NC}"
