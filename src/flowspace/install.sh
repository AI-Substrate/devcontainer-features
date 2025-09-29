#!/bin/bash
set -euo pipefail

# Flowspace DevContainer Feature Installation
# Extracts key logic from the official installer (https://aka.ms/InstallFlowspace)
# Installs Flowspace during devcontainer build phase when common-utils is available

FEATURE_NAME="flowspace"
VERSION="${VERSION:-latest}"
PRERELEASE="${PRERELEASE:-false}"
GITHUB_REPO="AI-Substrate/flowspace"

log() { echo "[flowspace] $*"; }
warn() { echo "[flowspace] ⚠️  $*" >&2; }
error() { echo "[flowspace] ❌ $*" >&2; exit 1; }
success() { echo "[flowspace] ✅ $*"; }
info() { echo "[flowspace] $*"; }

# Check prerequisites (provided by common-utils feature)
for tool in curl tar jq; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        error "Missing required tool: $tool. Ensure common-utils feature runs before flowspace."
    fi
done

log "Prerequisites check passed: curl, tar, jq available"

# System detection functions (from official installer)
detect_arch() {
    case "$(uname -m)" in
        x86_64) echo "amd64" ;;
        aarch64|arm64) echo "arm64" ;;
        *) error "Unsupported architecture: $(uname -m)" ;;
    esac
}

detect_os() {
    case "$(uname -s)" in
        Linux) echo "linux" ;;
        *) error "Unsupported OS: $(uname -s). Linux only." ;;
    esac
}

# Version detection (from official installer)
get_latest_version() {
    local api_url version
    
    if [[ "$PRERELEASE" == "true" ]]; then
        api_url="https://api.github.com/repos/$GITHUB_REPO/releases"
        info "Fetching latest version (including pre-releases)..." >&2
        version=$(curl -s "$api_url" | jq -r '.[0].tag_name' 2>/dev/null)
    else
        api_url="https://api.github.com/repos/$GITHUB_REPO/releases/latest"
        info "Fetching latest stable version..." >&2
        version=$(curl -s "$api_url" | jq -r '.tag_name' 2>/dev/null)
    fi
    
    if [[ -z "$version" || "$version" == "null" ]]; then
        error "Failed to fetch version from GitHub API"
    fi
    
    echo "$version"
}

# Binary installation (from official installer, Docker validation removed)
install_binary() {
    local version="$1" os="$2" arch="$3"
    local clean_version="${version#v}"
    local archive_name="flowspace-v${clean_version}-${os}-${arch}.tar.gz"
    local download_url="https://github.com/$GITHUB_REPO/releases/download/$version/$archive_name"
    local install_dir="/usr/local/bin"
    
    # Create install directory (should already exist in most base images)
    mkdir -p "$install_dir"
    local temp_dir=$(mktemp -d)
    
    info "Downloading $archive_name..."
    if ! curl -fsSL -o "$temp_dir/$archive_name" "$download_url"; then
        error "Download failed: $download_url"
    fi
    
    info "Extracting archive..."
    if ! tar -xzf "$temp_dir/$archive_name" -C "$temp_dir"; then
        error "Failed to extract archive"
    fi
    
    # The binary name in the archive includes OS and architecture
    local binary_name="flowspace-${os}-${arch}"
    local binary_path="$temp_dir/$binary_name"
    
    if [[ ! -f "$binary_path" ]]; then
        # Fallback: look for any flowspace binary
        binary_path=$(find "$temp_dir" -name "flowspace*" -type f | head -1)
        if [[ -z "$binary_path" ]]; then
            error "Flowspace binary not found in archive. Contents: $(ls -la $temp_dir)"
        fi
    fi
    
    info "Installing to $install_dir/flowspace..."
    cp "$binary_path" "$install_dir/flowspace"
    chmod +x "$install_dir/flowspace"
    rm -rf "$temp_dir"
    
    
    success "Installed to $install_dir/flowspace"
}

# Main installation
main() {
    log "Starting Flowspace installation..."
    
    local os arch install_version
    os=$(detect_os)
    arch=$(detect_arch)
    info "System: $os/$arch"
    
    if [[ "$VERSION" == "latest" ]]; then
        install_version=$(get_latest_version)
    else
        install_version="$VERSION"
    fi
    info "Version: $install_version"
    
    install_binary "$install_version" "$os" "$arch"
    
    if [[ -x "/usr/local/bin/flowspace" ]]; then
        success "Installation completed successfully!"
        info "Binary installed to /usr/local/bin/flowspace"
        info "Docker will be available at runtime for scans"
    else
        error "Installation verification failed"
    fi
}

main "$@"
