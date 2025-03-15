#!/usr/bin/env python3
"""
Distributor class for handling APT and Homebrew package creation.
This is used by the distt command.
"""

import subprocess
from pathlib import Path
from typing import Optional, List, Dict
import tempfile
import requests


class Distributor:
    """Handles creating APT and Homebrew packages from PyPI packages."""
    
    def __init__(self, package_name: str, version: Optional[str] = None):
        self.package_name = package_name
        self.version = version
        self.pypi_info = self._fetch_pypi_info()
        
        if not version:
            self.version = self.pypi_info["info"]["version"]
    
    def _run_command(
        self, cmd: List[str], check: bool = True
    ) -> subprocess.CompletedProcess:
        """Run a shell command."""
        return subprocess.run(cmd, check=check, capture_output=True, text=True)
    
    def _fetch_pypi_info(self) -> Dict:
        """Fetch package information from PyPI."""
        url = f"https://pypi.org/pypi/{self.package_name}/json"
        response = requests.get(url)
        response.raise_for_status()
        return response.json()
    
    def _get_package_url(self) -> str:
        """Get the source distribution URL from PyPI."""
        for url in self.pypi_info["urls"]:
            if url["packagetype"] == "sdist":
                return url["url"]
        raise ValueError("No source distribution found on PyPI")
    
    def build_apt_package(self, output_dir: str = "dist") -> bool:
        """Build an APT package from the PyPI package."""
        try:
            # Create temporary directory for building
            with tempfile.TemporaryDirectory() as temp_dir:
                # Download source distribution
                url = self._get_package_url()
                response = requests.get(url)
                response.raise_for_status()
                
                # Save to temporary directory
                sdist_path = Path(temp_dir) / (
                    f"{self.package_name}-{self.version}.tar.gz"
                )
                sdist_path.write_bytes(response.content)
                
                # Build APT package
                cmd = [
                    "apt/build",
                    f"--package-name={self.package_name}",
                    f"--version={self.version}",
                    f"--output-dir={output_dir}"
                ]
                self._run_command(cmd)
                return True
                
        except (subprocess.CalledProcessError, requests.RequestException) as e:
            print(f"Failed to build APT package: {e}")
            return False
    
    def build_brew_formula(self, output_dir: str = "Formula") -> bool:
        """Build a Homebrew formula from the PyPI package."""
        try:
            cmd = [
                "brew/build",
                f"--package-name={self.package_name}",
                f"--version={self.version}",
                f"--output-dir={output_dir}"
            ]
            self._run_command(cmd)
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"Failed to build Homebrew formula: {e}")
            return False
    
    def publish_apt_package(self, repo_url: str, force: bool = False) -> bool:
        """Publish the APT package to a repository."""
        try:
            cmd = [
                "apt/publish",
                f"--package-name={self.package_name}",
                f"--version={self.version}",
                f"--repo-url={repo_url}"
            ]
            if force:
                cmd.append("--force")
            
            self._run_command(cmd)
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"Failed to publish APT package: {e}")
            return False
    
    def publish_brew_formula(self, tap_url: str, force: bool = False) -> bool:
        """Publish the Homebrew formula to a tap."""
        try:
            cmd = [
                "brew/publish",
                f"--package-name={self.package_name}",
                f"--version={self.version}",
                f"--tap-url={tap_url}"
            ]
            if force:
                cmd.append("--force")
            
            self._run_command(cmd)
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"Failed to publish Homebrew formula: {e}")
            return False
    
    def distribute(
        self,
        targets: List[str],
        force: bool = False,
        apt_repo: Optional[str] = None,
        brew_tap: Optional[str] = None
    ) -> bool:
        """
        Distribute to specified targets.
        
        Args:
            targets: List of targets ("apt", "brew")
            force: Force update even if version exists
            apt_repo: URL of APT repository
            brew_tap: URL of Homebrew tap
        """
        success = True
        
        for target in targets:
            if target == "apt":
                if not apt_repo:
                    print("APT repository URL is required for apt target")
                    success = False
                    continue
                    
                if not self.build_apt_package():
                    success = False
                    continue
                    
                if not self.publish_apt_package(apt_repo, force):
                    success = False
                    
            elif target == "brew":
                if not brew_tap:
                    print("Homebrew tap URL is required for brew target")
                    success = False
                    continue
                    
                if not self.build_brew_formula():
                    success = False
                    continue
                    
                if not self.publish_brew_formula(brew_tap, force):
                    success = False
                    
            else:
                print(f"Unknown target: {target}")
                success = False
        
        return success 