# Python Migration Script

This document provides detailed information about using the Python script (`migrate.py`) for migrating repositories from Bitbucket to GitHub and setting up synchronization.

## Overview

The Python migration script offers a programmatic alternative to the interactive bash script. It's particularly useful for:

- Automating the migration process
- Integrating with other Python applications
- Migrating multiple repositories in batch
- Cross-platform compatibility (Windows, macOS, Linux)

## Prerequisites

- Python 3.6 or higher
- Git installed and available in PATH
- Requests library (`pip install requests`)
- Access tokens for both Bitbucket and GitHub

## Usage

```bash
python migrate.py --bb-user BITBUCKET_USERNAME --bb-repo BITBUCKET_REPO \
                 --gh-user GITHUB_USERNAME --gh-repo GITHUB_REPO \
                 --bb-token BITBUCKET_APP_PASSWORD --gh-token GITHUB_TOKEN \
                 [--private]
```

### Parameters

| Parameter    | Description                                          | Required |
| ------------ | ---------------------------------------------------- | -------- |
| `--bb-user`  | Bitbucket username or workspace                      | Yes      |
| `--bb-repo`  | Bitbucket repository name                            | Yes      |
| `--gh-user`  | GitHub username                                      | Yes      |
| `--gh-repo`  | GitHub repository name                               | Yes      |
| `--bb-token` | Bitbucket access token                               | Yes      |
| `--gh-token` | GitHub personal access token                         | Yes      |
| `--private`  | Create a private GitHub repository (default: public) | No       |

## Example

```bash
python migrate.py --bb-user mybitbucketuser --bb-repo myrepo \
                 --gh-user mygithubuser --gh-repo myrepo \
                 --bb-token abc123 --gh-token xyz789 --private
```

## What the Script Does

1. **Checks if the GitHub repository exists**

   - If it doesn't exist, creates it with the specified visibility (private/public)

2. **Migrates the repository**

   - Clones the Bitbucket repository with the `--mirror` option
   - Pushes to the GitHub repository with the `--mirror` option
   - This preserves all branches, tags, and commit history

3. **Creates the Bitbucket Pipelines configuration**
   - Generates a `bitbucket-pipelines.yml` file in the current directory
   - This file needs to be committed to your Bitbucket repository

## Next Steps After Running the Script

1. Add the generated `bitbucket-pipelines.yml` file to your Bitbucket repository:

   ```bash
   cd /path/to/your/bitbucket/repo
   cp /path/to/generated/bitbucket-pipelines.yml .
   git add bitbucket-pipelines.yml
   git commit -m "Add GitHub mirroring pipeline"
   git push
   ```

2. Set up repository variables in Bitbucket:

   - Go to Repository settings > Pipelines > Repository variables
   - Add `BITBUCKET_APP_PASSWORD` with your Bitbucket App Password (mark as "Secured")
   - Add `GITHUB_TOKEN` with your GitHub personal access token (mark as "Secured")

3. Enable Bitbucket Pipelines:
   - Go to Repository settings > Pipelines > Settings
   - Toggle the switch to enable Pipelines

## Batch Migration

For migrating multiple repositories, you can create a simple shell script:

```bash
#!/bin/bash

# List of repositories to migrate
REPOS=("repo1" "repo2" "repo3")

# Credentials
BB_USER="mybitbucketuser"
GH_USER="mygithubuser"
BB_TOKEN="your_bitbucket_token"
GH_TOKEN="your_github_token"

# Migrate each repository
for REPO in "${REPOS[@]}"; do
  echo "Migrating $REPO..."
  python migrate.py --bb-user $BB_USER --bb-repo $REPO \
                   --gh-user $GH_USER --gh-repo $REPO \
                   --bb-token $BB_TOKEN --gh-token $GH_TOKEN --private
done
```

## Troubleshooting

### Common Issues

- **Authentication Errors**: Verify that your tokens are correct and have the necessary permissions
- **Repository Not Found**: Check that the repository names and usernames are correct
- **Git Not Found**: Ensure Git is installed and available in your PATH
- **Module Not Found**: Install the required dependency with `pip install requests`

### Debugging

For more verbose output, you can modify the script to add debug logging:

```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

## Security Considerations

- Do not hardcode tokens in your scripts
- Consider using environment variables for tokens
- Use repository-specific tokens with minimal permissions
- Regularly rotate your access tokens
