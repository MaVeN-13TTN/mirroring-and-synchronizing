# Bitbucket to GitHub Migration and Synchronization

This project provides tools and configurations for migrating repositories from Bitbucket to GitHub and setting up automatic one-way synchronization to keep the GitHub repository updated with changes from Bitbucket.

## Features

- One-time migration of repositories from Bitbucket to GitHub
- Automatic one-way synchronization from Bitbucket to GitHub using Bitbucket Pipelines
- Preservation of all branches, tags, and commit history
- Support for both HTTPS and SSH authentication
- Interactive setup script for easy configuration

## Why Migrate and Synchronize?

There are several reasons you might want to migrate from Bitbucket to GitHub while maintaining synchronization:

- GitHub offers better integration with many CI/CD tools and third-party services
- You want to take advantage of GitHub features like GitHub Actions, Codespaces, or Advanced Security
- Your team is transitioning from Bitbucket to GitHub but needs to maintain both during the transition
- You want to have a backup of your code on another platform
- You have some team members who prefer GitHub and others who prefer Bitbucket

## Getting Started

We provide two different methods to set up the migration and synchronization process:

### Option 1: Interactive Bash Script (Recommended for Most Users)

The easiest way to get started is to use the interactive setup script:

```bash
./setup-mirroring.sh
```

This bash script will guide you through the process of:

1. Generating the necessary access tokens
2. Creating the GitHub repository (if it doesn't exist)
3. Performing the initial migration
4. Setting up ongoing synchronization

### Option 2: Python Script (For Automation and Programmatic Use)

For users who prefer Python or need to automate the process, we provide a Python script:

```bash
python migrate.py --bb-user BITBUCKET_USERNAME --bb-repo BITBUCKET_REPO \
                 --gh-user GITHUB_USERNAME --gh-repo GITHUB_REPO \
                 --bb-token BITBUCKET_APP_PASSWORD --gh-token GITHUB_TOKEN \
                 [--private]
```

The Python script:

- Can be integrated into other Python applications
- Provides better error handling
- Works cross-platform (Windows, macOS, Linux)
- Is ideal for automating migrations of multiple repositories

Requirements:

- Python 3.6+
- Git
- Requests library (`pip install requests`)

For detailed instructions:

- Interactive Bash Script: [Bitbucket to GitHub Migration Guide](bitbucket-to-github.md)
- Python Script: [Python Migration Guide](python-migration.md)

## Manual Setup

If you prefer to set up the migration and synchronization manually, follow these steps:

1. Create a GitHub repository (if it doesn't exist)
2. Generate access tokens for both Bitbucket and GitHub
3. Perform the initial migration using Git commands
4. Set up Bitbucket Pipelines for ongoing synchronization

Detailed instructions for manual setup are available in the [Bitbucket to GitHub Migration Guide](bitbucket-to-github.md).

## Setting Up Bitbucket Pipeline

### Required Credentials

To set up the Bitbucket Pipeline for synchronization, you'll need these credentials:

1. **Bitbucket Access Token**:

   - Purpose: Allows the pipeline to read from your Bitbucket repository
   - Permissions needed: Repository read access
   - Where to create: Bitbucket > Personal settings > App passwords
   - Variable name in pipeline: `BITBUCKET_APP_PASSWORD`

2. **GitHub Personal Access Token**:

   - Purpose: Allows the pipeline to write to your GitHub repository
   - Permissions needed: Repository (repo) scope
   - Where to create: GitHub > Settings > Developer settings > Personal access tokens
   - Variable name in pipeline: `GITHUB_TOKEN`

3. **GitHub Repository Information**:
   - Purpose: Identifies where to push the mirrored repository
   - Variables needed:
     - `GITHUB_REPO_OWNER`: Your GitHub username or organization name
     - `GITHUB_REPO_NAME`: Your GitHub repository name

### Pipeline Setup Steps

1. **Enable Bitbucket Pipelines**:

   - Go to Repository settings > Pipelines > Settings
   - Toggle the switch to enable Pipelines

2. **Add Repository Variables**:

   - Go to Repository settings > Pipelines > Repository variables
   - Add the variables listed above
   - Check "Secured" for token variables to protect them in logs

3. **Create Pipeline Configuration**:
   - Create a `bitbucket-pipelines.yml` file in your repository
   - Use the template provided in this project
   - Commit and push to trigger the pipeline

For a complete step-by-step guide, see the [Bitbucket Pipeline Setup Guide](pipeline-setup.md) and the [Bitbucket to GitHub Migration Guide](bitbucket-to-github.md).

## Prerequisites

- A repository on Bitbucket (source)
- Administrator access to the Bitbucket repository
- A GitHub account with permission to create repositories
- Git installed on your local machine (for manual migration)

## Security Considerations

- All authentication tokens and SSH keys should be stored securely
- Use repository-specific deploy keys and tokens with minimal required permissions
- Store App Passwords and tokens as secured repository variables in Bitbucket
- Use the provided .env file approach for local token storage with secure permissions
- Never commit .env files containing tokens to version control
- Regularly rotate credentials for enhanced security

For detailed information on secure token handling, see the [Secure Token Handling Guide](secure-token-handling.md).

## Troubleshooting

If you encounter issues during migration or synchronization, check the [Troubleshooting Guide](troubleshooting.md) for common problems and solutions.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
