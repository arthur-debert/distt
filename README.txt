PY-RELEASE

A drop-in solution for managing Python package releases across multiple platforms:
- ✅ Package Publishing (for package authors):
  - ✅ GitHub releases
  - ✅ PyPI releases
- ✅ Package Distribution (for package managers):
  - ✅ APT packages
  - ✅ Homebrew formulas

Supports both local execution and GitHub Actions workflows.

1. INSTALLATION

   ```bash
   brew install distt
   ```

2. CONCEPTS

2.1 Publishing vs Distribution
    The toolset is split into two main functions:
    
    Publishing (distt-publish):
    - For package authors
    - Publishes your Python package to:
      - PyPI: Build and publish Python packages
      - GitHub: Create releases with assets and notes
    
    Distribution (distt):
    - For package managers and distributors
    - Takes an existing PyPI package and creates:
      - APT packages: Generate and maintain debian packages
      - Homebrew formulas: Generate and maintain Homebrew formulas

2.2 Release Steps
    Each operation follows these steps in sequence:
    
    build  → Generate required artifacts
            - PyPI: Build distribution files
            - GitHub: Prepare release notes and assets
            - APT: Generate debian package
            - Brew: Generate formula file
    
    check  → Test locally before publishing
            - PyPI: Install from local dist
            - GitHub: Validate release assets
            - APT: Install local package
            - Brew: Install local formula
    
    publish→ Make changes available
            - PyPI: Upload to PyPI
            - GitHub: Create release
            - APT: Commit package to repo
            - Brew: Commit formula to repo
    
    verify → Test as end user
            - PyPI: Install from PyPI
            - GitHub: Check release via API
            - APT: Install via apt
            - Brew: Install via brew

3. USAGE

3.1 Publishing (for package authors)
    Use distt-publish to release your Python package:
    
    ```bash
    # Run from your Python package directory (where pyproject.toml is)
    distt-publish

    # Options:
    --target=<target>     Specify target (pypi,github)
    --local              Run locally instead of GitHub Actions
    --build             Run until build step
    --check             Run until check step
    --publish           Run until publish step
    --verify            Run all steps (default)
    --force             Force update even if no changes
    --version=<ver>     Override version
    ```

    Examples:
    ```bash
    distt-publish --target=pypi --publish
    distt-publish --local
    ```

3.2 Distribution (for package managers)
    Use distt to create distribution packages:
    
    ```bash
    distt

    # Options:
    --target=<target>     Specify target (apt,brew)
    --local              Run locally instead of GitHub Actions
    --package-name=<n>   Package name on PyPI to distribute
    --build             Run until build step
    --check             Run until check step
    --publish           Run until publish step
    --verify            Run all steps (default)
    --force             Force update even if no changes
    ```

    Examples:
    ```bash
    distt --target=brew --package-name=requests
    distt --target=apt --package-name=flask
    ```

4. DEPENDENCIES

Required dependencies will be installed automatically via brew. For manual installation:
- Python 3.7+
- Poetry
- GitHub CLI (gh)
- Jinja2 (for templating)
- Twine (for PyPI uploads)
- For APT builds: dpkg-deb, devscripts, debhelper

