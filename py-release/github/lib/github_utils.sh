#!/bin/bash

# Check if a GitHub release exists
github_release_exists() {
    local package_name=$1
    local version=$2

    # Try to get release info from GitHub
    if gh release view "v$version" &>/dev/null; then
        return 0
    fi
    return 1
}

# Create GitHub release assets directory
prepare_release_assets() {
    local assets_dir=".github/release-assets"
    mkdir -p "$assets_dir"
    echo "$assets_dir"
}

# Generate release notes
generate_release_notes() {
    local version=$1
    local package_name=$2
    local notes_file
    notes_file=$(prepare_release_assets)/release-notes.md

    {
        echo "# $package_name v$version"
        echo
        echo "## Changes"
        echo
        # Get changes since last tag
        if git describe --tags --abbrev=0 &>/dev/null; then
            local last_tag
            last_tag=$(git describe --tags --abbrev=0)
            git log --pretty=format:"* %s" "$last_tag"..HEAD
        else
            git log --pretty=format:"* %s"
        fi
        echo
        echo "## Installation"
        echo
        echo "### PyPI"
        echo "\`\`\`bash"
        echo "pip install $package_name==$version"
        echo "\`\`\`"
        echo
        echo "### Homebrew"
        echo "\`\`\`bash"
        echo "brew install adebert/releasee-test/$package_name"
        echo "\`\`\`"
    } >"$notes_file"

    echo "$notes_file"
}

# Validate release assets
validate_release_assets() {
    local assets_dir=".github/release-assets"

    # Check if assets directory exists
    if [ ! -d "$assets_dir" ]; then
        error "Assets directory not found: $assets_dir"
        return 1
    fi

    # Check if release notes exist and are not empty
    if [ ! -s "$assets_dir/release-notes.md" ]; then
        error "Release notes not found or empty: $assets_dir/release-notes.md"
        return 1
    fi

    # Check for distribution files
    if ! ls "$assets_dir"/*.whl >/dev/null 2>&1; then
        error "No wheel distribution file found in $assets_dir"
        return 1
    fi

    if ! ls "$assets_dir"/*.tar.gz >/dev/null 2>&1; then
        error "No source distribution file found in $assets_dir"
        return 1
    fi

    return 0
}

# Create GitHub release
create_github_release() {
    local version=$1
    local package_name=$2
    local notes_file=$3
    local assets_dir=".github/release-assets"

    # Create release with all assets
    gh release create "v$version" \
        --title "$package_name v$version" \
        --notes-file "$notes_file" \
        "$assets_dir"/*
}

# Get latest GitHub release version
get_github_latest_version() {
    local package_name=$1

    # Get latest release version from GitHub
    gh release list --limit 1 | awk '{print $1}' | sed 's/^v//'
}

# Verify GitHub release
verify_github_release() {
    local version=$1
    local package_name=$2

    # Check release info
    local release_info
    release_info=$(gh release view "v$version" --json tagName,name,body,assets)

    # Check tag name
    if ! echo "$release_info" | jq -e '.tagName == "v'"$version"'"' >/dev/null; then
        error "Release tag mismatch"
        return 1
    fi

    # Check release name
    if ! echo "$release_info" | jq -e '.name == "'"$package_name v$version"'"' >/dev/null; then
        error "Release name mismatch"
        return 1
    fi

    # Check assets
    if ! echo "$release_info" | jq -e '.assets | length >= 3' >/dev/null; then
        error "Missing release assets"
        return 1
    fi

    return 0
}
