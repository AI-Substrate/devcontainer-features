# Flowspace Dev Container Integration Guide

## Goal
Establish a reproducible development container configuration that enables Flowspace to run reliably inside VS Code or GitHub Codespaces while following development container best practices and Flowspace’s Docker requirements.

## Runtime Requirements Snapshot
- **Docker access is mandatory** – the Flowspace installer exits when Docker is unavailable and explicitly suggests adding either Docker-in-Docker or Docker-outside-of-Docker when running inside devcontainers (source: `scripts/install-flowspace.sh`). Treat these as recommended add-ons; a workspace can skip them only when another secure Docker path is already available.
- **Installer prerequisites** – `curl`, `tar`, `jq`, and a checksum utility (`sha256sum` or `shasum`) must be available so the script can download, extract, and validate the Flowspace binary (installer script logic).
- **Runtime configuration** – developers supply Azure/OpenAI credentials via environment variables or `.env` files; Flowspace creates a `.flowspace` directory and spawns Docker workloads for scans (`README.md`).

## Baseline Dev Container Shape
- **Base image**: `mcr.microsoft.com/devcontainers/base:ubuntu` (Debian-based images ensure compatibility with official Features).
- **Core Features**:
  - `ghcr.io/devcontainers/features/common-utils:2` to provision curl, tar, jq, git, zsh, and quality-of-life tooling.
  - `ghcr.io/devcontainers/features/git:1` when an updated Git (for Git Credential Manager integration) is required.
  - Optional: `ghcr.io/devcontainers/features/azure-cli:1` if managing Azure OpenAI deployments from inside the container.
- **Customizations**: configure VS Code settings or extensions (e.g., `ms-azuretools.vscode-containers`) inside `customizations.vscode` to aid Docker troubleshooting.

## Docker Enablement Strategies
Flowspace can operate with either an isolated Docker engine (DinD) or the host daemon (DooD). Include one of the following Features when Docker is otherwise inaccessible; if your Codespace or local Docker context already exposes Docker securely you can omit them.

### Option A – Docker-in-Docker (DinD)
- Add the Feature referenced in the Dev Containers registry (Context7 `/devcontainers/features` documentation):

  ```jsonc
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {}
  }
  ```

- Persist the engine’s data using the `${devcontainerId}` placeholder highlighted in the Dev Container spec to avoid volume conflicts:

  ```jsonc
  "mounts": [
    {
      "source": "dind-var-lib-docker-${devcontainerId}",
      "target": "/var/lib/docker",
      "type": "volume"
    }
  ]
  ```

-Notes
- The Feature sets `privileged` and `init` automatically; additional `runArgs` are usually unnecessary.
- Ensure the container image architecture matches the host (Feature README limitation).
- Reclaim the named volume when a clean Docker state is required.

### Option B – Docker-outside-of-Docker (DooD)
- Attach the Docker CLI Feature as described in the official README:

  ```jsonc
  "features": {
    "ghcr.io/devcontainers/features/docker-outside-of-docker:1": {}
  }
  ```

- Mirror host paths and expose them as environment variables so bind mounts continue to work:

  ```jsonc
  "remoteEnv": {
    "LOCAL_WORKSPACE_FOLDER": "${localWorkspaceFolder}",
    "HOST_PROJECT_PATH": "${localWorkspaceFolder}"
  },
  "workspaceFolder": "${localWorkspaceFolder}",
  "workspaceMount": "source=${localWorkspaceFolder},target=${localWorkspaceFolder},type=bind"
  ```

- When invoking Docker inside the container use `${LOCAL_WORKSPACE_FOLDER}`. Provide `HOST_PROJECT_PATH` to shims or scripts that need the exact host path when orchestrating bind mounts. Document the limitation that Codespaces “repo in container volume” mode does not expose a host path.

## Flowspace Version Control
- Expose a `version` option on the Flowspace Feature (default: `latest`). The feature’s `install.sh` should export `FLOWSPACE_VERSION` before invoking the installer only when a value is provided.
- Allow developers to opt into pre-releases through an additional boolean (e.g., `preRelease`), mirroring the installer’s `FLOWSPACE_PRE_RELEASE` flag.

## Flowspace Installation Workflow
1. **Feature bootstrap** – the Flowspace Feature executes the official installer during the build phase (running as the non-root development user). It exports the relevant environment variables (`FLOWSPACE_VERSION`, `FLOWSPACE_PRE_RELEASE`, `FLOWSPACE_BASE_URL`) whenever you set the corresponding options. When `skipCliInstall` is true, the Feature leaves these environment variables in place so you can run the installer later.

   ```jsonc
  "features": {
    "ghcr.io/AI-Substrate/devcontainer-features/flowspace:0": {
      "version": "1.4.0",
      "preRelease": false,
      "baseUrl": "https://mirror.contoso.corp/flowspace"
    }
  }
   ```

   - The installer places the binary in `~/.local/bin`. The Feature injects profile snippets so this directory stays on `PATH` for both root and the default dev container user.
  - Pin versions or support offline installs through the exported environment variables. You can still re-run the installer manually (or inside `postCreateCommand`) when experimenting with alternative flows:

    ```jsonc
    "postCreateCommand": "flowspace --version && flowspace --help"
    ```

2. **Optional caching** – mount Flowspace’s working directory to preserve indices across rebuilds:

   ```jsonc
   "mounts": [
     "source=flowspace-cache-${devcontainerId},target=${containerWorkspaceFolder}/.flowspace,type=volume"
   ]
   ```

3. **Validation** – ensure the Docker daemon is reachable by appending `docker info` to the lifecycle hook or documenting a manual verification step.

## Secrets and Configuration Handling
- Mirror API keys into the container without committing them, following the README guidance:

  ```jsonc
  "remoteEnv": {
    "AZURE_OPENAI_API_KEY": "${localEnv:AZURE_OPENAI_API_KEY}"
  }
  ```

- Encourage teams using GitHub Codespaces to leverage `${codespacesSecret:NAME}` mappings. Flowspace rejects credentials embedded directly in `config.yaml`, so keep them in `.env` or secret stores.
- Add `.env` to `.gitignore` if it is not already present in the target repository.

## Post-Setup Tasks for Developers
- Run `flowspace init` inside the project to scaffold `.flowspace/config.yaml` and verify Docker connectivity.
- Configure scan include/exclude paths so Flowspace containers have access to relevant source directories (bind mounts must align with DinD or DooD strategy).
- For MCP usage, optionally commit a `.vscode/mcp.json` entry that points to `flowspace mcp` once the binary is available.

## Validation Checklist
- `docker info` succeeds inside the dev container.
- `flowspace --version` returns the expected Flowspace release.
- `flowspace full-scan` completes on a sample repository without Docker permission errors.

## Future Enhancements & Open Questions
- Prebuild the dev container image with Flowspace installed (set `skipCliInstall=true` during feature execution) to avoid repeated downloads.
- Decide whether to pin `FLOWSPACE_VERSION` for deterministic builds or track the latest release.
- Monitor Flowspace roadmap for GPU acceleration; if adopted, combine with the `ghcr.io/devcontainers/features/nvidia-cuda:1` Feature and set `"hostRequirements": { "gpu": "optional" }`.
- Evaluate collecting `flowspace` binary checksums internally if the GitHub repository becomes private.

This plan captures the actionable steps required to integrate Flowspace into a development container while aligning with the Dev Container best practices surfaced through the Context7 documentation.