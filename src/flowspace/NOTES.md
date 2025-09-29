# Flowspace Dev Container Feature

The Flowspace Feature provisions the Flowspace CLI and the minimum host tooling required for Flowspace scans inside a development container. It follows the integration plan documented in `docs/flowspace-feature.md`, ensuring Docker access considerations, installer prerequisites, and runtime ergonomics are covered.

## What gets installed

- Flowspace CLI via the official `https://aka.ms/InstallFlowspace` bootstrapper.
- Core utilities demanded by the installer: `curl`, `tar`, `jq`, `ca-certificates`, and `sha256sum` (through `coreutils`).
- Shell profile tweaks so `$HOME/.local/bin` stays on the default user `PATH`.
- Optional Flowspace installer environment variables (`FLOWSPACE_VERSION`, `FLOWSPACE_PRE_RELEASE`, `FLOWSPACE_BASE_URL`) exported for downstream lifecycle hooks.

If Docker is not already available inside the container, the Feature emits a warning so you can bolt on Docker-in-Docker or Docker-outside-of-Docker support.

## Feature options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `version` | string | `"latest"` | Flowspace release to install. Values other than `latest` populate `FLOWSPACE_VERSION` before running the installer. |
| `preRelease` | boolean | `false` | When `true`, sets `FLOWSPACE_PRE_RELEASE=1` so the installer picks pre-release builds. |
| `baseUrl` | string | `""` | Overrides the Flowspace download mirror by exporting `FLOWSPACE_BASE_URL`. Useful for air-gapped mirrors. |
| `skipCliInstall` | boolean | `false` | Skips running the Flowspace installer. Use when Flowspace is pre-baked into the image or for offline testing. |

## Basic usage

```jsonc
{
  "name": "Flowspace Dev Container",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {},
    "ghcr.io/devcontainers/features/git:1": {},
    "ghcr.io/AI-Substrate/devcontainer-features/flowspace:0": {
      "version": "latest",
      "preRelease": false
    }
  },
  "postCreateCommand": "flowspace --version && docker info"
}
```

> ❗️ Flowspace requires a reachable Docker daemon. Pair this Feature with one of the Docker Features when the host's Docker context is not already mounted into the dev container.

### Option A – Docker-in-Docker (DinD)

```jsonc
{
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {},
    "ghcr.io/AI-Substrate/devcontainer-features/flowspace:0": {}
  },
  "mounts": [
    {
      "source": "dind-var-lib-docker-${devcontainerId}",
      "target": "/var/lib/docker",
      "type": "volume"
    },
    "source=flowspace-cache-${devcontainerId},target=${containerWorkspaceFolder}/.flowspace,type=volume"
  ]
}
```

- The Docker Feature sets `privileged` automatically; no additional `runArgs` are needed.
- Reclaim the named volume when you need a fresh Docker state.

### Option B – Docker-outside-of-Docker (DooD)

```jsonc
{
  "features": {
    "ghcr.io/devcontainers/features/docker-outside-of-docker:1": {},
    "ghcr.io/AI-Substrate/devcontainer-features/flowspace:0": {}
  },
  "workspaceFolder": "${localWorkspaceFolder}",
  "workspaceMount": "source=${localWorkspaceFolder},target=${localWorkspaceFolder},type=bind",
  "remoteEnv": {
    "LOCAL_WORKSPACE_FOLDER": "${localWorkspaceFolder}",
    "HOST_PROJECT_PATH": "${localWorkspaceFolder}"
  }
}
```

> Codespaces running in "repo in container volume" mode cannot expose the host path; document this limitation for your team.

## Secrets and environment variables

Forward Flowspace credentials or Azure/OpenAI keys without committing them:

```jsonc
"remoteEnv": {
  "AZURE_OPENAI_API_KEY": "${localEnv:AZURE_OPENAI_API_KEY}",
  "OPENAI_API_KEY": "${codespacesSecret:OPENAI_API_KEY}"
}
```

Add `.env` to `.gitignore` in your project so local overrides stay private.

## Post-setup validation checklist

1. `docker info` completes successfully inside the dev container.
2. `flowspace --version` matches the configured `version`/`preRelease` settings.
3. `flowspace full-scan` (or a targeted scan) runs without Docker permission errors.

## Advanced configuration

- Set `FLOWSPACE_BASE_URL` through the `baseUrl` option when mirroring the installer artifacts.
- Persist Flowspace indices across rebuilds via the `.flowspace` volume example above.
- Combine with `ghcr.io/devcontainers/features/azure-cli:1` when you manage Azure OpenAI deployments from inside the container.
- Optional MCP wiring: once installed, you can add an entry to `.vscode/mcp.json` pointing at `flowspace mcp`.

## Troubleshooting tips

- Re-run the installer manually (`curl -fsSL https://aka.ms/InstallFlowspace | bash`) when experimenting with custom environment variables.
- If Flowspace fails because Docker is unavailable, decide whether to add the DinD or DooD feature depending on your security posture.
- Remove the cached `.flowspace` volume when scans need a clean slate: `docker volume rm flowspace-cache-<id>`.