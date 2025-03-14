#!/bin/bash
# Common utility functions for py-release scripts

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo "[INFO] $1"
}

error() {
    echo "[ERROR] $1" >&2
}

warn() {
    echo "[WARN] $1" >&2
}

# Get package name from pyproject.toml or environment variable
get_package_name() {
    if [ -n "$PACKAGE_NAME" ]; then
        echo "$PACKAGE_NAME"
        return 0
    fi

    if [ -f "pyproject.toml" ]; then
        # Try to get package name from pyproject.toml
        name=$(grep "^name = " pyproject.toml | head -n1 | cut -d'"' -f2)
        if [ -n "$name" ]; then
            echo "$name"
            return 0
        fi
    fi

    return 1
}

# Get package version from pyproject.toml or environment variable
get_package_version() {
    if [ -n "$VERSION" ]; then
        echo "$VERSION"
        return 0
    fi

    if [ -f "pyproject.toml" ]; then
        # Try to get version from pyproject.toml
        version=$(grep "^version = " pyproject.toml | head -n1 | cut -d'"' -f2)
        if [ -n "$version" ]; then
            echo "$version"
            return 0
        fi
    fi

    return 1
}

# Create a temporary directory and ensure it's cleaned up on exit
create_temp_dir() {
    local temp_dir
    temp_dir=$(mktemp -d)
    trap 'rm -rf "$temp_dir"' EXIT
    echo "$temp_dir"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if a Python package is installed
python_package_installed() {
    python3 -c "import $1" >/dev/null 2>&1
}

# Get Python version
get_python_version() {
    python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")'
}

# Get Python site-packages directory
get_python_site_packages() {
    local prefix=$1
    echo "$prefix/lib/python$(get_python_version)/site-packages"
}

# Version validation
validate_version() {
    local version=$1
    if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
        error "Invalid version format: $version"
        error "Version must match: X.Y.Z or X.Y.Z-suffix"
        return 1
    fi
}

# Package name validation
validate_package_name() {
    local name=$1
    if [[ ! $name =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
        error "Invalid package name: $name"
        error "Package name must start with a letter and contain only letters, numbers, underscores, and hyphens"
        return 1
    fi
}

# Check if running in GitHub Actions
is_github_actions() {
    [ -n "${GITHUB_ACTIONS:-}" ]
}

# Get the current version from pyproject.toml, setup.py, or VERSION file
get_current_version() {
    if [ -f "pyproject.toml" ]; then
        grep '^version = ' pyproject.toml | cut -d'"' -f2
    elif [ -f "setup.py" ]; then
        python3 -c "import re;print(re.search(r'version=['\"]([^'\"]+)['\"]', open('setup.py').read()).group(1))"
    elif [ -f "VERSION" ]; then
        cat VERSION
    else
        error "Could not determine current version"
        return 1
    fi
}

# Check if dependencies are installed
check_dependencies() {
    local missing=()
    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        error "Missing required dependencies: ${missing[*]}"
        return 1
    fi
}

# Check if a command succeeded and print appropriate message
check_status() {
    local status=$1
    local success_msg=${2:-"Operation completed successfully"}
    local error_msg=${3:-"Operation failed"}

    if [ $status -eq 0 ]; then
        log "$success_msg"
        return 0
    else
        error "$error_msg"
        return 1
    fi
}
