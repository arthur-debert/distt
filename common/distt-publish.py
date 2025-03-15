#!/usr/bin/env python3
"""
Command line tool for publishing Python packages to PyPI and GitHub.
"""

import argparse
import sys

from publisher import Publisher


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Publish Python packages to PyPI and GitHub"
    )
    
    parser.add_argument(
        "--target",
        choices=["pypi", "github"],
        action="append",
        dest="targets",
        help="Target to publish to (can be specified multiple times)"
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
        "--release-notes",
        help="Path to release notes file for GitHub release"
    )
    
    return parser.parse_args()


def main() -> int:
    """Main entry point."""
    args = parse_args()
    
    # Default to all targets if none specified
    if not args.targets:
        args.targets = ["pypi", "github"]
    
    try:
        # Initialize publisher
        publisher = Publisher()
        
        # Load release notes if provided
        release_notes = None
        if args.release_notes:
            with open(args.release_notes) as f:
                release_notes = f.read()
        
        # Publish to targets
        if publisher.publish(args.targets, args.force, release_notes):
            print("✅ Publishing completed successfully!")
            return 0
        else:
            print("❌ Publishing failed!")
            return 1
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main()) 