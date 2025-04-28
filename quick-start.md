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

## Step 2: Choose Your Setup Method

### Option A: Interactive Bash Script (Recommended)

```bash
./setup-mirroring.sh
```

Follow the interactive prompts to:

1. Enter your Bitbucket and GitHub information
2. Create access tokens
3. Migrate your repository
4. Set up synchronization

The script will create a secure `.env` file to store your configuration and tokens.

### Option B: Python Script (For Automation)

```bash
# Install required dependencies
pip install requests python-dotenv

# Create a .env file (optional)
cat > .env << EOF
BITBUCKET_USERNAME=your_bitbucket_username
BITBUCKET_REPO=your_bitbucket_repo
BITBUCKET_TOKEN=your_bitbucket_token
GITHUB_USERNAME=your_github_username
GITHUB_REPO=your_github_repo
GITHUB_TOKEN=your_github_token
EOF

# Set secure permissions
chmod 600 .env

# Run the migration script (will use .env if available)
python migrate.py --save-env
```

You can also run without a pre-existing `.env` file:

```bash
python migrate.py --bb-user BITBUCKET_USERNAME --bb-repo BITBUCKET_REPO \
                 --gh-user GITHUB_USERNAME --gh-repo GITHUB_REPO \
                 --save-env
```

The script will prompt for any missing information and can save the configuration to a secure `.env` file.

## Step 4: Commit the Pipeline Configuration to Bitbucket

After the script completes, you'll need to commit the `bitbucket-pipelines.yml` file to your Bitbucket repository:

```bash
cd /path/to/your/bitbucket/repo
git add bitbucket-pipelines.yml
git commit -m "Add GitHub mirroring pipeline"
git push
```

## Step 5: Set Up Bitbucket Pipelines

1. **Enable Pipelines**:

   - Go to your Bitbucket repository
   - Navigate to Repository settings > Pipelines > Settings
   - Toggle the switch to enable Pipelines

2. **Add Required Repository Variables**:
   - Go to Repository settings > Pipelines > Repository variables
   - Add the following variables:
     - `BITBUCKET_TOKEN`: Your Bitbucket access token (mark as "Secured")
     - `GITHUB_TOKEN`: Your GitHub personal access token (mark as "Secured")
     - `GITHUB_REPO_OWNER`: Your GitHub username or organization name
     - `GITHUB_REPO_NAME`: Your GitHub repository name

## Step 6: Verify the Setup

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
