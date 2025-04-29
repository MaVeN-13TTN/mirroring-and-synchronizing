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

The easiest way to get started is to use the interactive setup script:

```bash
./setup-mirroring.sh
```

This bash script will guide you through the process of:

1. Generating the necessary access tokens
2. Creating the GitHub repository (if it doesn't exist)
3. Performing the initial migration
4. Setting up ongoing synchronization

### Advanced Options

The script supports several command-line options:

```bash
./setup-mirroring.sh --debug --verbose
```

- `--debug`: Enables detailed debugging output (shows all commands as they execute)
- `--verbose`: Shows additional information during execution

### Requirements

- Git
- Bash shell
- curl

For detailed instructions, see the [Bitbucket to GitHub Migration Guide](bitbucket-to-github.md)

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

1. **Bitbucket App Password**:

   - Purpose: Allows the pipeline to read from your Bitbucket repository
   - Permissions needed: Repository read/write access, Pipelines read/write/variables
   - Where to create: Bitbucket > Personal settings > App passwords
   - Variable name in pipeline: `BITBUCKET_APP_PASSWORD`

2. **GitHub Personal Access Token**:

   - Purpose: Allows the pipeline to write to your GitHub repository
   - Permissions needed: Repository (repo) scope
   - Where to create: GitHub > Settings > Developer settings > Personal access tokens
   - Variable name in pipeline: `GITHUB_TOKEN`

3. **Personal Bitbucket Username** (for workspace repositories):
   - Purpose: Used for authentication with Bitbucket when using workspace repositories
   - Variable name in pipeline: `BITBUCKET_AUTH_USERNAME`
   - Note: Only required when your repository is under a workspace/organization

### Pipeline Setup Steps

1. **Enable Bitbucket Pipelines**:

   - Go to Repository settings > Pipelines > Settings
   - Toggle the switch to enable Pipelines

2. **Add Repository Variables**:

   - Go to Repository settings > Pipelines > Repository variables
   - Add the following variables:
     - `BITBUCKET_APP_PASSWORD`: Your Bitbucket App Password (mark as 'Secured')
     - `GITHUB_TOKEN`: Your GitHub personal access token (mark as 'Secured')
     - `BITBUCKET_AUTH_USERNAME`: Your personal Bitbucket username (if using a workspace)
   - Check "Secured" for token variables to protect them in logs

3. **Create Pipeline Configuration**:
   - The setup script automatically creates and commits the `bitbucket-pipelines.yml` file
   - The pipeline is configured to run on every push to your repository
   - It also includes a scheduled daily synchronization at midnight

For a complete step-by-step guide, see the [Bitbucket Pipeline Setup Guide](pipeline-setup.md) and the [Bitbucket to GitHub Migration Guide](bitbucket-to-github.md).

## Prerequisites

- A repository on Bitbucket (source)
- Administrator access to the Bitbucket repository
- A GitHub account with permission to create repositories
- Git installed on your local machine (for manual migration)

## Security Considerations

- All authentication tokens and app passwords should be stored securely
- Use repository-specific tokens with minimal required permissions
- Store App Passwords and tokens as secured repository variables in Bitbucket
- Use the provided .env file approach for local token storage with secure permissions (chmod 600)
- Never commit .env files containing tokens to version control
- For workspace repositories, ensure your personal account has appropriate permissions
- Regularly rotate credentials for enhanced security
- Consider using debug mode only when troubleshooting to avoid exposing sensitive information

For detailed information on secure token handling, see the [Secure Token Handling Guide](secure-token-handling.md).

## Limitations and Considerations

### One-Way Synchronization

- The script only supports Bitbucket to GitHub synchronization
- Changes made directly to GitHub will be overwritten by the next sync from Bitbucket
- This is intentional to maintain Bitbucket as the source of truth

### Large Repositories

- Very large repositories might exceed Bitbucket Pipelines' time or memory limits
- For repositories larger than 1GB, consider:
  - Using a custom runner with increased resources
  - Breaking the initial migration into smaller parts
  - Increasing the pipeline timeout settings

### Branch Protection

- If you have branch protection rules on GitHub, ensure the token has sufficient permissions
- GitHub tokens need the "bypass branch protections" permission to push to protected branches
- Consider temporarily disabling branch protection during initial migration

### Private Dependencies

- If your repository uses private dependencies, additional configuration might be needed
- For private Git submodules, you'll need to configure access tokens for those repositories
- For private package registries, configure appropriate credentials in the pipeline

## Troubleshooting

If you encounter issues during migration or synchronization, check the [Troubleshooting Guide](troubleshooting.md) for common problems and solutions.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
