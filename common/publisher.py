#!/usr/bin/env python3
"""
Publisher class for handling PyPI and GitHub releases.
This is used by the distt-publish command.
"""

import os
import subprocess
from pathlib import Path
import shutil
from typing import Optional, List, Dict
import toml


class Publisher:
    """Handles publishing Python packages to PyPI and GitHub."""
    
    def __init__(self, package_dir: str = "."):
        self.package_dir = Path(package_dir)
        self.pyproject_path = self.package_dir / "pyproject.toml"
        if not self.pyproject_path.exists():
            raise FileNotFoundError(
                f"No pyproject.toml found in {package_dir}"
            )
        
        # Load package info
        self.package_info = self._load_package_info()
        
    def _load_package_info(self) -> Dict[str, str]:
        """Load package information from pyproject.toml."""
        with open(self.pyproject_path) as f:
            pyproject = toml.load(f)
        
        return {
            "name": pyproject["tool"]["poetry"]["name"],
            "version": pyproject["tool"]["poetry"]["version"],
            "description": pyproject["tool"]["poetry"]["description"],
            "authors": pyproject["tool"]["poetry"]["authors"]
        }
    
    def _run_command(
        self, cmd: List[str], check: bool = True
    ) -> subprocess.CompletedProcess:
        """Run a shell command."""
        return subprocess.run(
            cmd, check=check, capture_output=True, text=True
        )
    
    def build(self) -> bool:
        """Build the Python package using poetry."""
        try:
            self._run_command(["poetry", "build"])
            return True
        except subprocess.CalledProcessError as e:
            print(f"Failed to build package: {e}")
            return False
    
    def publish_to_pypi(self, force: bool = False) -> bool:
        """Publish the package to PyPI."""
        try:
            # Check if version already exists on PyPI
            if not force:
                check_cmd = [
                    "pip", "index", "versions", self.package_info["name"]
                ]
                result = self._run_command(check_cmd, check=False)
                if str(self.package_info["version"]) in result.stdout:
                    print(
                        f"Version {self.package_info['version']} already "
                        "exists on PyPI. Use --force to override."
                    )
                    return False
            
            # Publish using poetry
            self._run_command(["poetry", "publish"])
            print(
                f"Successfully published {self.package_info['name']} "
                f"{self.package_info['version']} to PyPI"
            )
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"Failed to publish to PyPI: {e}")
            return False
    
    def create_github_release(
        self, force: bool = False, release_notes: Optional[str] = None
    ) -> bool:
        """Create a GitHub release with the built distribution files."""
        if not shutil.which("gh"):
            print(
                "GitHub CLI not found. Please install it to create "
                "GitHub releases."
            )
            return False
        
        try:
            version = self.package_info["version"]
            tag_name = f"v{version}"
            
            # Delete existing release if force is True
            if force:
                try:
                    self._run_command(
                        ["gh", "release", "delete", tag_name, "-y"],
                        check=False
                    )
                    self._run_command(
                        ["git", "tag", "-d", tag_name],
                        check=False
                    )
                    self._run_command(
                        ["git", "push", "origin", f":refs/tags/{tag_name}"],
                        check=False
                    )
                except subprocess.CalledProcessError:
                    pass
            
            # Create release command
            cmd = [
                "gh", "release", "create", tag_name,
                "--title", f"Release {tag_name}"
            ]
            
            # Add release notes if provided
            if release_notes:
                cmd.extend(["--notes", release_notes])
            else:
                cmd.append("--generate-notes")
            
            # Add distribution files
            dist_files = list(Path("dist").glob("*"))
            for file in dist_files:
                cmd.append(str(file))
            
            # Create the release
            self._run_command(cmd)
            print(f"Successfully created GitHub release {tag_name}")
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"Failed to create GitHub release: {e}")
            return False
    
    def publish(
        self,
        targets: List[str],
        force: bool = False,
        release_notes: Optional[str] = None
    ) -> bool:
        """
        Publish to specified targets.
        
        Args:
            targets: List of targets ("pypi", "github")
            force: Force update even if version exists
            release_notes: Optional release notes for GitHub release
        """
        success = True
        
        # Always build first
        if not self.build():
            return False
        
        # Publish to each target
        for target in targets:
            if target == "pypi":
                if not self.publish_to_pypi(force):
                    success = False
            elif target == "github":
                if not self.create_github_release(force, release_notes):
                    success = False
            else:
                print(f"Unknown target: {target}")
                success = False
        
        return success 