# Troubleshooting Guide

This guide provides solutions to common issues you might encounter when setting up repository migration and synchronization from Bitbucket to GitHub.

## Common Issues and Solutions

### Authentication Failures

#### Issue: "Authentication failed" error in Bitbucket Pipelines

**Possible causes:**

- Incorrect or expired Bitbucket token
- Incorrect or expired GitHub token
- Repository URL typo

**Solutions:**

1. Regenerate your Bitbucket access token and update the `BITBUCKET_TOKEN` repository variable
2. Regenerate your GitHub personal access token and update the `GITHUB_TOKEN` repository variable
3. Double-check the repository URLs in your `bitbucket-pipelines.yml` file

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
