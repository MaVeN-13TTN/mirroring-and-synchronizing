# Secure Credential Handling Guide

This guide explains how credentials are securely handled in the Bitbucket to GitHub migration and synchronization project.

## Overview

The project requires authentication credentials (Bitbucket App Password and GitHub personal access token) to perform repository migration and synchronization. These credentials provide access to your repositories and should be handled securely to prevent unauthorized access.

## Token Storage Options

### 1. Environment Variables (.env file)

The recommended approach for local development and one-time migrations is to use a `.env` file with secure permissions:

- **How it works**:

  - Tokens are stored in a local `.env` file
  - The file has restricted permissions (readable only by the owner)
  - Both scripts automatically load variables from this file

- **Security features**:

  - File permissions are set to `600` (readable/writable only by the owner)
  - The `.env` file is included in `.gitignore` to prevent accidental commits
  - Tokens are never displayed in terminal output
  - Input is masked when entering tokens manually

- **Example .env file**:

  ```
  # Bitbucket credentials
  BITBUCKET_APP_PASSWORD=your_bitbucket_app_password_here
  BITBUCKET_USERNAME=your_bitbucket_username_here
  BITBUCKET_REPO=your_bitbucket_repo_name_here
  BITBUCKET_IS_WORKSPACE=true_or_false
  BITBUCKET_AUTH_USERNAME=your_personal_bitbucket_username_here

  # GitHub credentials
  GITHUB_TOKEN=your_github_token_here
  GITHUB_USERNAME=your_github_username_here
  GITHUB_REPO=your_github_repo_name_here
  ```

### 2. Bitbucket Repository Variables

For ongoing synchronization, credentials are stored as repository variables in Bitbucket:

- **How it works**:

  - Credentials are stored as repository variables in Bitbucket
  - The pipeline accesses these variables during execution

- **Security features**:
  - Variables can be marked as "Secured" to mask them in logs
  - Access to repository variables is restricted to repository administrators
  - Credentials are never exposed in the pipeline configuration

## How to Use the .env File

### Bash Script

The `setup-mirroring.sh` script:

1. Checks for an existing `.env` file and loads it if present
2. Prompts for any missing information, including whether you're using a workspace repository
3. For workspace repositories, prompts for your personal Bitbucket username for authentication
4. Creates a new `.env` file with secure permissions if needed
5. Uses masked input for credential entry

## Best Practices

1. **Credential Permissions**:

   - Use repository-specific credentials with minimal required permissions
   - For Bitbucket App Password: Grant repository read/write access and Pipelines read/write/variables permissions
   - For GitHub token: Only grant repository write access
   - For workspace repositories, ensure your personal account has appropriate permissions in the workspace

2. **Credential Rotation**:

   - Regularly rotate your credentials (e.g., every 90 days)
   - Immediately revoke credentials if they are accidentally exposed

3. **Environment Security**:

   - Ensure your local environment is secure
   - Use full-disk encryption if possible
   - Lock your computer when not in use

4. **Avoid Command-Line Exposure**:

   - Don't pass credentials as command-line arguments (they appear in process listings)
   - Use the `.env` file or environment variables instead

5. **Version Control**:
   - Never commit `.env` files or credentials to version control
   - Use `.gitignore` to prevent accidental commits
   - Regularly check for accidentally committed credentials

## Alternative Approaches

If you need even stronger security, consider these alternatives:

1. **System Keychain**:

   - Store credentials in your system's secure keychain
   - Access them programmatically using libraries like `keyring`

2. **OAuth Flow**:

   - Implement a proper OAuth flow for credential acquisition
   - This eliminates direct credential handling

3. **SSH Keys**:
   - Use SSH keys instead of App Passwords or tokens for Git operations
   - Configure SSH agent for secure key management

## Troubleshooting

If you encounter issues with authentication:

1. Verify that your credentials have not expired
2. Check that your credentials have the necessary permissions
3. Ensure the `.env` file has the correct format
4. Check that the file permissions are set correctly

For more help, see the [Troubleshooting Guide](troubleshooting.md).
