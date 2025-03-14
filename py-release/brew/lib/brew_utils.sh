#!/bin/bash
# Utility functions for Homebrew operations

# Check if a formula exists in Homebrew
brew_formula_exists() {
    local package_name=$1
    local version=$2

    # Try to find the formula
    if brew info "$package_name" &>/dev/null; then
        if [ -n "$version" ]; then
            # Check if version exists
            if brew info "$package_name" | grep -q "^$package_name: $version"; then
                return 0
            fi
            return 1
        fi
        return 0
    fi
    return 1
}

# Get latest version from Homebrew
get_brew_latest_version() {
    local package_name=$1

    # Get latest version from Homebrew
    local version
    version=$(brew info "$package_name" | grep -m1 "^$package_name: " | cut -d' ' -f2)

    if [ -n "$version" ]; then
        echo "$version"
        return 0
    fi
    return 1
}

# Create a temporary Homebrew environment
create_temp_brew_env() {
    local temp_dir=$1

    # Create necessary directories
    mkdir -p "$temp_dir"/{Cellar,bin,etc,include,lib,opt,var}

    # Set Homebrew environment variables
    export HOMEBREW_PREFIX="$temp_dir"
    export HOMEBREW_CELLAR="$temp_dir/Cellar"
    export HOMEBREW_REPOSITORY="$temp_dir"
    export PATH="$temp_dir/bin:$PATH"
}

# Clean up temporary Homebrew environment
cleanup_temp_brew_env() {
    local temp_dir=$1

    # Unset Homebrew environment variables
    unset HOMEBREW_PREFIX
    unset HOMEBREW_CELLAR
    unset HOMEBREW_REPOSITORY

    # Remove temporary directory
    rm -rf "$temp_dir"
}
