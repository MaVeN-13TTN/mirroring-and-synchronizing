# Quick Start Guide: Bitbucket to GitHub Migration

This guide provides the fastest way to migrate your Bitbucket repository to GitHub and set up synchronization.

## Prerequisites

- Git installed on your machine
- A repository on Bitbucket
- A GitHub account

## Step 1: Clone This Repository

```bash
git clone https://github.com/YOUR_USERNAME/mirroring-and-synchronizing.git
cd mirroring-and-synchronizing
```

## Step 2: Run the Setup Script

```bash
./setup-mirroring.sh
```

For more detailed output, use:

```bash
./setup-mirroring.sh --verbose
```

For debugging, use:

```bash
./setup-mirroring.sh --debug
```

Follow the interactive prompts to:

1. Specify whether you're using a Bitbucket workspace or personal username
2. For workspace repositories, provide your personal username for authentication
3. Enter your Bitbucket and GitHub repository details
4. Create access tokens
5. Migrate your repository
6. Set up synchronization

The script will create a secure `.env` file to store your configuration and tokens.

## Step 3: Commit the Pipeline Configuration to Bitbucket

After the script completes, you'll need to commit the `bitbucket-pipelines.yml` file to your Bitbucket repository:

```bash
cd /path/to/your/bitbucket/repo
git add bitbucket-pipelines.yml
git commit -m "Add GitHub mirroring pipeline"
git push
```

## Step 4: Set Up Bitbucket Pipelines

1. **Enable Pipelines**:

   - Go to your Bitbucket repository
   - Navigate to Repository settings > Pipelines > Settings
   - Toggle the switch to enable Pipelines

2. **Add Required Repository Variables**:
   - Go to Repository settings > Pipelines > Repository variables
   - Add the following variables:
     - `BITBUCKET_APP_PASSWORD`: Your Bitbucket App Password (mark as "Secured")
     - `BITBUCKET_AUTH_USERNAME`: Your personal Bitbucket username (required for workspace repositories)
     - `GITHUB_TOKEN`: Your GitHub personal access token (mark as "Secured")
     - `GITHUB_REPO_OWNER`: Your GitHub username or organization name
     - `GITHUB_REPO_NAME`: Your GitHub repository name

## Step 5: Verify the Setup

1. Make a small change to your Bitbucket repository
2. Commit and push the change
3. Check your GitHub repository to verify the change was mirrored

## Troubleshooting

If you encounter any issues:

1. Check that your tokens have the correct permissions
2. Verify that Bitbucket Pipelines is enabled
3. Check the pipeline logs for any error messages
4. Refer to the [Troubleshooting Guide](troubleshooting.md) for common issues and solutions

## Next Steps

- Consider setting up SSH keys for enhanced security
- Configure scheduled synchronization for regular updates
- Add branch restrictions if needed

For more detailed instructions, see the [Bitbucket to GitHub Migration Guide](bitbucket-to-github.md).
