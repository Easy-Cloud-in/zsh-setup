zsh-setup/CONTRIBUTING.md
# Contributing to zsh-setup

Thank you for your interest in contributing to the **zsh-setup** project! We welcome improvements, bug fixes, new features, and documentation enhancements from the community.

---

## How to Contribute

1. **Fork the Repository**
   - Click "Fork" at the top right of the GitHub page.
   - Clone your fork locally:
     ```
     git clone https://github.com/<your-username>/zsh-setup.git
     cd zsh-setup
     ```

2. **Create a Feature Branch**
   - Use a descriptive branch name:
     ```
     git checkout -b feature/my-improvement
     ```

3. **Make Your Changes**
   - Follow the code style and best practices outlined below.
   - Add comments and documentation where appropriate.
   - Test your changes in a safe environment.

4. **Commit and Push**
   - Write clear, concise commit messages:
     ```
     git commit -m "Add feature: improved theme selection logic"
     git push origin feature/my-improvement
     ```

5. **Open a Pull Request**
   - Go to your fork on GitHub and click "Compare & pull request".
   - Describe your changes and reference any related issues.

6. **Respond to Feedback**
   - Be ready to discuss and revise your code based on feedback from maintainers and other contributors.

---

## Code Style & Best Practices

- **Shell Scripts**
  - Use `#!/bin/bash` as the shebang.
  - Enable strict error handling: `set -euo pipefail`.
  - Use consistent indentation (2 or 4 spaces).
  - Prefer long-form flags for clarity (e.g., `--force`, `--dry-run`).
  - Use arrays/maps for lists (plugins, fonts).
  - Always validate user input.
  - Add colored output for errors, warnings, and success messages.
  - Add explanatory comments and function docstrings.
  - Make config changes idempotent (avoid duplicates).
  - Preserve user customizations in config files.
  - Use clear markers for auto-generated config sections.

- **Documentation**
  - Update `README.md` and `CHANGELOG.md` as needed.
  - Add usage examples, troubleshooting tips, and FAQ entries.
  - Document new flags, options, or features.

- **Testing**
  - Test scripts in a safe environment (e.g., VM, Docker).
  - Use `shellcheck` or similar tools to lint scripts.
  - Validate config file syntax after changes.

---

## Community Guidelines

- Be respectful and constructive in discussions.
- Report issues with clear steps to reproduce, error messages, and environment details.
- Suggest improvements or new features via issues or pull requests.
- Help review and test contributions from others.

---

## Support & Feedback

- For help, open an issue on GitHub.
- For feature requests, use the "Issues" tab and label your request.
- For security concerns, please contact the maintainers directly.

---

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for helping make zsh-setup better for everyone!**