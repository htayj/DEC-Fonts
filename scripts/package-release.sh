#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
usage: scripts/package-release.sh [--version VERSION] [--release-dir DIR] [--source-date-epoch EPOCH]

Environment overrides are also supported:
  VERSION              Release version string (default: git describe fallback dev)
  RELEASE_DIR          Directory for release artifacts (default: dist/release)
  SOURCE_DATE_EPOCH    Timestamp used for deterministic tar metadata (default: 1731361680)
USAGE
}

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)

version=${VERSION:-$(git -C "$repo_root" describe --tags --always --dirty 2>/dev/null || echo dev)}
release_dir=${RELEASE_DIR:-dist/release}
source_date_epoch=${SOURCE_DATE_EPOCH:-1731361680}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)
            [[ $# -ge 2 ]] || { echo "--version requires a value" >&2; exit 2; }
            version=$2
            shift 2
            ;;
        --version=*)
            version=${1#--version=}
            shift
            ;;
        --release-dir)
            [[ $# -ge 2 ]] || { echo "--release-dir requires a value" >&2; exit 2; }
            release_dir=$2
            shift 2
            ;;
        --release-dir=*)
            release_dir=${1#--release-dir=}
            shift
            ;;
        --source-date-epoch)
            [[ $# -ge 2 ]] || { echo "--source-date-epoch requires a value" >&2; exit 2; }
            source_date_epoch=$2
            shift 2
            ;;
        --source-date-epoch=*)
            source_date_epoch=${1#--source-date-epoch=}
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [[ ! "$version" =~ ^[A-Za-z0-9._+~-]+$ ]]; then
    echo "VERSION must contain only ASCII letters, digits, '.', '_', '+', '~', or '-': $version" >&2
    exit 2
fi

case "$source_date_epoch" in
    ""|*[!0-9]*)
        echo "SOURCE_DATE_EPOCH must be an integer timestamp: $source_date_epoch" >&2
        exit 2
        ;;
esac

cd "$repo_root"
umask 022

for tool in tar gzip sha256sum find cp mktemp grep chmod; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "missing required tool: $tool" >&2
        exit 1
    }
done

if ! tar --version 2>/dev/null | grep -q 'GNU tar'; then
    echo "GNU tar is required for deterministic release archives" >&2
    exit 1
fi

[[ -f README.org ]] || { echo "missing required file: README.org" >&2; exit 1; }
[[ -f dist/dec.set ]] || { echo "missing required file: dist/dec.set" >&2; exit 1; }

for spec in bdf:*.bdf otb:*.otb psf:*.psf; do
    dir=${spec%%:*}
    pattern=${spec#*:}
    path="dist/fonts/$dir"
    [[ -d "$path" ]] || { echo "missing required directory: $path" >&2; exit 1; }
    if [[ -z $(find "$path" -maxdepth 1 -type f -name "$pattern" -print -quit) ]]; then
        echo "missing generated $pattern files under $path" >&2
        exit 1
    fi
done

mkdir -p "$release_dir"
release_dir=$(cd "$release_dir" && pwd)
package_name="DEC-Fonts-$version"
archive="$release_dir/$package_name.tar.gz"
checksum="$archive.sha256"
staging_root=$(mktemp -d "$release_dir/.package.XXXXXX")
trap 'rm -rf "$staging_root"' EXIT

mkdir -p "$staging_root/$package_name/dist/fonts"
cp -p README.org "$staging_root/$package_name/README.org"
cp -p dist/dec.set "$staging_root/$package_name/dist/dec.set"
cp -a dist/fonts/bdf "$staging_root/$package_name/dist/fonts/bdf"
cp -a dist/fonts/otb "$staging_root/$package_name/dist/fonts/otb"
cp -a dist/fonts/psf "$staging_root/$package_name/dist/fonts/psf"
find "$staging_root/$package_name" -type d -exec chmod 0755 {} +
find "$staging_root/$package_name" -type f -exec chmod 0644 {} +

rm -f "$archive" "$checksum"
(
    cd "$staging_root"
    tar \
        --sort=name \
        --mtime="@$source_date_epoch" \
        --owner=0 \
        --group=0 \
        --numeric-owner \
        -cf - \
        "$package_name" | gzip -n > "$archive"
)

(
    cd "$release_dir"
    sha256sum "$(basename "$archive")" > "$(basename "$checksum")"
)
echo "wrote $archive"
echo "wrote $checksum"
