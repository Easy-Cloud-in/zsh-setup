zsh-setup/IMPROVEMENT_PLAN.md
# zsh-setup Project Improvement & Error Fix Plan

_Last updated: June 2024_

---

## Table of Contents

1. [Overview](#overview)
2. [Step-by-Step Plan](#step-by-step-plan)
    - [Phase 1: Automation & User Experience](#phase-1-automation--user-experience)
    - [Phase 2: Error Handling & Safety](#phase-2-error-handling--safety)
    - [Phase 3: Config File Best Practices & Oh My Posh NVM Segment](#phase-3-config-file-best-practices--oh-my-posh-nvm-segment)
    - [Phase 4: Code Quality & Maintainability](#phase-4-code-quality--maintainability)
    - [Phase 5: Documentation & Support](#phase-5-documentation--support)
    - [Phase 6: Extensibility & Community](#phase-6-extensibility--community)
3. [Milestones & Progress Tracking](#milestones--progress-tracking)
4. [Notes & Best Practices](#notes--best-practices)

---

## Overview

This plan outlines actionable steps to improve the `zsh-setup` project, focusing on automation, error handling, user friendliness, code quality, documentation, and extensibility. Each phase is designed to be implemented incrementally, with clear goals and tasks.

---

## Step-by-Step Plan

### Phase 1: Automation & User Experience

**Goal:** Make the setup, theme switching, font installation, and uninstallation scripts fully automatable and more user-friendly.

- [ ] Add non-interactive flags to all scripts (e.g., `--yes`, `--no-prompt`) for CI/dotfiles automation.
- [ ] Allow skipping optional steps (e.g., font configuration, plugin installation) via flags.
- [ ] Validate all user inputs strictly (theme selection, confirmations).
- [ ] Add preview/dry-run mode to show planned changes without executing them.
- [ ] Improve colored output consistency and add clear success/error messages.
- [ ] Add support for restoring previous themes in `change_posh_theme.sh`.
- [ ] Make font installation script detect and skip already-installed fonts.

### Phase 2: Error Handling & Safety

**Goal:** Ensure robust error handling and protect user data/configurations.

- [ ] Add network, permission, and disk space checks before downloads/installations.
- [ ] Log all actions and errors to a file for troubleshooting.
- [ ] Confirm backup creation and location before destructive actions.
- [ ] Warn users before overwriting or removing custom configurations.
- [ ] Allow selective uninstallation (e.g., only plugins, only Oh My Posh).
- [ ] Handle edge cases in theme block removal (multiple blocks, malformed files).
- [ ] Add rollback option if installation fails partway.

### Phase 3: Config File Best Practices & Oh My Posh NVM Segment

**Goal:** Ensure `.zshrc`, `.bashrc`, and related config files are written, backed up, and maintained according to best practices. Configure Oh My Posh to use the NVM segment for Node version display, without installing NVM via script.

#### Config File Best Practices

- [ ] Always create timestamped backups before modifying `.zshrc`, `.bashrc`, or `.aliases`.
- [ ] Use clear markers for auto-generated sections so users can distinguish them from manual edits.
- [ ] Make config file changes idempotent (no duplicate entries on repeated runs).
- [ ] Preserve user customizations and only modify necessary sections.
- [ ] Add explanatory comments in config files for each section.
- [ ] Validate config file syntax after writing (e.g., source `.zshrc` and check for errors).
- [ ] Provide example `.zshrc` and `.aliases` files for reference.
- [ ] Migrate environment variables and aliases from `.bashrc` to `.zshrc` safely.

#### Oh My Posh NVM Segment

- [ ] Ensure the selected Oh My Posh theme includes the NVM segment/plugin.
- [ ] Document in README that users should install NVM themselves if they want Node version support in the prompt.
- [ ] Provide troubleshooting tips for NVM segment display (e.g., NVM must be installed and available in `$PATH`).
- [ ] Do **not** install or initialize NVM in `.zshrc` via script.

---

### Phase 4: Code Quality & Maintainability

**Goal:** Refactor scripts for readability, modularity, and future-proofing.

- [ ] Refactor duplicated logic (especially theme selection and plugin installation).
- [ ] Use arrays/maps for plugins and fonts for easier maintenance.
- [ ] Split large scripts into smaller, focused scripts if project grows.
- [ ] Add inline comments and function docstrings for clarity.
- [ ] Standardize variable naming and quoting for shell safety.
- [ ] Add unit tests or script self-checks where feasible.

### Phase 5: Documentation & Support

**Goal:** Enhance documentation for all user levels and provide troubleshooting resources.

- [ ] Add FAQ section to README.md for common questions.
- [ ] Add CHANGELOG.md to track updates and fixes.
- [ ] Add visual guides (screenshots/GIFs) for installation and theme switching.
- [ ] Document all script flags and options in README.md.
- [ ] Add troubleshooting section for common errors and recovery steps.
- [ ] Provide example `.zshrc` and `.aliases` files for reference.
- [ ] Document Oh My Posh NVM segment usage and troubleshooting in README (not NVM installation).

### Phase 6: Extensibility & Community

**Goal:** Make the project easier to contribute to and expand.

- [ ] Add guidelines for contributing (CONTRIBUTING.md).
- [ ] Modularize plugin/font/theme lists for easy addition/removal.
- [ ] Support more Linux distros (detect and warn if unsupported).
- [ ] Add support for more terminals (Alacritty, Kitty, etc.) in font instructions.
- [ ] Encourage community feedback via issues and pull requests.
- [ ] Regularly review and merge community contributions.

---

## Milestones & Progress Tracking

| Phase      | Task Description                          | Status      | Target Date |
|------------|------------------------------------------|-------------|-------------|
| Phase 1    | Add non-interactive flags                 | Not started | YYYY-MM-DD  |
| Phase 1    | Validate user inputs                      | Not started | YYYY-MM-DD  |
| Phase 2    | Add error logging to file                 | Not started | YYYY-MM-DD  |
| Phase 2    | Warn before overwriting configs           | Not started | YYYY-MM-DD  |
| Phase 3    | Implement config file best practices      | Not started | YYYY-MM-DD  |
| Phase 3    | Ensure Oh My Posh NVM segment is enabled  | Not started | YYYY-MM-DD  |
| Phase 5    | Document NVM segment usage in README      | Not started | YYYY-MM-DD  |
| Phase 4    | Refactor theme selection logic            | Not started | YYYY-MM-DD  |
| Phase 5    | Add FAQ and CHANGELOG.md                  | Not started | YYYY-MM-DD  |
| Phase 6    | Add CONTRIBUTING.md                       | Not started | YYYY-MM-DD  |
| ...        | ...                                      | ...         | ...         |

_Update this table as tasks are completed._

---

## Notes & Best Practices

- Always test scripts in a safe environment before releasing.
- Use shellcheck or similar tools to lint shell scripts.
- Document any breaking changes in CHANGELOG.md.
- Encourage users to back up their configs before running scripts.
- Use clear markers and comments in config files for user clarity.
- Make config file changes idempotent and preserve user customizations.
- Validate config file syntax after writing.
- Do **not** install or initialize NVM via script; document that NVM must be installed by the user for Node version display in Oh My Posh prompt.
- Ensure Oh My Posh theme includes the NVM segment.
- Review user feedback regularly and iterate on improvements.

---

**This plan is designed for incremental, collaborative improvement. Each phase can be tackled independently or in parallel, depending on team size and priorities.**

_Authored by: Expert Software Engineer_