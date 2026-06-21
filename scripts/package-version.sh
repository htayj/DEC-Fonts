#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
usage: scripts/package-version.sh [VERSION]

Normalize a git describe/tag string for Linux package metadata.
If VERSION is omitted, VERSION from the environment is used; if that is unset,
git describe --tags --always --dirty is used, with a final fallback of "dev".
USAGE
}

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)

if [[ $# -gt 1 ]]; then
    usage >&2
    exit 2
fi

case "${1:-}" in
    --help|-h)
        usage
        exit 0
        ;;
esac

raw_version=${1:-${VERSION:-}}
if [[ -z "$raw_version" ]]; then
    raw_version=$(git -C "$repo_root" describe --tags --always --dirty 2>/dev/null || echo dev)
fi

# Keep the shared DEB/RPM upstream version in the intersection of their safe
# character sets.  Hyphens are reserved for package release suffixes, and Debian
# package versions reject underscores, so both are converted to dots.
version=$raw_version
if [[ $version =~ ^[vV][0-9] ]]; then
    version=${version:1}
fi
version=${version//-/.}
version=$(printf '%s' "$version" | LC_ALL=C sed -E \
    -e 's/[^A-Za-z0-9.+_~]+/./g' \
    -e 's/_/./g' \
    -e 's/[.]+/./g' \
    -e 's/^[.]+//' \
    -e 's/[.]+$//')

if [[ -z "$version" ]]; then
    version=unknown
fi

if [[ ! $version =~ ^[0-9] ]]; then
    version="0+git.$version"
fi

if [[ $version == *-* ]]; then
    echo "normalized package version must not contain '-': $version" >&2
    exit 1
fi

if [[ ! $version =~ ^[A-Za-z0-9.+~]+$ ]]; then
    echo "normalized package version contains unsupported characters: $version" >&2
    exit 1
fi

printf '%s\n' "$version"
