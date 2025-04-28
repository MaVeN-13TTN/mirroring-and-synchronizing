#!/bin/bash

# Script to help set up repository migration and mirroring from Bitbucket to GitHub

echo "Bitbucket to GitHub Migration and Synchronization Helper"
echo "======================================================="
echo

# Function to load environment variables from .env file
load_env() {
    if [ -f .env ]; then
        echo "Loading configuration from .env file..."
        # Export all variables from .env file
        export $(grep -v '^#' .env | xargs)
        return 0
    fi
    return 1
}

# Function to create .env file with secure permissions
create_env_file() {
    echo "Creating .env file with secure permissions..."
    touch .env
    chmod 600 .env

    # Add tokens to .env file
    cat > .env << EOF
# Environment variables for Bitbucket to GitHub migration
# Created on $(date)

# Bitbucket credentials
BITBUCKET_APP_PASSWORD=$bb_token
BITBUCKET_USERNAME=$bb_username
BITBUCKET_REPO=$bb_repo

# GitHub credentials
GITHUB_TOKEN=$gh_token
GITHUB_USERNAME=$gh_username
GITHUB_REPO=$gh_repo

# Optional settings
GITHUB_PRIVATE=true
EOF

    echo "Configuration saved to .env file with secure permissions."
    echo "For security, avoid committing this file to version control."
}

# Try to load from .env file first
if load_env; then
    # Use values from .env if available
    bb_username=${BITBUCKET_USERNAME:-$bb_username}
    bb_repo=${BITBUCKET_REPO:-$bb_repo}
    bb_token=${BITBUCKET_APP_PASSWORD:-$bb_token}
    gh_username=${GITHUB_USERNAME:-$gh_username}
    gh_repo=${GITHUB_REPO:-$gh_repo}
    gh_token=${GITHUB_TOKEN:-$gh_token}

    # Confirm loaded values
    echo "Using configuration from .env file."
    echo "Bitbucket repository: $bb_username/$bb_repo"
    echo "GitHub repository: $gh_username/$gh_repo"

    # Ask if user wants to proceed with these values
    read -p "Do you want to proceed with these values? (y/n): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "Let's set up new values then."
        # Clear variables to force prompting
        bb_username=""
        bb_repo=""
        bb_token=""
        gh_username=""
        gh_repo=""
        gh_token=""
    fi
fi

# Collect Bitbucket information if not already set
if [ -z "$bb_username" ]; then
    read -p "Enter your Bitbucket workspace/username: " bb_username
fi

if [ -z "$bb_repo" ]; then
    read -p "Enter your Bitbucket repository name: " bb_repo
fi

# Collect GitHub information if not already set
if [ -z "$gh_username" ]; then
    read -p "Enter your GitHub username: " gh_username
fi

if [ -z "$gh_repo" ]; then
    read -p "Enter your GitHub repository name (will be created if it doesn't exist): " gh_repo
fi

# Step 1: Generate Bitbucket App Password if not already set
if [ -z "$bb_token" ]; then
    echo
    echo "Step 1: Generate a Bitbucket App Password"
    echo "----------------------------------------"
    echo "1. Go to Bitbucket and log in to your account"
    echo "2. Click on your profile picture in the bottom left and select 'Personal settings'"
    echo "3. Go to 'App passwords' under 'Access management'"
    echo "4. Click 'Create app password'"
    echo "5. Give it a name (e.g., 'Migration to GitHub')"
    echo "6. Select the 'Repository' read permission"
    echo "7. Click 'Create'"
    echo "8. Copy the generated App Password"
    read -sp "Enter your Bitbucket App Password: " bb_token
    echo
fi

# Step 2: Generate GitHub personal access token if not already set
if [ -z "$gh_token" ]; then
    echo
    echo "Step 2: Generate a GitHub personal access token"
    echo "---------------------------------------------"
    echo "1. Go to GitHub and log in to your account"
    echo "2. Click on your profile picture in the top right and select 'Settings'"
    echo "3. Scroll down to 'Developer settings' in the left sidebar"
    echo "4. Select 'Personal access tokens' and then 'Tokens (classic)'"
    echo "5. Click 'Generate new token' and then 'Generate new token (classic)'"
    echo "6. Give it a name (e.g., 'Bitbucket Migration')"
    echo "7. Select the 'repo' scope"
    echo "8. Click 'Generate token'"
    echo "9. Copy the generated token"
    read -sp "Enter your GitHub personal access token: " gh_token
    echo
fi

# Save configuration to .env file if it doesn't exist or user entered new values
if [ ! -f .env ] || [[ ! $confirm =~ ^[Yy]$ ]]; then
    create_env_file
fi

# Step 3: Create GitHub repository if it doesn't exist
echo "Step 3: Creating GitHub repository (if it doesn't exist)"
echo "-----------------------------------------------------"
echo "Checking if GitHub repository exists..."

# Check if GitHub repository exists
repo_check=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $gh_token" "https://api.github.com/repos/$gh_username/$gh_repo")

if [ "$repo_check" == "404" ]; then
    echo "Repository doesn't exist. Creating new repository on GitHub..."

    # Create GitHub repository
    curl -X POST -H "Authorization: token $gh_token" \
         -d "{\"name\":\"$gh_repo\", \"private\":true}" \
         "https://api.github.com/user/repos"

    echo "GitHub repository created successfully!"
else
    echo "GitHub repository already exists."
fi
echo

# Step 4: Clone Bitbucket repository and push to GitHub
echo "Step 4: Migrating repository from Bitbucket to GitHub"
echo "--------------------------------------------------"
echo "Cloning Bitbucket repository..."

# Create a temporary directory
temp_dir=$(mktemp -d)
cd "$temp_dir"

# Clone Bitbucket repository with mirror option
git clone --mirror "https://x-token-auth:$bb_token@bitbucket.org/$bb_username/$bb_repo.git" repo
cd repo

# Push to GitHub
echo "Pushing to GitHub repository..."
git push --mirror "https://x-access-token:$gh_token@github.com/$gh_username/$gh_repo.git"

# Clean up
cd ../..
rm -rf "$temp_dir"

echo "Initial migration completed successfully!"
echo

# Step 5: Create bitbucket-pipelines.yml for ongoing synchronization
echo "Step 5: Setting up ongoing synchronization from Bitbucket to GitHub"
echo "----------------------------------------------------------------"

# Define the project directory path
project_dir="/home/ndungu-kinyanjui/Desktop/Solavise-DevOps/mirroring-and-synchronizing"
echo "Creating bitbucket-pipelines.yml file in the project directory..."

# Create the file in the project directory
cat > "$project_dir/bitbucket-pipelines.yml" << EOF
pipelines:
  default:
    - step:
        name: Mirror to GitHub
        image: alpine/git:latest
        clone:
          enabled: false
        script:
          - git clone --mirror https://x-token-auth:\${BITBUCKET_APP_PASSWORD}@bitbucket.org/$bb_username/$bb_repo.git repo
          - cd repo
          - git push --mirror https://x-access-token:\${GITHUB_TOKEN}@github.com/$gh_username/$gh_repo.git
EOF

echo "bitbucket-pipelines.yml created successfully in $project_dir!"
echo

# Step 6: Instructions for setting up repository variables
echo "Step 6: Set up repository variables in Bitbucket"
echo "---------------------------------------------"
echo "1. Go to your Bitbucket repository"
echo "2. Navigate to Repository settings > Pipelines > Repository variables"
echo "3. Add a variable named BITBUCKET_APP_PASSWORD with your Bitbucket App Password"
echo "4. Add a variable named GITHUB_TOKEN with your GitHub personal access token"
echo "5. Make sure to check 'Secured' for both variables"
echo "6. Enable Pipelines in Repository settings > Pipelines > Settings"
echo

echo "Setup completed! Your repository has been migrated and synchronization is configured."
echo "To activate the synchronization:"
echo "1. Commit and push the bitbucket-pipelines.yml file to your Bitbucket repository"
echo "2. Any future changes to your Bitbucket repository will be automatically mirrored to GitHub"
echo
echo "For more details, see the documentation in bitbucket-to-github.md"
