# Troubleshooting Guide

This guide provides solutions to common issues you might encounter when setting up repository migration and synchronization from Bitbucket to GitHub.

## Common Issues and Solutions

### Authentication Failures

#### Issue: "Authentication failed" error in Bitbucket Pipelines

**Possible causes:**

- Incorrect or expired Bitbucket token
- Incorrect or expired GitHub token
- Repository URL typo
- Missing BITBUCKET_AUTH_USERNAME for workspace repositories
- Insufficient permissions for your personal account in the workspace

**Solutions:**

1. Regenerate your Bitbucket App Password and update the `BITBUCKET_APP_PASSWORD` repository variable
2. Regenerate your GitHub personal access token and update the `GITHUB_TOKEN` repository variable
3. Double-check the repository URLs in your `bitbucket-pipelines.yml` file
4. For workspace repositories, ensure you've added the `BITBUCKET_AUTH_USERNAME` variable with your personal Bitbucket username
5. Verify that your personal account has appropriate permissions in the workspace

### Permission Issues

#### Issue: "Permission denied" error when pushing to GitHub

**Possible causes:**

- GitHub token doesn't have the `repo` scope
- Deploy key doesn't have write access

**Solutions:**

1. Regenerate your GitHub token with the `repo` scope
2. Go to your GitHub repository settings and ensure the deploy key has write access

### Pipeline Configuration Issues

#### Issue: Bitbucket Pipeline doesn't trigger

**Possible causes:**

- Pipelines not enabled for the repository
- Incorrect pipeline configuration

**Solutions:**

1. Go to Repository settings > Pipelines > Settings and enable pipelines
2. Validate your `bitbucket-pipelines.yml` file syntax

### Workspace-Specific Issues

#### Issue: "401 Unauthorized" error when using a workspace repository

**Possible causes:**

- Missing BITBUCKET_AUTH_USERNAME variable
- Incorrect personal username
- Insufficient permissions in the workspace

**Solutions:**

1. Add the `BITBUCKET_AUTH_USERNAME` variable with your personal Bitbucket username
2. Verify that your personal username is correct (this is your login username, not the workspace name)
3. Ensure your personal account has appropriate permissions in the workspace
4. Check that your App Password has the necessary permissions (Repository read/write, Pipelines read/write/variables)

#### Issue: Pipeline works for personal repositories but fails for workspace repositories

**Possible causes:**

- Different authentication requirements for workspace repositories
- Incorrect pipeline configuration

**Solutions:**

1. Ensure you're using the correct authentication format for workspace repositories
2. Verify that the pipeline configuration includes conditional logic for workspace repositories
3. Check that all required variables are set correctly

### Git Issues

#### Issue: "Updates were rejected because the remote contains work that you do not have locally"

**Possible causes:**

- The destination repository has commits that aren't in the source repository

**Solutions:**

1. For initial setup, consider using `--force` with caution
2. Pull changes from the destination repository before pushing
3. Consider using `--mirror` instead of regular push

#### Issue: "shallow update not allowed" error

**Possible causes:**

- Using a shallow clone with `--mirror`

**Solutions:**

1. Use `--mirror` when cloning in Bitbucket Pipelines

## Advanced Troubleshooting

### Debugging Bitbucket Pipelines

To get more detailed information about what's happening in your pipeline:

1. Add the `-v` flag to git commands for verbose output:

   ```bash
   git clone -v --mirror https://...
   git push -v --mirror https://...
   ```

2. Add debugging steps to your pipeline:

   ```yaml
   - echo "Current directory: $(pwd)"
   - ls -la
   - git remote -v
   - echo "BITBUCKET_REPO_OWNER: ${BITBUCKET_REPO_OWNER}"
   - echo "BITBUCKET_REPO_SLUG: ${BITBUCKET_REPO_SLUG}"
   - echo "Using workspace repository: $([[ -n "${BITBUCKET_AUTH_USERNAME}" ]] && echo "Yes" || echo "No")"
   ```

3. For workspace-specific debugging:
   ```yaml
   - if [ -n "${BITBUCKET_AUTH_USERNAME}" ]; then
     - echo "Using workspace repository with auth username: ${BITBUCKET_AUTH_USERNAME}"
     - else
     - echo "Using personal repository with owner: ${BITBUCKET_REPO_OWNER}"
     - fi
   ```

## Getting Help

If you're still experiencing issues after trying the solutions in this guide:

1. Check the pipeline logs for specific error messages
2. Search for the error message in the GitHub or Bitbucket documentation
3. Open an issue in this repository with:
   - A description of the problem
   - The error message
   - Steps you've already taken to resolve it
   - Your configuration files (with sensitive information removed)
