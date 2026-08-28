#!/usr/bin/env bash
#
# install-zolt.sh - download zoltd from GitHub releases for the current OS/arch
# and install it, adding it to PATH.
#
# The installed release tag is cached next to the binary. Running the script
# again keeps zoltd up to date: if the latest release differs from the cached
# version, the script downloads and installs the new version.
#
# Usage:
#   ./install-zolt.sh [--dir DIR] [--version TAG] [--no-path]
#
#   --dir DIR        install zoltd into DIR (default: ~/.local/bin)
#   --version TAG    download a specific release tag like v0.1.0 (default: latest)
#   --no-path        install without touching shell rc files
#   -h, --help       show this help

set -euo pipefail

repo="iluvicecream/zolt"
version="latest"
install_dir="${HOME}/.local/bin"
modify_path=1

usage() {
    sed -n '2,15p' "$0"
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --dir)
            [ "$#" -ge 2 ] || { echo "error: --dir requires a value" >&2; exit 1; }
            install_dir="$2"
            shift 2
            ;;
        --version)
            [ "$#" -ge 2 ] || { echo "error: --version requires a value" >&2; exit 1; }
            version="$2"
            shift 2
            ;;
        --no-path)
            modify_path=0
            shift
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            echo "error: unknown option: $1" >&2
            usage
            exit 1
            ;;
    esac
done

if [ -z "${HOME:-}" ]; then
    echo "error: \$HOME is not set; pass --dir explicitly" >&2
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "error: curl is required to download zoltd" >&2
    exit 1
fi

# Map the running OS to the asset suffix used by the release.
os=$(uname -s)
case "$os" in
    Linux)  os_asset="linux" ;;
    Darwin) os_asset="macos" ;;
    *)
        echo "error: unsupported OS '$os' (zolt ships binaries for linux and macos)" >&2
        exit 1
        ;;
esac

# Map the machine architecture to the asset suffix used by the release.
arch=$(uname -m)
case "$arch" in
    x86_64 | amd64)  arch_asset="x86_64" ;;
    aarch64 | arm64) arch_asset="aarch64" ;;
    *)
        echo "error: unsupported architecture '$arch' (zolt ships binaries for x86_64 and aarch64)" >&2
        exit 1
        ;;
esac

asset="zoltd-${arch_asset}-${os_asset}"
cache_file="${install_dir}/.zolt-version"

cached=""
if [ -f "$cache_file" ]; then
    cached=$(cat "$cache_file")
fi

# Normalize a pinned version to a release tag (0.1.0 -> v0.1.0).
case "$version" in
    latest) ;;
    v*) ;;
    *) version="v${version}" ;;
esac

fetch_latest_version() {
    # Follow the /releases/latest redirect; the final URL contains the tag.
    local url
    url=$(curl -fsSIL -o /dev/null --max-redirs 3 -w '%{url_effective}' \
        "https://github.com/${repo}/releases/latest" 2>/dev/null || true)
    case "$url" in
        */tag/*)
            printf '%s\n' "${url##*/tag/}"
            return 0
            ;;
    esac
    # Fallback: parse the tag out of the GitHub API response.
    curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null \
        | grep -m1 '"tag_name"' \
        | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/'
}

if [ "$version" = "latest" ]; then
    echo "checking for the latest zolt release ..."
    latest_version=$(fetch_latest_version || true)
    if [ -z "$latest_version" ]; then
        if [ -n "$cached" ] && [ -x "${install_dir}/zoltd" ]; then
            echo "warning: could not reach GitHub to check for updates; keeping installed zolt $cached" >&2
            exit 0
        fi
        echo "error: could not determine the latest zolt release" >&2
        exit 1
    fi

    if [ "$latest_version" = "$cached" ] && [ -x "${install_dir}/zoltd" ]; then
        echo "zolt $cached is already installed and up to date"
        exit 0
    fi

    if [ -n "$cached" ]; then
        echo "new release available: $latest_version (installed: $cached) - updating ..."
    fi
    version="$latest_version"
else
    if [ "$version" = "$cached" ] && [ -x "${install_dir}/zoltd" ]; then
        echo "zolt $version is already installed"
        exit 0
    fi
    if [ -n "$cached" ] && [ "$version" != "$cached" ]; then
        echo "updating zolt $cached -> $version ..."
    fi
fi

base_url="https://github.com/${repo}/releases/download/${version}"

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/zolt-install.XXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT

sha256_of_file() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    else
        return 1
    fi
}

echo "zolt $version for ${arch_asset}/${os_asset}"
echo "downloading $asset ..."
curl -fL --proto '=https' --tlsv1.2 -o "${tmp_dir}/${asset}" "${base_url}/${asset}"

# Verify against the checksum file published alongside the binary.
echo "verifying checksum ..."
if curl -fsSL -o "${tmp_dir}/SHA256SUMS.txt" "${base_url}/SHA256SUMS.txt"; then
    expected=$(awk -v name="$asset" '$2 == name {print $1}' "${tmp_dir}/SHA256SUMS.txt")
    if [ -z "$expected" ]; then
        echo "warning: no checksum entry for $asset in SHA256SUMS.txt; skipping verification" >&2
    else
        actual=$(sha256_of_file "${tmp_dir}/${asset}")
        if [ "$actual" != "$expected" ]; then
            echo "error: checksum mismatch for $asset" >&2
            echo "  expected: $expected" >&2
            echo "  actual:   $actual" >&2
            exit 1
        fi
    fi
else
    echo "warning: no SHA256SUMS.txt in this release; skipping verification" >&2
fi

mkdir -p "$install_dir"
if command -v install >/dev/null 2>&1; then
    install -m 0755 "${tmp_dir}/${asset}" "${install_dir}/zoltd"
else
    cp "${tmp_dir}/${asset}" "${install_dir}/zoltd"
    chmod 0755 "${install_dir}/zoltd"
fi
printf '%s\n' "$version" > "$cache_file"

if [ "$modify_path" -eq 1 ]; then
    case ":$PATH:" in
        *":${install_dir}:"*) ;;
        *)
            shell_name=$(basename "${SHELL:-}")
            case "$shell_name" in
                zsh)  rc="${HOME}/.zshrc" ;;
                bash) rc="${HOME}/.bashrc" ;;
                fish) rc="${HOME}/.config/fish/config.fish" ;;
                *)    rc="${HOME}/.profile" ;;
            esac
            mkdir -p "$(dirname "$rc")"
            if [ "$shell_name" = "fish" ]; then
                printf 'fish_add_path %s\n' "$install_dir" >> "$rc"
            else
                printf '\n# added by install-zolt.sh\nexport PATH="%s:$PATH"\n' "$install_dir" >> "$rc"
            fi
            echo "added $install_dir to PATH in $rc"
            echo "restart your shell, or run: source $rc"
            ;;
    esac
else
    echo "add $install_dir to your PATH manually (e.g. export PATH=\"$install_dir:\$PATH\")"
fi

if command -v zoltd >/dev/null 2>&1; then
    echo "note: zoltd was already available at $(command -v zoltd); the installed copy is at ${install_dir}/zoltd"
fi

echo "done: zoltd installed at ${install_dir}/zoltd"
