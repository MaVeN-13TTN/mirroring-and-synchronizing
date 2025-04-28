# Bitbucket Pipeline Setup Guide

This guide provides detailed instructions for setting up the Bitbucket Pipeline that synchronizes your Bitbucket repository to GitHub.

## Overview

The Bitbucket Pipeline is the key component that enables automatic synchronization from Bitbucket to GitHub. It runs whenever changes are pushed to your Bitbucket repository and mirrors those changes to GitHub.

## Prerequisites

Before setting up the pipeline, ensure you have:

- A repository on Bitbucket (source)
- A repository on GitHub (destination)
- Administrator access to both repositories

## Step 1: Generate Required Credentials

### Bitbucket App Password

1. Log in to Bitbucket
2. Click on your profile picture in the bottom-left corner
3. Select "Personal settings"
4. Go to "App passwords" under "Access management"
5. Click "Create app password"
6. Give it a name (e.g., "GitHub Migration")
7. Select the "Repository" read permission
8. Click "Create"
9. **Important**: Copy and save the App Password immediately as it won't be shown again

### GitHub Personal Access Token

1. Log in to GitHub
2. Click on your profile picture in the top-right corner
3. Select "Settings"
4. Scroll down to "Developer settings" in the left sidebar
5. Select "Personal access tokens" and then "Tokens (classic)"
6. Click "Generate new token" and then "Generate new token (classic)"
7. Give it a name (e.g., "Bitbucket Migration")
8. Select the "repo" scope (this gives full control of repositories)
9. Click "Generate token"
10. **Important**: Copy and save the token immediately as it won't be shown again

## Step 2: Enable Bitbucket Pipelines

1. Navigate to your Bitbucket repository
2. Go to **Repository settings** > **Pipelines** > **Settings**
3. Toggle the switch to enable Pipelines

## Step 3: Add Repository Variables

These variables store your credentials securely and provide information about your repositories:

1. Go to **Repository settings** > **Pipelines** > **Repository variables**
2. Add the following variables:

   | Variable Name          | Value                                     | Secured |
   | ---------------------- | ----------------------------------------- | ------- |
   | BITBUCKET_APP_PASSWORD | Your Bitbucket App Password               | Yes     |
   | GITHUB_TOKEN           | Your GitHub personal access token         | Yes     |
   | GITHUB_REPO_OWNER      | Your GitHub username or organization name | No      |
   | GITHUB_REPO_NAME       | Your GitHub repository name               | No      |

   **Note**: The "Secured" checkbox masks the value in logs for security.

## Step 4: Create the Pipeline Configuration File

1. In your Bitbucket repository, create a file named `bitbucket-pipelines.yml` at the root level
2. Add the following content:

```yaml
# Bitbucket Pipelines configuration for mirroring to GitHub
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
          - git clone --mirror https://x-token-auth:${BITBUCKET_APP_PASSWORD}@bitbucket.org/${BITBUCKET_REPO_OWNER}/${BITBUCKET_REPO_SLUG}.git repo
          - cd repo

          # Push to GitHub with mirror option
          # This ensures GitHub repository is an exact copy of Bitbucket
          - echo "Pushing to GitHub repository..."
          - git push --mirror https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}.git

          # Clean up
          - echo "Synchronization completed successfully!"

  # Also run on schedule (daily at midnight)
  schedules:
    - cron: "0 0 * * *"
      branches:
        include:
          - main # or your default branch
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
          - git clone --mirror https://x-token-auth:${BITBUCKET_APP_PASSWORD}@bitbucket.org/${BITBUCKET_REPO_OWNER}/${BITBUCKET_REPO_SLUG}.git repo
          - cd repo
          - git push --mirror https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}.git
          - echo "Scheduled synchronization completed successfully!"
```

**Note**: You don't need to replace any placeholders in this file. Bitbucket automatically provides the variables `BITBUCKET_REPO_OWNER` and `BITBUCKET_REPO_SLUG`, and the other variables are set in the repository variables.

## Step 5: Commit and Push the Pipeline Configuration

1. Commit the `bitbucket-pipelines.yml` file to your repository
2. Push the changes to Bitbucket
3. This will trigger the pipeline for the first time

## Step 6: Verify the Pipeline

1. Go to the "Pipelines" section in your Bitbucket repository
2. Check that the pipeline ran successfully
3. Verify that your GitHub repository has been updated with the changes

## Understanding the Pipeline Configuration

### Key Components

1. **Image**: `alpine/git:latest` - A lightweight Docker image with Git installed
2. **Clone Disabled**: `clone: enabled: false` - We disable the default clone because we'll do a mirror clone
3. **Mirror Clone**: `git clone --mirror` - Clones all branches, tags, and history
4. **Mirror Push**: `git push --mirror` - Pushes all branches, tags, and history
5. **Scheduled Runs**: The pipeline also runs daily to ensure synchronization even without commits

### Environment Variables

The pipeline uses several environment variables:

1. **Provided by Bitbucket**:

   - `BITBUCKET_REPO_OWNER`: Your Bitbucket username or workspace
   - `BITBUCKET_REPO_SLUG`: Your Bitbucket repository name

2. **Set by You**:
   - `BITBUCKET_APP_PASSWORD`: Your Bitbucket App Password
   - `GITHUB_TOKEN`: Your GitHub personal access token
   - `GITHUB_REPO_OWNER`: Your GitHub username or organization name
   - `GITHUB_REPO_NAME`: Your GitHub repository name

## Troubleshooting

### Pipeline Fails with Authentication Error

- Verify that your App Password and token are correct and have not expired
- Check that the credentials have the necessary permissions
- Ensure the repository variables are set correctly

### Pipeline Succeeds but Repository Is Not Updated

- Check if the GitHub repository exists and is accessible
- Verify that your GitHub token has write access to the repository
- Check for any branch protection rules that might prevent force pushes

### Large Repository Issues

- If your repository is very large, the pipeline might time out
- Consider using a custom pipeline with a longer timeout or breaking the migration into smaller parts

## Security Considerations

- Use repository-specific App Passwords and tokens with minimal permissions
- Store credentials securely as repository variables with the "Secured" option
- Regularly rotate your App Passwords and tokens
- Consider using SSH keys instead of App Passwords/tokens for enhanced security (see the [Bitbucket to GitHub Migration Guide](bitbucket-to-github.md) for instructions)

## Next Steps

After setting up the pipeline, you might want to:

1. Configure branch restrictions in GitHub to prevent direct pushes
2. Set up additional pipelines for testing or deployment
3. Configure notifications for pipeline failures

For more information, see the [Bitbucket to GitHub Migration Guide](bitbucket-to-github.md) and the [Troubleshooting Guide](troubleshooting.md).
