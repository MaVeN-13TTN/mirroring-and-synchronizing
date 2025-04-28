# Secure Token Handling Guide

This guide explains how tokens are securely handled in the Bitbucket to GitHub migration and synchronization project.

## Overview

The project requires authentication tokens for both Bitbucket and GitHub to perform repository migration and synchronization. These tokens provide access to your repositories and should be handled securely to prevent unauthorized access.

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
  BITBUCKET_TOKEN=your_bitbucket_token_here
  BITBUCKET_USERNAME=your_bitbucket_username_here
  BITBUCKET_REPO=your_bitbucket_repo_name_here

  # GitHub credentials
  GITHUB_TOKEN=your_github_token_here
  GITHUB_USERNAME=your_github_username_here
  GITHUB_REPO=your_github_repo_name_here
  ```

### 2. Bitbucket Repository Variables

For ongoing synchronization, tokens are stored as repository variables in Bitbucket:

- **How it works**:
  - Tokens are stored as repository variables in Bitbucket
  - The pipeline accesses these variables during execution

- **Security features**:
  - Variables can be marked as "Secured" to mask them in logs
  - Access to repository variables is restricted to repository administrators
  - Tokens are never exposed in the pipeline configuration

## How to Use the .env File

### Bash Script

The `setup-mirroring.sh` script:
1. Checks for an existing `.env` file and loads it if present
2. Prompts for any missing information
3. Creates a new `.env` file with secure permissions if needed
4. Uses masked input for token entry

### Python Script

The `migrate.py` script:
1. Attempts to load the `.env` file using python-dotenv
2. Falls back to command-line arguments if provided
3. Prompts for any missing information using masked input
4. Can save configuration to a `.env` file with secure permissions

## Best Practices

1. **Token Permissions**:
   - Use repository-specific tokens with minimal required permissions
   - For Bitbucket: Only grant repository read access
   - For GitHub: Only grant repository write access

2. **Token Rotation**:
   - Regularly rotate your tokens (e.g., every 90 days)
   - Immediately revoke tokens if they are accidentally exposed

3. **Environment Security**:
   - Ensure your local environment is secure
   - Use full-disk encryption if possible
   - Lock your computer when not in use

4. **Avoid Command-Line Exposure**:
   - Don't pass tokens as command-line arguments (they appear in process listings)
   - Use the `.env` file or environment variables instead

5. **Version Control**:
   - Never commit `.env` files or tokens to version control
   - Use `.gitignore` to prevent accidental commits
   - Regularly check for accidentally committed tokens

## Alternative Approaches

If you need even stronger security, consider these alternatives:

1. **System Keychain**:
   - Store tokens in your system's secure keychain
   - Access them programmatically using libraries like `keyring`

2. **OAuth Flow**:
   - Implement a proper OAuth flow for token acquisition
   - This eliminates direct token handling

3. **SSH Keys**:
   - Use SSH keys instead of tokens for Git operations
   - Configure SSH agent for secure key management

## Troubleshooting

If you encounter issues with token authentication:

1. Verify that your tokens have not expired
2. Check that your tokens have the necessary permissions
3. Ensure the `.env` file has the correct format
4. Check that the file permissions are set correctly

For more help, see the [Troubleshooting Guide](troubleshooting.md).
