#!/usr/bin/env python3
"""
Main entry point for creating new releases.
"""

from pathlib import Path


def get_script_path(script_name):
    """Get the absolute path to a script in the repository"""
    repo_root = Path(__file__).parent.parent.parent
    
    # Map script names to their locations in the py-release directory
    script_locations = {
        "pypi-new-release": "common/pypi-new-release",
        "pypi-to-apt": "debian/pypi-to-apt",
        "test-apt-package.sh": "debian/test-apt-package.sh",
        "apt-update": "debian/apt-update",
        "pypi-to-brew": "brew/pypi-to-brew",
        "test-brew-formula.sh": "brew/test-brew-formula.sh",
        "brew-update": "brew/brew-update",
        "pypi-package-info": "common/pypi-package-info",
        "trigger-workflow": "common/trigger-workflow"
    }
    
    if script_name in script_locations:
        return repo_root / "py-release" / script_locations[script_name]
    else:
        # Fallback to bin directory for any scripts not in the mapping
        return repo_root / "bin" / script_name 