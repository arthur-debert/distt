#!/usr/bin/env python3
"""
Command line tool for creating APT and Homebrew packages from PyPI packages.
"""

import argparse
import sys

from distributor import Distributor


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Create APT and Homebrew packages from PyPI packages"
    )
    
    parser.add_argument(
        "--target",
        choices=["apt", "brew"],
        action="append",
        dest="targets",
        help="Target to distribute to (can be specified multiple times)"
    )
    
    parser.add_argument(
        "--package-name",
        required=True,
        help="Name of the PyPI package to distribute"
    )
    
    parser.add_argument(
        "--version",
        help="Version to distribute (defaults to latest from PyPI)"
    )
    
    parser.add_argument(
        "--local",
        action="store_true",
        help="Run locally instead of using GitHub Actions"
    )
    
    parser.add_argument(
        "--force",
        action="store_true",
        help="Force update even if version exists"
    )
    
    parser.add_argument(
        "--apt-repo",
        help="URL of APT repository to publish to"
    )
    
    parser.add_argument(
        "--brew-tap",
        help="URL of Homebrew tap to publish to"
    )
    
    return parser.parse_args()


def main() -> int:
    """Main entry point."""
    args = parse_args()
    
    # Default to all targets if none specified
    if not args.targets:
        args.targets = ["apt", "brew"]
    
    try:
        # Initialize distributor
        distributor = Distributor(args.package_name, args.version)
        
        # Distribute to targets
        if distributor.distribute(
            args.targets,
            args.force,
            apt_repo=args.apt_repo,
            brew_tap=args.brew_tap
        ):
            print("✅ Distribution completed successfully!")
            return 0
        else:
            print("❌ Distribution failed!")
            return 1
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main()) 