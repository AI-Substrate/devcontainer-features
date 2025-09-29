# Dev Container Features

This repository contains DevContainer Features for enhanced development environments.

## Features

### Flowspace

A DevContainer Feature that installs and configures [Flowspace](https://github.com/AI-Substrate/flowspace), a CLI tool for workflow automation and development operations.

**Status**: ✅ **Production Ready**

## Usage

Add the flowspace feature to your `.devcontainer/devcontainer.json`:

```json
{
  "name": "My Development Environment",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/ai-substrate/devcontainer-features/flowspace:latest": {
      "version": "latest"
    }
  }
}
```

### Options

- `version`: Flowspace version to install (default: "latest")
- `preRelease`: Install pre-release version (default: false)

### Example with Options

```json
{
  "features": {
    "ghcr.io/ai-substrate/devcontainer-features/flowspace:latest": {
      "version": "v1.2.0",
      "preRelease": false
    }
  }
}
```

## Repository Layout

```
├── docs/
│   ├── flowspace-feature.md    # Feature documentation
│   ├── sonnet-review.md        # Development analysis
│   └── workflow-updates.md     # CI/CD documentation
├── src/
│   └── flowspace/              # Flowspace feature implementation
│       ├── devcontainer-feature.json
│       ├── install.sh
│       └── README.md
├── test/
│   └── flowspace/              # Feature tests
│       ├── scenarios.json
│       ├── test.sh
│       └── flowspace.sh
└── .github/
    └── workflows/              # CI/CD pipelines
```

## Development Status

- ✅ **Flowspace Feature**: Fully implemented and tested
- ✅ **CI/CD Pipelines**: Updated for feature testing and publishing
- ✅ **Documentation**: Complete with usage examples and architecture notes
- ✅ **Testing**: Comprehensive test suite with Docker integration

## Testing

Test the features locally using the DevContainer CLI:

```bash
# Test all features
devcontainer features test

# Test specific feature
devcontainer features test --features flowspace

# Test with custom base image
devcontainer features test --features flowspace --base-image mcr.microsoft.com/devcontainers/base:ubuntu
```

## Publishing

Features are automatically published to GitHub Container Registry when changes are merged to main. The registry location is:

```
ghcr.io/ai-substrate/devcontainer-features/flowspace
```

## Requirements

The flowspace feature requires:
- **common-utils**: Provides `curl`, `jq`, and `tar` utilities
- **docker-in-docker**: Provides Docker daemon for flowspace operations

These dependencies are automatically handled by the feature's `installsAfter` configuration.

## Contributing

1. **Feature Development**: Create or update feature code in `src/`
2. **Testing**: Add or update tests under `test/` and run locally with `devcontainer features test`
3. **Documentation**: Update relevant documentation in `docs/` and `README.md`
4. **CI/CD**: GitHub workflows automatically test PRs and publish releases

### Development Workflow

1. Fork and clone the repository
2. Make changes to feature implementation in `src/flowspace/`
3. Update tests in `test/flowspace/` as needed
4. Test locally: `devcontainer features test --features flowspace`
5. Submit pull request - CI will validate changes
6. Merge to main triggers automatic publishing

Please refer to the [DevContainer Feature specification](https://containers.dev/implementors/features) when making changes.

## Architecture

The flowspace feature is designed with the following considerations:

- **System Installation**: Installs flowspace to `/usr/local/bin` for system-wide availability
- **Dependency Management**: Uses `installsAfter` to ensure required tools are available
- **Version Flexibility**: Supports both latest and specific version installation
- **Docker Integration**: Works seamlessly with Docker-in-Docker for container operations

For detailed technical information, see the documentation in `docs/`.
