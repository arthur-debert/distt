#!/bin/bash
set -e

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get py-release root directory
PY_RELEASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
# Get repository root directory
REPO_ROOT="$(cd "$PY_RELEASE_DIR/.." && pwd)"

# Source common functions
source "$PY_RELEASE_DIR/lib/common.sh"

# Test configuration
PACKAGE_NAME="nanodoc"
VERSION="0.8.11"
TEST_REPO_DIR="$REPO_ROOT/apt-test-repo"
TEST_GIT_URL="https://github.com/arthur-debert/apt-test.git"
TEST_PUBLIC_URL="https://arthur-debert.github.io/apt-test"

log "Testing APT package workflow..."

# Test local repository workflow
log "Testing local repository workflow..."

log "1. Building package..."
"$PY_RELEASE_DIR/apt/build" \
    --package-name="$PACKAGE_NAME" \
    --version="$VERSION" || {
    error "Build failed"
    exit 1
}

log "2. Testing local installation..."
"$PY_RELEASE_DIR/apt/verify" \
    --package-name="$PACKAGE_NAME" \
    --version="$VERSION" || {
    error "Local verification failed"
    exit 1
}

log "3. Publishing to local repository..."
"$PY_RELEASE_DIR/apt/publish" \
    --package-name="$PACKAGE_NAME" \
    --version="$VERSION" \
    --repo-dir="$TEST_REPO_DIR" || {
    error "Local publish failed"
    exit 1
}

log "4. Testing installation from local repository..."
"$PY_RELEASE_DIR/apt/verify" \
    --package-name="$PACKAGE_NAME" \
    --version="$VERSION" \
    --repo-dir="$TEST_REPO_DIR" || {
    error "Local repository verification failed"
    exit 1
}

# Test git repository workflow (if git URL provided)
if [ -n "$TEST_GIT_URL" ]; then
    log "Testing git repository workflow..."

    log "5. Publishing to git repository..."
    "$PY_RELEASE_DIR/apt/publish" \
        --package-name="$PACKAGE_NAME" \
        --version="$VERSION" \
        --target=git \
        --git-url="$TEST_GIT_URL" \
        --public-url="$TEST_PUBLIC_URL" || {
        error "Git publish failed"
        exit 1
    }

    log "6. Testing installation from git repository..."
    "$PY_RELEASE_DIR/apt/verify" \
        --package-name="$PACKAGE_NAME" \
        --version="$VERSION" \
        --repo-url="$TEST_PUBLIC_URL" || {
        error "Git repository verification failed"
        exit 1
    }
fi

log "All tests passed successfully!"

# Clean up test repository
if [ -d "$TEST_REPO_DIR" ]; then
    rm -rf "$TEST_REPO_DIR"
fi
