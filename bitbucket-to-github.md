# Migrating and Synchronizing from Bitbucket to GitHub

This guide provides comprehensive instructions for migrating a repository from Bitbucket to GitHub and setting up automatic synchronization to keep both repositories in sync.

## Overview

The process consists of two main parts:

1. **Initial Migration**: One-time transfer of all code, branches, tags, and history from Bitbucket to GitHub
2. **Ongoing Synchronization**: Automatic mirroring of changes from Bitbucket to GitHub whenever changes are pushed to Bitbucket

## Prerequisites

- A repository on Bitbucket (source)
- Administrator access to Bitbucket repository
- A GitHub account with permission to create repositories
- Git installed on your local machine (for manual migration)

## Part 1: Initial Migration

### Option A: Using the Setup Script (Recommended)

The easiest way to migrate your repository is to use the provided setup script:

1. Run the `setup-mirroring.sh` script in this repository
2. Follow the interactive prompts to:
   - Enter your Bitbucket and GitHub credentials
   - Generate necessary access tokens
   - Create the GitHub repository (if it doesn't exist)
   - Perform the initial migration
   - Set up ongoing synchronization

### Option B: Manual Migration

If you prefer to perform the migration manually, follow these steps:

#### Step 1: Create a GitHub Repository

1. Log in to GitHub
2. Click the "+" icon in the top-right corner and select "New repository"
3. Enter a name for your repository (ideally the same as your Bitbucket repository)
4. Choose whether the repository should be public or private
5. Do not initialize the repository with a README, .gitignore, or license
6. Click "Create repository"

#### Step 2: Generate Access Tokens

##### Bitbucket Access Token

1. Log in to Bitbucket
2. Click on your profile picture in the bottom-left corner
3. Select "Personal settings"
4. Go to "App passwords" under "Access management"
5. Click "Create app password"
6. Give it a name (e.g., "GitHub Migration")
7. Select the "Repository" read permission
8. Click "Create"
9. Copy and save the token securely

##### GitHub Personal Access Token

1. Log in to GitHub
2. Click on your profile picture in the top-right corner
3. Select "Settings"
4. Scroll down to "Developer settings" in the left sidebar
5. Select "Personal access tokens" and then "Tokens (classic)"
6. Click "Generate new token" and then "Generate new token (classic)"
7. Give it a name (e.g., "Bitbucket Migration")
8. Select the "repo" scope
9. Click "Generate token"
10. Copy and save the token securely

#### Step 3: Perform the Migration

Open a terminal and run the following commands:

```bash
# Create a temporary directory
mkdir temp_migration
cd temp_migration

# Clone the Bitbucket repository with mirror option
git clone --mirror https://x-token-auth:YOUR_BITBUCKET_TOKEN@bitbucket.org/YOUR_BITBUCKET_USERNAME/YOUR_REPO_NAME.git

# Navigate into the cloned repository
cd YOUR_REPO_NAME.git

# Push to GitHub with mirror option
git push --mirror https://x-access-token:YOUR_GITHUB_TOKEN@github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME.git

# Clean up
cd ../..
rm -rf temp_migration
```

Replace:

- `YOUR_BITBUCKET_TOKEN` with your Bitbucket access token
- `YOUR_BITBUCKET_USERNAME` with your Bitbucket username
- `YOUR_REPO_NAME` with your repository name
- `YOUR_GITHUB_TOKEN` with your GitHub personal access token
- `YOUR_GITHUB_USERNAME` with your GitHub username

## Part 2: Setting Up Ongoing Synchronization

After the initial migration, you'll want to set up automatic synchronization to keep your GitHub repository updated whenever changes are pushed to Bitbucket.

### Step 1: Set Up Bitbucket Pipelines

1. Navigate to your Bitbucket repository
2. Go to **Repository settings** > **Pipelines** > **Settings**
3. Toggle the switch to enable Pipelines

### Step 2: Add Repository Variables in Bitbucket

1. Go to **Repository settings** > **Pipelines** > **Repository variables**
2. Add a variable named `BITBUCKET_TOKEN` with the value of your Bitbucket access token
3. Add a variable named `GITHUB_TOKEN` with the value of your GitHub personal access token
4. Make sure to check "Secured" for both variables to protect your tokens

### Step 3: Create Bitbucket Pipelines Configuration

Create a file named `bitbucket-pipelines.yml` in the root of your Bitbucket repository with the following content:

```yaml
pipelines:
  default:
    - step:
        name: Mirror to GitHub
        image: alpine/git:latest
        clone:
          enabled: false
        script:
          - git clone --mirror https://x-token-auth:${BITBUCKET_TOKEN}@bitbucket.org/YOUR_BITBUCKET_USERNAME/YOUR_REPO_NAME.git repo
          - cd repo
          - git push --mirror https://x-access-token:${GITHUB_TOKEN}@github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME.git
```

Replace:

- `YOUR_BITBUCKET_USERNAME` with your Bitbucket username
- `YOUR_REPO_NAME` with your repository name
- `YOUR_GITHUB_USERNAME` with your GitHub username

### Step 4: Commit and Push the Pipeline Configuration

1. Commit the `bitbucket-pipelines.yml` file to your Bitbucket repository
2. Push the changes to trigger the pipeline for the first time

## Verification and Testing

To verify that the synchronization is working:

1. Make a small change to your Bitbucket repository (e.g., update the README)
2. Commit and push the change
3. Go to your Bitbucket repository's Pipelines section to check if the pipeline ran successfully
4. Check your GitHub repository to verify that the change was mirrored

## Alternative: Using SSH Keys Instead of Tokens

For enhanced security, you can use SSH keys instead of access tokens:

### Step 1: Generate SSH Keys in Bitbucket

1. Navigate to your Bitbucket repository
2. Go to **Repository settings** > **Pipelines** > **SSH keys**
3. Click **Generate keys**
4. Copy the generated public key to your clipboard

### Step 2: Add the SSH Key to GitHub

1. Navigate to your GitHub repository
2. Go to **Settings** > **Deploy keys**
3. Click **Add deploy key**
4. Paste the public key from Bitbucket
5. Give it a descriptive title (e.g., "Bitbucket Pipeline Mirror")
6. Check the **Allow write access** option
7. Click **Add key**

### Step 3: Configure Known Hosts in Bitbucket

1. In your Bitbucket repository, go to **Repository settings** > **Pipelines** > **SSH keys**
2. Under **Known hosts**, click **Add host**
3. Enter `github.com` as the Host name
4. Click **Fetch** to retrieve GitHub's public key
5. Click **Add host**

### Step 4: Update the Pipelines Configuration

Update your `bitbucket-pipelines.yml` file to use SSH instead of HTTPS:

```yaml
pipelines:
  default:
    - step:
        name: Mirror to GitHub
        image: alpine/git:latest
        script:
          - git clone --mirror https://x-token-auth:${BITBUCKET_TOKEN}@bitbucket.org/YOUR_BITBUCKET_USERNAME/YOUR_REPO_NAME.git repo
          - cd repo
          - git remote add github git@github.com:YOUR_GITHUB_USERNAME/YOUR_REPO_NAME.git
          - git push --mirror github
```

## Troubleshooting

### Pipeline Fails with Authentication Error

- Verify that your tokens are correct and have not expired
- Check that the tokens have the necessary permissions
- Ensure the repository paths in the pipeline configuration are correct

### Pipeline Succeeds but Repository Is Not Updated

- Check if the GitHub repository exists and is accessible
- Verify that the deploy key has write access to the GitHub repository
- Check for any branch protection rules that might prevent force pushes

### Large Repository Issues

- If your repository is very large, the pipeline might time out
- Consider using a custom pipeline with a longer timeout or breaking the migration into smaller parts

## Security Considerations

- Use repository-specific access tokens with minimal permissions
- Store tokens securely as repository variables
- Regularly rotate your access tokens
- Consider using SSH keys instead of tokens for enhanced security
- Remove tokens and keys when they are no longer needed
