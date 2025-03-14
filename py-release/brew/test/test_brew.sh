#!/bin/bash
# Test script for Homebrew target functionality

set -e

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get py-release root directory
PY_RELEASE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# Get repository root directory
REPO_ROOT="$(cd "$PY_RELEASE_ROOT/.." && pwd)"

# Source common functions
source "$PY_RELEASE_ROOT/lib/common.sh"

# Test package details
PACKAGE_NAME="nanodoc"
VERSION="0.8.11"

log "Testing Homebrew target with $PACKAGE_NAME version $VERSION"

# Test build
log "Testing build step..."
"$PY_RELEASE_ROOT/brew/build" "$PACKAGE_NAME" "$VERSION"

# Verify formula was created
FORMULA_PATH="$REPO_ROOT/Formula/$PACKAGE_NAME.rb"
if [ ! -f "$FORMULA_PATH" ]; then
    error "Formula not created at $FORMULA_PATH"
    exit 1
fi
log "✅ Build step passed"

# Test check
log "Testing check step..."
"$PY_RELEASE_ROOT/brew/check" "$PACKAGE_NAME" "$VERSION"
log "✅ Check step passed"

# Test publish
log "Testing publish step..."
"$PY_RELEASE_ROOT/brew/publish" "$PACKAGE_NAME" "$VERSION"
log "✅ Publish step passed"

# Test verify
log "Testing verify step..."
"$PY_RELEASE_ROOT/brew/verify" "$PACKAGE_NAME" "$VERSION"
log "✅ Verify step passed"

log "All tests passed successfully!"
