# GitHub Workflows and Actions Updates

## Overview
Updated the repository's GitHub workflows and actions to support **DevContainer Features** instead of **DevContainer Templates**.

## Files Modified

### 1. `.github/workflows/test-pr.yaml`
**Changes:**
- **Name**: Changed from "CI - Test Templates" to "CI - Test Features"
- **Change Detection**: Replaced hardcoded template filters with dynamic feature detection using `tj-actions/changed-files@v41`
- **Testing Approach**: Replaced custom smoke-test action with direct `devcontainer features test` command
- **Matrix Strategy**: Removed matrix strategy since we now detect and test all changed features in a single job

**Key Improvements:**
- Automatically detects any feature in `src/` directory when files change
- Uses proper DevContainer CLI feature testing
- More efficient single-job approach
- Future-proof for additional features

### 2. `.github/workflows/release.yaml`
**Changes:**
- **Name**: Changed from "Release Dev Container Templates & Generate Documentation" to "Release Dev Container Features & Generate Documentation"
- **Publish Mode**: Changed from `publish-templates: "true"` to `publish-features: "true"`
- **Base Path**: Changed from `base-path-to-templates: "./src"` to `base-path-to-features: "./src"`

**Key Improvements:**
- Correctly publishes features to GitHub Container Registry
- Generates proper feature documentation
- Maintains same documentation PR creation workflow

### 3. `.github/actions/smoke-test/action.yaml`
**Changes:**
- **Added Comment**: Added note that this action is for DevContainer Templates only
- **Status**: Kept for backward compatibility but not used by feature workflows

**Note**: The new feature testing approach uses `devcontainer features test` directly, which is more appropriate and efficient than custom smoke tests.

## Workflow Behavior

### PR Testing (`test-pr.yaml`)
1. **Trigger**: On pull request
2. **Detection**: Automatically detects changed files in `src/` directory
3. **Feature Extraction**: Extracts feature names from changed file paths
4. **Testing**: Runs `devcontainer features test --features <feature-name>` for each changed feature
5. **Example**: If `src/flowspace/install.sh` changes, it detects `flowspace` and runs `devcontainer features test --features flowspace`

### Release Publishing (`release.yaml`)
1. **Trigger**: Manual workflow dispatch on main branch
2. **Publishing**: Uses `devcontainers/action@v1` with `publish-features: true`
3. **Documentation**: Generates feature documentation and creates PR for updates
4. **Registry**: Publishes to GitHub Container Registry as features (not templates)

## Testing Verification

The updated workflows were tested with:
- **Feature Detection**: Correctly identifies `flowspace` from changed files in `src/flowspace/`
- **Command Generation**: Properly constructs `devcontainer features test --features flowspace`
- **Path Matching**: Works with the existing repository structure

## Future Features

The workflows are now designed to automatically handle new features:
1. Add new feature directory under `src/new-feature/`
2. Include `devcontainer-feature.json` and other feature files
3. Workflows will automatically detect and test the new feature
4. No manual workflow updates required

## Compatibility

- **Templates**: Old smoke-test actions remain for potential future template support
- **Features**: New workflows fully support current and future DevContainer Features
- **Documentation**: Maintains existing documentation generation and PR creation
- **Publishing**: Correctly publishes to appropriate registry endpoints

## Commands Used

The workflows now use standard DevContainer CLI commands:
```bash
# Install CLI (in GitHub Actions)
npm install -g @devcontainers/cli

# Test features
devcontainer features test --features <feature-name>
```

This approach aligns with DevContainer Feature best practices and official tooling.