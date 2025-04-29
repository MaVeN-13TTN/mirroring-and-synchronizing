#!/bin/bash

# Script to help set up repository migration and mirroring from Bitbucket to GitHub

# Enable debugging if requested
DEBUG=false
VERBOSE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            DEBUG=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Set up debugging if enabled
if [ "$DEBUG" = true ]; then
    set -x  # Print commands and their arguments as they are executed
fi

# Function to print verbose messages
verbose_log() {
    if [ "$VERBOSE" = true ] || [ "$DEBUG" = true ]; then
        echo "[VERBOSE] $1"
    fi
}

# Function to print error messages and exit
error_exit() {
    echo "[ERROR] $1" >&2
    exit 1
}

echo "Bitbucket to GitHub Migration and Synchronization Helper"
echo "======================================================="
echo
echo "Run with --debug for detailed debugging output"
echo "Run with --verbose for additional information"
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
BITBUCKET_IS_WORKSPACE=${bb_is_workspace:-false}
BITBUCKET_AUTH_USERNAME=${bb_auth_username:-$bb_username}

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
    bb_is_workspace=${BITBUCKET_IS_WORKSPACE:-false}
    bb_auth_username=${BITBUCKET_AUTH_USERNAME:-$bb_username}
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
    echo "Bitbucket repositories can be under a personal username or a workspace/organization."
    read -p "Enter your Bitbucket workspace or username: " bb_username

    # Ask for clarification on whether this is a workspace or username
    read -p "Is '$bb_username' a workspace/organization (w) or a personal username (u)? (w/u): " bb_account_type
    if [[ "$bb_account_type" =~ ^[Ww]$ ]]; then
        bb_is_workspace=true
        echo "Using '$bb_username' as a Bitbucket workspace."

        # For workspace repositories, we need the personal username for authentication
        read -p "Enter your personal Bitbucket username (for authentication): " bb_auth_username
        echo "Using '$bb_auth_username' for authentication with Bitbucket."
    else
        bb_is_workspace=false
        echo "Using '$bb_username' as a personal Bitbucket username."
        # For personal repositories, the username is also used for authentication
        bb_auth_username=$bb_username
    fi
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

# Test Bitbucket authentication before proceeding
echo "Testing Bitbucket authentication..."
if [ "$bb_is_workspace" = true ]; then
    verbose_log "Using workspace repository with personal authentication"
    verbose_log "Authentication username: $bb_auth_username, Repository path: $bb_username/$bb_repo"
    auth_test=$(curl -s -o /dev/null -w "%{http_code}" -u "$bb_auth_username:$bb_token" "https://api.bitbucket.org/2.0/repositories/$bb_username/$bb_repo")
else
    verbose_log "Using personal account authentication"
    verbose_log "Username: $bb_username, Repository path: $bb_username/$bb_repo"
    auth_test=$(curl -s -o /dev/null -w "%{http_code}" -u "$bb_username:$bb_token" "https://api.bitbucket.org/2.0/repositories/$bb_username/$bb_repo")
fi

if [ "$auth_test" = "200" ] || [ "$auth_test" = "201" ]; then
    echo "Bitbucket authentication successful!"
else
    error_exit "Bitbucket authentication failed with status code $auth_test. Please check your credentials."
fi

echo "Cloning Bitbucket repository..."

# Create a temporary directory
temp_dir=$(mktemp -d)
cd "$temp_dir" || error_exit "Failed to create and navigate to temporary directory"

# Prepare the clone URL based on whether it's a workspace or personal account
if [ "$bb_is_workspace" = true ]; then
    # For workspace repositories with personal authentication
    clone_url="https://$bb_auth_username:$bb_token@bitbucket.org/$bb_username/$bb_repo.git"
    verbose_log "Using workspace URL format with personal authentication: ${clone_url//$bb_token/****}"
else
    # For personal repositories
    clone_url="https://$bb_username:$bb_token@bitbucket.org/$bb_username/$bb_repo.git"
    verbose_log "Using personal URL format: ${clone_url//$bb_token/****}"
fi

# Clone Bitbucket repository with mirror option
echo "Cloning from Bitbucket using: ${clone_url//$bb_token/****}"
if ! git clone --mirror "$clone_url" repo; then
    error_exit "Failed to clone Bitbucket repository. Please check your credentials and repository name."
fi

cd repo || error_exit "Failed to navigate to cloned repository"

# Test GitHub authentication
echo "Testing GitHub authentication..."
github_auth_test=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $gh_token" "https://api.github.com/user")
if [ "$github_auth_test" = "200" ] || [ "$github_auth_test" = "201" ]; then
    echo "GitHub authentication successful!"
else
    error_exit "GitHub authentication failed with status code $github_auth_test. Please check your token."
fi

# Push to GitHub
echo "Pushing to GitHub repository..."
github_url="https://x-access-token:$gh_token@github.com/$gh_username/$gh_repo.git"
verbose_log "Using GitHub URL: ${github_url//$gh_token/****}"

if ! git push --mirror "$github_url"; then
    error_exit "Failed to push to GitHub repository. Please check your GitHub credentials and repository name."
fi

# Clean up
cd ../.. || true
rm -rf "$temp_dir"

echo "Initial migration completed successfully!"
echo

# Step 5: Create bitbucket-pipelines.yml for ongoing synchronization
echo "Step 5: Setting up ongoing synchronization from Bitbucket to GitHub"
echo "----------------------------------------------------------------"

# Define the Bitbucket repository path
bitbucket_repo_path="/home/ndungu-kinyanjui/Desktop/Solavise-DevOps/mirror-mirror"

# Function to verify if a directory is a valid Bitbucket repository
verify_bitbucket_repo() {
    local repo_path=$1

    # Check if directory exists
    if [ ! -d "$repo_path" ]; then
        verbose_log "Directory does not exist: $repo_path"
        return 1
    fi

    # Check if it's a git repository
    if [ ! -d "$repo_path/.git" ]; then
        verbose_log "Not a git repository: $repo_path"
        return 2
    fi

    # Navigate to the directory to check git remote
    pushd "$repo_path" > /dev/null

    # Check if the remote URL contains bitbucket.org
    local remote_url=$(git remote get-url origin 2>/dev/null)
    verbose_log "Remote URL: $remote_url"

    if [[ ! "$remote_url" == *"bitbucket.org"* ]]; then
        verbose_log "Remote URL does not contain bitbucket.org"
        popd > /dev/null
        return 3
    fi

    # For workspace repositories, the URL format might be different
    # We'll check if either the workspace name or the repo name is in the URL
    if [[ ! "$remote_url" == *"$bb_repo"* ]]; then
        verbose_log "Remote URL does not contain the repository name: $bb_repo"
        popd > /dev/null
        return 4
    fi

    # If we're using a workspace, we need to be more flexible in our check
    if [ "$bb_is_workspace" = true ]; then
        if [[ ! "$remote_url" == *"$bb_username"* ]] && [[ ! "$remote_url" == *"bitbucket.org/$bb_username"* ]]; then
            verbose_log "Remote URL does not contain the workspace name: $bb_username"
            popd > /dev/null
            return 5
        fi
    else
        # For personal accounts, we expect the username to be in the URL
        if [[ ! "$remote_url" == *"$bb_username"* ]]; then
            verbose_log "Remote URL does not contain the username: $bb_username"
            popd > /dev/null
            return 6
        fi
    fi

    verbose_log "Repository verification successful"
    popd > /dev/null
    return 0
}

# Check if the repository directory exists and is valid
echo "Verifying Bitbucket repository at $bitbucket_repo_path..."
verify_bitbucket_repo "$bitbucket_repo_path"
repo_check_result=$?

if [ $repo_check_result -ne 0 ]; then
    echo "Bitbucket repository not found or invalid at $bitbucket_repo_path"
    echo "Please enter the path to your cloned Bitbucket repository:"
    read -p "Repository path: " bitbucket_repo_path

    verify_bitbucket_repo "$bitbucket_repo_path"
    repo_check_result=$?

    if [ $repo_check_result -ne 0 ]; then
        case $repo_check_result in
            1) echo "Error: Directory does not exist." ;;
            2) echo "Error: Not a git repository." ;;
            3) echo "Error: Not a Bitbucket repository (remote URL doesn't contain bitbucket.org)." ;;
            4) echo "Error: Repository name mismatch. Expected: $bb_repo" ;;
            5|6) echo "Error: Username/workspace mismatch. Expected: $bb_username" ;;
            *) echo "Error: Unknown verification error (code: $repo_check_result)." ;;
        esac

        # Provide helpful instructions based on the error
        if [ "$bb_is_workspace" = true ]; then
            echo "Please clone the repository first with:"
            echo "git clone https://$bb_auth_username:<app_password>@bitbucket.org/$bb_username/$bb_repo.git"
            echo "Note: $bb_username is a workspace, and $bb_auth_username is your personal username for authentication."
        else
            echo "Please clone the repository first with:"
            echo "git clone https://$bb_username:<app_password>@bitbucket.org/$bb_username/$bb_repo.git"
        fi

        error_exit "Repository verification failed. Please clone the repository and try again."
    fi
fi

echo "Valid Bitbucket repository found at $bitbucket_repo_path"

echo "Creating bitbucket-pipelines.yml file in the Bitbucket repository..."

# Navigate to the Bitbucket repository
cd "$bitbucket_repo_path"

# Create the file in the repository
if [ "$bb_is_workspace" = true ]; then
    # For workspace repositories, use BITBUCKET_REPO_OWNER and BITBUCKET_REPO_SLUG
    cat > "bitbucket-pipelines.yml" << EOF
pipelines:
  default:
    - step:
        name: Mirror to GitHub
        image: alpine/git:latest
        clone:
          enabled: false
        script:
          # Set Git configuration
          - git config --global user.name "Bitbucket Pipeline"
          - git config --global user.email "noreply@bitbucket.org"

          # Clone the Bitbucket repository with mirror option
          # This preserves all branches, tags, and history
          - echo "Cloning Bitbucket repository..."
          - git clone --mirror https://$bb_auth_username:\${BITBUCKET_APP_PASSWORD}@bitbucket.org/\${BITBUCKET_REPO_OWNER}/\${BITBUCKET_REPO_SLUG}.git repo
          - cd repo

          # Push to GitHub with mirror option
          # This ensures GitHub repository is an exact copy of Bitbucket
          - echo "Pushing to GitHub repository..."
          - git push --mirror https://x-access-token:\${GITHUB_TOKEN}@github.com/$gh_username/$gh_repo.git

          # Clean up
          - echo "Synchronization completed successfully!"

  # Also run on schedule (daily at midnight)
  schedules:
    - cron: '0 0 * * *'
      branches:
        include:
          - main  # or your default branch
      name: Daily Sync
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
          - git clone --mirror https://$bb_auth_username:\${BITBUCKET_APP_PASSWORD}@bitbucket.org/\${BITBUCKET_REPO_OWNER}/\${BITBUCKET_REPO_SLUG}.git repo
          - cd repo
          - git push --mirror https://x-access-token:\${GITHUB_TOKEN}@github.com/$gh_username/$gh_repo.git
          - echo "Scheduled synchronization completed successfully!"
EOF
else
    # For personal repositories, use the username directly
    cat > "bitbucket-pipelines.yml" << EOF
pipelines:
  default:
    - step:
        name: Mirror to GitHub
        image: alpine/git:latest
        clone:
          enabled: false
        script:
          # Set Git configuration
          - git config --global user.name "Bitbucket Pipeline"
          - git config --global user.email "noreply@bitbucket.org"

          # Clone the Bitbucket repository with mirror option
          # This preserves all branches, tags, and history
          - echo "Cloning Bitbucket repository..."
          - git clone --mirror https://$bb_username:\${BITBUCKET_APP_PASSWORD}@bitbucket.org/$bb_username/$bb_repo.git repo
          - cd repo

          # Push to GitHub with mirror option
          # This ensures GitHub repository is an exact copy of Bitbucket
          - echo "Pushing to GitHub repository..."
          - git push --mirror https://x-access-token:\${GITHUB_TOKEN}@github.com/$gh_username/$gh_repo.git

          # Clean up
          - echo "Synchronization completed successfully!"

  # Also run on schedule (daily at midnight)
  schedules:
    - cron: '0 0 * * *'
      branches:
        include:
          - main  # or your default branch
      name: Daily Sync
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
          - git clone --mirror https://$bb_username:\${BITBUCKET_APP_PASSWORD}@bitbucket.org/$bb_username/$bb_repo.git repo
          - cd repo
          - git push --mirror https://x-access-token:\${GITHUB_TOKEN}@github.com/$gh_username/$gh_repo.git
          - echo "Scheduled synchronization completed successfully!"
EOF
fi

echo "bitbucket-pipelines.yml created successfully in the Bitbucket repository!"

# Commit and push the changes
echo "Committing and pushing the changes to Bitbucket..."
git add bitbucket-pipelines.yml
git commit -m "Add Bitbucket Pipelines configuration for GitHub mirroring"
git push

echo "Successfully pushed bitbucket-pipelines.yml to the Bitbucket repository!"
echo

# Step 6: Instructions for setting up repository variables
echo "Step 6: Set up repository variables in Bitbucket"
echo "---------------------------------------------"
echo "1. Go to your Bitbucket repository"
echo "2. Navigate to Repository settings > Pipelines > Repository variables"

if [ "$bb_is_workspace" = true ]; then
    echo "3. Add the following variables:"
    echo "   - BITBUCKET_APP_PASSWORD: Your Bitbucket App Password (mark as 'Secured')"
    echo "   - GITHUB_TOKEN: Your GitHub personal access token (mark as 'Secured')"
    echo "   - BITBUCKET_AUTH_USERNAME: Your personal Bitbucket username ($bb_auth_username) (NOT secured)"
    echo "   Note: Bitbucket automatically provides BITBUCKET_REPO_OWNER and BITBUCKET_REPO_SLUG variables"
else
    echo "3. Add the following variables:"
    echo "   - BITBUCKET_APP_PASSWORD: Your Bitbucket App Password (mark as 'Secured')"
    echo "   - GITHUB_TOKEN: Your GitHub personal access token (mark as 'Secured')"
fi

echo "4. Enable Pipelines in Repository settings > Pipelines > Settings"
echo
echo "For debugging purposes, you can also add:"
echo "- Set DEBUG=true to enable detailed logging in the pipeline"
echo

echo "Setup completed! Your repository has been migrated and synchronization is configured."
echo "The bitbucket-pipelines.yml file has been committed and pushed to your Bitbucket repository."
echo "Any future changes to your Bitbucket repository will be automatically mirrored to GitHub."
echo
echo "For more details, see the documentation in bitbucket-to-github.md"
