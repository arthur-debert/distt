#!/bin/bash

# Check if running in a Linux environment
is_linux() {
    [[ "$(uname -s)" == "Linux" ]]
}

# Check if Docker is available
has_docker() {
    command -v docker >/dev/null 2>&1
}

# Get the Docker image to use for APT operations
get_docker_image() {
    echo "debian:bullseye"
}

# Run a command in Docker if not on Linux
run_in_docker() {
    local script=$1
    shift

    if is_linux; then
        "$script" "$@"
        return $?
    fi

    if ! has_docker; then
        error "Docker is required for APT operations on non-Linux systems"
        return 1
    fi

    # Create a temporary directory for mounting
    local temp_dir
    temp_dir=$(mktemp -d)
    trap 'rm -rf "$temp_dir"' EXIT

    # Copy necessary files to temp directory
    mkdir -p "$temp_dir/py-release"
    cp -r "$(dirname "$(dirname "$(dirname "$script")")")"/* "$temp_dir/py-release/"
    cp -r "$(dirname "$(dirname "$script")")/../lib" "$temp_dir/py-release/"

    # Run the script in Docker
    docker run --rm \
        -v "$temp_dir:/workspace" \
        -v "$(pwd):/package" \
        -w /package \
        "$(get_docker_image)" \
        "/workspace/py-release/apt/$(basename "$script")" "$@"
}

# Create debian package directory structure
create_deb_structure() {
    local package_name=$1
    local version=$2
    local arch=${3:-all}
    local root_dir=$4

    mkdir -p "$root_dir/DEBIAN"
    mkdir -p "$root_dir/usr/lib/python3/dist-packages"
    mkdir -p "$root_dir/usr/bin"

    # Create control file
    cat >"$root_dir/DEBIAN/control" <<EOF
Package: $package_name
Version: $version
Architecture: $arch
Maintainer: $(git config user.name) <$(git config user.email)>
Description: $(python3 setup.py --description 2>/dev/null || echo "No description available")
 Python package $package_name version $version
Section: python
Priority: optional
Depends: python3
EOF
}

# Build debian package
build_deb_package() {
    local package_name=$1
    local version=$2
    local root_dir=$3
    local output_dir=${4:-dist}

    mkdir -p "$output_dir"
    dpkg-deb --build "$root_dir" "$output_dir/${package_name}_${version}_all.deb"
}

# Validate debian package
validate_deb_package() {
    local deb_file=$1

    # Check if package exists
    if [ ! -f "$deb_file" ]; then
        error "Package file not found: $deb_file"
        return 1
    fi

    # Check package with lintian if available
    if command -v lintian >/dev/null 2>&1; then
        lintian "$deb_file" || true
    fi

    # Verify package with dpkg-deb
    dpkg-deb --info "$deb_file" >/dev/null
}

# Install debian package
install_deb_package() {
    local deb_file=$1

    # Install package dependencies
    apt-get update -qq
    apt-get install -y python3 >/dev/null

    # Install the package
    dpkg -i "$deb_file"
    apt-get install -f -y >/dev/null
}

# Test debian package installation
test_deb_package() {
    local package_name=$1
    local version=$2

    # Try to import the package
    if ! python3 -c "import $package_name; print($package_name.__version__)" | grep -q "^$version$"; then
        error "Package $package_name version $version not properly installed"
        return 1
    fi
}

# Get package version from pyproject.toml or setup.py
get_package_version() {
    if [ -f "pyproject.toml" ]; then
        grep '^version = ' pyproject.toml | cut -d'"' -f2
    elif [ -f "setup.py" ]; then
        python3 setup.py --version
    else
        return 1
    fi
}

# Get package name from pyproject.toml or setup.py
get_package_name() {
    if [ -f "pyproject.toml" ]; then
        grep '^name = ' pyproject.toml | cut -d'"' -f2
    elif [ -f "setup.py" ]; then
        python3 setup.py --name
    else
        return 1
    fi
}
