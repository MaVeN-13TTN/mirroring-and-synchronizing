#!/usr/bin/env python3
"""
Bitbucket to GitHub Migration Script

This script automates the migration of a Bitbucket repository to GitHub
and sets up synchronization using Bitbucket Pipelines.

Usage:
    python migrate.py [--bb-user USERNAME] [--bb-repo REPO] [--gh-user USERNAME] [--gh-repo REPO]
                     [--bb-token TOKEN] [--gh-token TOKEN] [--private]

The script will first try to load configuration from a .env file in the current directory.
Command line arguments will override values from the .env file.

Requirements:
    - Python 3.6+
    - Git
    - Requests library (pip install requests)
    - python-dotenv library (pip install python-dotenv)
"""

import argparse
import os
import subprocess
import tempfile
import requests
import sys
import json
import getpass
from pathlib import Path


def load_env_file():
    """Load environment variables from .env file."""
    try:
        from dotenv import load_dotenv

        env_path = Path(".") / ".env"
        if env_path.exists():
            print(f"Loading configuration from {env_path}")
            load_dotenv(dotenv_path=env_path)
            return True
    except ImportError:
        print("python-dotenv not installed. Install with: pip install python-dotenv")
        print("Continuing without .env file support...")
    return False


def create_env_file(
    bb_user, bb_repo, gh_user, gh_repo, bb_token, gh_token, private=True
):
    """Create a .env file with the provided configuration."""
    try:
        from datetime import datetime

        env_path = Path(".") / ".env"

        # Create .env file content
        content = f"""# Environment variables for Bitbucket to GitHub migration
# Created on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

# Bitbucket credentials
BITBUCKET_TOKEN={bb_token}
BITBUCKET_USERNAME={bb_user}
BITBUCKET_REPO={bb_repo}

# GitHub credentials
GITHUB_TOKEN={gh_token}
GITHUB_USERNAME={gh_user}
GITHUB_REPO={gh_repo}

# Optional settings
GITHUB_PRIVATE={'true' if private else 'false'}
"""

        # Write to file with secure permissions
        with open(env_path, "w") as f:
            f.write(content)

        # Set secure permissions (readable only by owner)
        os.chmod(env_path, 0o600)

        print(f"Configuration saved to {env_path} with secure permissions.")
        print("For security, avoid committing this file to version control.")
        return True
    except Exception as e:
        print(f"Error creating .env file: {e}")
        return False


def parse_args():
    """Parse command line arguments with fallback to environment variables."""
    parser = argparse.ArgumentParser(
        description="Migrate a repository from Bitbucket to GitHub"
    )

    # Load defaults from environment variables
    env_bb_user = os.environ.get("BITBUCKET_USERNAME")
    env_bb_repo = os.environ.get("BITBUCKET_REPO")
    env_gh_user = os.environ.get("GITHUB_USERNAME")
    env_gh_repo = os.environ.get("GITHUB_REPO")
    env_bb_token = os.environ.get("BITBUCKET_TOKEN")
    env_gh_token = os.environ.get("GITHUB_TOKEN")
    env_private = os.environ.get("GITHUB_PRIVATE", "false").lower() in (
        "true",
        "yes",
        "1",
    )

    # Define arguments with defaults from environment
    parser.add_argument(
        "--bb-user", default=env_bb_user, help="Bitbucket username or workspace"
    )
    parser.add_argument(
        "--bb-repo", default=env_bb_repo, help="Bitbucket repository name"
    )
    parser.add_argument("--gh-user", default=env_gh_user, help="GitHub username")
    parser.add_argument("--gh-repo", default=env_gh_repo, help="GitHub repository name")
    parser.add_argument(
        "--bb-token", default=env_bb_token, help="Bitbucket access token"
    )
    parser.add_argument(
        "--gh-token", default=env_gh_token, help="GitHub personal access token"
    )
    parser.add_argument(
        "--private",
        action="store_true",
        default=env_private,
        help="Create a private GitHub repository",
    )
    parser.add_argument(
        "--save-env", action="store_true", help="Save configuration to .env file"
    )

    args = parser.parse_args()

    # Prompt for missing required values
    if not args.bb_user:
        args.bb_user = input("Enter your Bitbucket username or workspace: ")

    if not args.bb_repo:
        args.bb_repo = input("Enter your Bitbucket repository name: ")

    if not args.gh_user:
        args.gh_user = input("Enter your GitHub username: ")

    if not args.gh_repo:
        args.gh_repo = input("Enter your GitHub repository name: ")

    if not args.bb_token:
        args.bb_token = getpass.getpass("Enter your Bitbucket access token: ")

    if not args.gh_token:
        args.gh_token = getpass.getpass("Enter your GitHub personal access token: ")

    return args


def check_github_repo(gh_user, gh_repo, gh_token):
    """Check if the GitHub repository exists."""
    url = f"https://api.github.com/repos/{gh_user}/{gh_repo}"
    headers = {
        "Authorization": f"token {gh_token}",
        "Accept": "application/vnd.github.v3+json",
    }
    response = requests.get(url, headers=headers)
    return response.status_code == 200


def create_github_repo(gh_user, gh_repo, gh_token, private=True):
    """Create a new GitHub repository."""
    url = "https://api.github.com/user/repos"
    headers = {
        "Authorization": f"token {gh_token}",
        "Accept": "application/vnd.github.v3+json",
    }
    data = {"name": gh_repo, "private": private, "auto_init": False}
    response = requests.post(url, headers=headers, data=json.dumps(data))
    if response.status_code not in (201, 200):
        print(f"Error creating GitHub repository: {response.text}")
        sys.exit(1)
    print(f"GitHub repository created: {gh_user}/{gh_repo}")


def migrate_repository(bb_user, bb_repo, gh_user, gh_repo, bb_token, gh_token):
    """Migrate the repository from Bitbucket to GitHub."""
    with tempfile.TemporaryDirectory() as temp_dir:
        os.chdir(temp_dir)

        # Clone Bitbucket repository
        print(f"Cloning Bitbucket repository: {bb_user}/{bb_repo}")
        clone_url = (
            f"https://x-token-auth:{bb_token}@bitbucket.org/{bb_user}/{bb_repo}.git"
        )
        subprocess.run(["git", "clone", "--mirror", clone_url, "repo"], check=True)

        os.chdir("repo")

        # Push to GitHub
        print(f"Pushing to GitHub repository: {gh_user}/{gh_repo}")
        push_url = (
            f"https://x-access-token:{gh_token}@github.com/{gh_user}/{gh_repo}.git"
        )
        subprocess.run(["git", "push", "--mirror", push_url], check=True)

        print("Repository migration completed successfully!")


def create_pipeline_config(bb_user, bb_repo, gh_user, gh_repo):
    """Create the Bitbucket Pipelines configuration file."""
    config = f"""# Bitbucket Pipelines configuration for mirroring to GitHub
# This pipeline automatically syncs changes from Bitbucket to GitHub

pipelines:
  # Run on all branches
  default:
    - step:
        name: Mirror to GitHub
        image: alpine/git:latest
        # Disable default clone since we'll do a mirror clone
        clone:
          enabled: false
        script:
          # Set Git configuration
          - git config --global user.name "Bitbucket Pipeline"
          - git config --global user.email "noreply@bitbucket.org"

          # Clone the Bitbucket repository with mirror option
          # This preserves all branches, tags, and history
          - echo "Cloning Bitbucket repository..."
          - git clone --mirror https://x-token-auth:${{BITBUCKET_TOKEN}}@bitbucket.org/{bb_user}/{bb_repo}.git repo
          - cd repo

          # Push to GitHub with mirror option
          # This ensures GitHub repository is an exact copy of Bitbucket
          - echo "Pushing to GitHub repository..."
          - git push --mirror https://x-access-token:${{GITHUB_TOKEN}}@github.com/{gh_user}/{gh_repo}.git

          # Clean up
          - echo "Synchronization completed successfully!"

  # Also run on schedule (daily at midnight)
  schedules:
    - cron: '0 0 * * *'
      branches:
        include:
          - main  # or your default branch
      name: Daily Sync
      deployment: production
      step:
        name: Scheduled Mirror to GitHub
        image: alpine/git:latest
        clone:
          enabled: false
        script:
          # Same script as above
          - git config --global user.name "Bitbucket Pipeline"
          - git config --global user.email "noreply@bitbucket.org"
          - echo "Performing scheduled sync to GitHub..."
          - git clone --mirror https://x-token-auth:${{BITBUCKET_TOKEN}}@bitbucket.org/{bb_user}/{bb_repo}.git repo
          - cd repo
          - git push --mirror https://x-access-token:${{GITHUB_TOKEN}}@github.com/{gh_user}/{gh_repo}.git
          - echo "Scheduled synchronization completed successfully!"

# Note: You need to set the following repository variables in Bitbucket:
# - BITBUCKET_TOKEN: Your Bitbucket access token with repository read permission
# - GITHUB_TOKEN: Your GitHub personal access token with repository write permission
"""

    with open("bitbucket-pipelines.yml", "w") as f:
        f.write(config)

    print("Bitbucket Pipelines configuration created: bitbucket-pipelines.yml")
    print("\nIMPORTANT: You need to add this file to your Bitbucket repository")
    print("and set up the following repository variables in Bitbucket:")
    print("- BITBUCKET_TOKEN: Your Bitbucket access token")
    print("- GITHUB_TOKEN: Your GitHub personal access token")


def main():
    """Main function."""
    # Try to load configuration from .env file
    load_env_file()

    # Parse arguments (with fallback to environment variables)
    args = parse_args()

    # Check if GitHub repository exists
    if not check_github_repo(args.gh_user, args.gh_repo, args.gh_token):
        print(
            f"GitHub repository {args.gh_user}/{args.gh_repo} does not exist. Creating..."
        )
        create_github_repo(args.gh_user, args.gh_repo, args.gh_token, args.private)
    else:
        print(f"GitHub repository {args.gh_user}/{args.gh_repo} already exists.")

    # Migrate repository
    migrate_repository(
        args.bb_user,
        args.bb_repo,
        args.gh_user,
        args.gh_repo,
        args.bb_token,
        args.gh_token,
    )

    # Create pipeline configuration
    create_pipeline_config(args.bb_user, args.bb_repo, args.gh_user, args.gh_repo)

    # Save configuration to .env file if requested
    if args.save_env or input("Save configuration to .env file? (y/n): ").lower() in (
        "y",
        "yes",
    ):
        create_env_file(
            args.bb_user,
            args.bb_repo,
            args.gh_user,
            args.gh_repo,
            args.bb_token,
            args.gh_token,
            args.private,
        )

    print("\nMigration completed successfully!")
    print("Next steps:")
    print("1. Add the bitbucket-pipelines.yml file to your Bitbucket repository")
    print("2. Set up repository variables in Bitbucket")
    print("3. Enable Bitbucket Pipelines")


if __name__ == "__main__":
    main()
