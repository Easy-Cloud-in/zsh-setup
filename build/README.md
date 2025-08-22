# Build & Distribution

**📚 Navigation:** [🏠 Main README](../README.md) | [📖 User Manual](../USER_MANUAL.md)

---

This directory contains all build-related scripts and tools for the **zsh-setup** project.

## Scripts

### Main Build & Release Scripts

- `create-distribution.sh` – Creates a distribution package, performs git validation, and optionally creates a GitHub release.
- `package.sh` – Builds the local zip package for distribution.

### Usage Examples

```bash
# Create distribution package
./build/create-distribution.sh

# Create package and GitHub release
./build/create-distribution.sh --create-release

# Build local zip package only
./build/package.sh
```

## create-distribution.sh Flags & Usage

The `create-distribution.sh` script supports the following flags:

- `--ignore-changelog`      Ignore uncommitted changes in CHANGELOG.md
- `--skip-checks`           Skip all git validation checks (uncommitted changes, branch, sync)
- `--create-release`        Automatically create a GitHub release after packaging
- `-h`, `--help`            Show help message

## Directory Structure

```
build/
├── README.md              # This file
├── create-distribution.sh # Distribution builder & release script
├── package.sh             # Local zip package builder
├── templates/             # Distribution templates
│   ├── README.md          # Distribution README template
│   ├── files.list         # Files to include in package
│   ├── install.sh         # Installer script for distribution
│   └── uninstall.sh       # Uninstaller script for distribution

../dist/                   # Output directory (clean - only zip files)
└── zsh-setup-v*.zip
```

## Workflow

### Development

```bash
# Build and test
./build/package.sh
```

### Release

```bash
# Complete release workflow
./build/create-distribution.sh --create-release
```

This creates:

- Git tag (e.g., `v1.0.0`)
- Distribution package (`dist/zsh-setup-v1.0.0.zip`)
- Pushes tag to origin and creates GitHub release (if requested)

## Version Management

Version is automatically determined from:

1. **CHANGELOG.md** (primary) - Format: `## [vX.Y.Z] - YYYY-MM-DD`
2. **Git tags** (fallback) - Format: `vX.Y.Z`
3. **Default** (first push) - Uses `1.0.0`

## Build Process

1. **Copy Files**: Based on `build/templates/files.list` specification
2. **Set Permissions**: Make scripts executable, configs readable
3. **Create Package**: Zip from staging area to `dist/`
4. **Cleanup**: Remove staging area (keeps build clean)

### Customizing Distribution

Edit `build/templates/files.list` to control what goes in the package:

```
# Format: source_path:destination_path
zsh_oh_my_posh_setup.sh:zsh_oh_my_posh_setup.sh
install_fonts.sh:install_fonts.sh
change_posh_theme.sh:change_posh_theme.sh
example.zshrc:example.zshrc
uninstall.sh:uninstall.sh
LICENSE:LICENSE
README.md:README.md
USER_MANUAL.md:USER_MANUAL.md
CHANGELOG.md:CHANGELOG.md
build/templates/install.sh:install.sh
build/templates/uninstall.sh:uninstall.sh
build/templates/README.md:README.md
```

Edit `build/templates/README.md` to customize the distribution README.

## Git State Requirements

Git validation is performed by `create-distribution.sh`:

- ✅ Must be on `main` branch
- ✅ Working tree must be clean (**CHANGELOG.md changes are allowed**)
- ✅ Must be synced with `origin/main`

## Requirements

- Git repository with proper setup
- `zip` command available
- Bash shell environment
- Clean working tree on main branch (CHANGELOG.md changes allowed)

## Troubleshooting

- **Git errors:** Ensure you are on the `main` branch and your working tree is clean.
- **Missing zip:** Make sure the `zip` command is installed.
- **Permission issues:** Scripts set executable permissions automatically, but you may need to run `chmod +x *.sh` in some environments.

---