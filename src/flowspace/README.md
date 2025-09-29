
# Flowspace (flowspace)

Installs Flowspace CLI during container build. Docker will be available at runtime for scans.

## Example Usage

```json
"features": {
    "ghcr.io/ai-substrate/devcontainer-features/flowspace:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Flowspace release to install. Leave as "latest" to track the newest stable build. | string | latest |
| preRelease | Set to true to opt into Flowspace pre-release builds via FLOWSPACE_PRE_RELEASE. | boolean | false |

# Flowspace Dev Container Feature

The Flowspace Feature provisions the Flowspace CLI and the minimum host tooling required for Flowspace scans inside a development container. 

> ❗️ Flowspace requires a reachable Docker daemon. Pair this Feature with one of the Docker Features when the host's Docker context is not already mounted into the dev container.

### Option A – Docker-in-Docker (DinD)

```jsonc
{
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {},
    "ghcr.io/AI-Substrate/devcontainer-features/flowspace:1": {}
  }
}
```

### Option B – Docker-outside-of-Docker (DooD)

```jsonc
{
  "features": {
    "ghcr.io/devcontainers/features/docker-outside-of-docker:1": {},
    "ghcr.io/AI-Substrate/devcontainer-features/flowspace:1": {}
  },
}
```

> Codespaces running in "repo in container volume" mode cannot expose the host path; document this limitation for your team.


## Post-setup validation checklist

1. `docker info` completes successfully inside the dev container.
2. `flowspace --version` matches the configured `version`/`preRelease` settings.
3. `flowspace full-scan` (or a targeted scan) runs without Docker permission errors.

## Troubleshooting tips

- Re-run the installer manually (`curl -fsSL https://aka.ms/InstallFlowspace | bash`) when experimenting with custom environment variables.
- If Flowspace fails because Docker is unavailable, decide whether to add the DinD or DooD feature depending on your security posture.
- Remove the cached `.flowspace` volume when scans need a clean slate: `docker volume rm flowspace-cache-<id>`.

---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
