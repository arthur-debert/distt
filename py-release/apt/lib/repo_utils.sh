#!/bin/bash

# Initialize APT repository structure
init_apt_repo() {
    local repo_dir=$1
    local codename=${2:-stable}
    local component=${3:-main}
    local arch=${4:-all}

    mkdir -p "$repo_dir/dists/$codename/$component/binary-$arch"
    mkdir -p "$repo_dir/pool/$component"
}

# Generate APT repository metadata
generate_repo_metadata() {
    local repo_dir=$1
    local codename=${2:-stable}
    local component=${3:-main}
    local arch=${4:-all}

    # Create Packages file
    cd "$repo_dir" || exit 1
    dpkg-scanpackages "pool/$component" >"dists/$codename/$component/binary-$arch/Packages"
    gzip -k "dists/$codename/$component/binary-$arch/Packages"

    # Create Release file
    cd "dists/$codename" || exit 1
    {
        echo "Origin: Custom APT Repository"
        echo "Label: Custom APT Repository"
        echo "Suite: $codename"
        echo "Codename: $codename"
        echo "Components: $component"
        echo "Architectures: $arch"
        echo "Date: $(date -u '+%a, %d %b %Y %H:%M:%S UTC')"
        echo "MD5Sum:"
        find . -type f -name "Packages*" -exec md5sum {} \; | sed 's/\.\///'
        echo "SHA256:"
        find . -type f -name "Packages*" -exec sha256sum {} \; | sed 's/\.\///'
    } >Release

    # If GPG key is available, sign the Release file
    if command -v gpg >/dev/null 2>&1 && [ -n "$GPG_KEY" ]; then
        gpg --default-key "$GPG_KEY" -abs -o Release.gpg Release
        gpg --default-key "$GPG_KEY" --clearsign -o InRelease Release
    fi
}

# Add package to repository
add_package_to_repo() {
    local repo_dir=$1
    local deb_file=$2
    local component=${3:-main}

    # Copy package to pool
    mkdir -p "$repo_dir/pool/$component"
    cp "$deb_file" "$repo_dir/pool/$component/"

    # Update repository metadata
    generate_repo_metadata "$repo_dir"
}

# Test repository setup
test_repo_setup() {
    local repo_dir=$1
    local codename=${2:-stable}

    # Check repository structure
    for dir in "dists/$codename" "pool/main"; do
        if [ ! -d "$repo_dir/$dir" ]; then
            error "Missing repository directory: $dir"
            return 1
        fi
    done

    # Check metadata files
    for file in "dists/$codename/Release" "dists/$codename/main/binary-all/Packages"; do
        if [ ! -f "$repo_dir/$file" ]; then
            error "Missing repository file: $file"
            return 1
        fi
    done

    return 0
}

# Configure APT for repository
configure_apt_for_repo() {
    local repo_dir=$1
    local codename=${2:-stable}

    # Add repository to sources.list
    echo "deb [trusted=yes] file://$repo_dir $codename main" >/etc/apt/sources.list.d/local.list
    apt-get update -qq
}

# Clean up repository configuration
cleanup_apt_repo_config() {
    rm -f /etc/apt/sources.list.d/local.list
    apt-get update -qq
}
