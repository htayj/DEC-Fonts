#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
usage: scripts/package-void.sh [--version VERSION] [--output-dir DIR] [--runtime docker|podman] [--image IMAGE] [--no-container]

Build dec-fonts-<version>_1.noarch.xbps. Defaults to dist/packages/void.
If xbps-create is not available locally, the script re-executes itself inside
a Void Linux container when docker/podman is available.
USAGE
}

fail() {
    echo "package-void: $*" >&2
    exit 1
}

quote() {
    printf '%q' "$1"
}

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
version_input=${VERSION:-}
output_dir=${VOID_PACKAGE_DIR:-${DIST_PACKAGE_DIR:-dist/packages}/void}
runtime=${CONTAINER_RUNTIME:-docker}
image=${VOID_CONTAINER_IMAGE:-docker.io/voidlinux/voidlinux:latest}
allow_container=true

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)
            [[ $# -ge 2 ]] || fail "--version requires a value"
            version_input=$2
            shift 2
            ;;
        --version=*)
            version_input=${1#--version=}
            shift
            ;;
        --output-dir|--package-dir)
            [[ $# -ge 2 ]] || fail "$1 requires a directory"
            output_dir=$2
            shift 2
            ;;
        --output-dir=*|--package-dir=*)
            output_dir=${1#*=}
            shift
            ;;
        --runtime)
            [[ $# -ge 2 ]] || fail "--runtime requires docker or podman"
            runtime=$2
            shift 2
            ;;
        --runtime=*)
            runtime=${1#--runtime=}
            shift
            ;;
        --image)
            [[ $# -ge 2 ]] || fail "--image requires a container image"
            image=$2
            shift 2
            ;;
        --image=*)
            image=${1#--image=}
            shift
            ;;
        --no-container)
            allow_container=false
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            fail "unknown option: $1"
            ;;
    esac
done

cd "$repo_root"

if ! command -v xbps-create >/dev/null 2>&1; then
    if [[ "$allow_container" != true ]]; then
        fail "missing required tool: xbps-create"
    fi
    case "$runtime" in
        docker|podman) ;;
        *) fail "--runtime must be docker or podman: $runtime" ;;
    esac
    command -v "$runtime" >/dev/null 2>&1 || fail "missing container runtime: $runtime"

    volume_suffix=:rw
    if [[ "$runtime" == podman ]]; then
        volume_suffix=:rw,Z
    fi

    cmd=(./scripts/package-void.sh --output-dir "$output_dir" --no-container)
    if [[ -n "$version_input" ]]; then
        cmd+=(--version "$version_input")
    fi

    printf 'xbps-create not found; building Void package in %s with %s\n' "$image" "$runtime"
    command_string=$(printf ' %q' "${cmd[@]}")
    "$runtime" run --rm -i \
        -v "$repo_root:/repo$volume_suffix" \
        -w /repo \
        "$image" \
        sh -lc "mkdir -p /etc/xbps.d; printf '%s\\n' 'repository=https://repo-default.voidlinux.org/current' > /etc/xbps.d/00-repository-main.conf; xbps-install -Syu -y xbps || xbps-install -Syu -y xbps; xbps-install -S -y bash; exec bash -lc $(quote "$command_string")"
    exit $?
fi

for tool in xbps-create xbps-rindex sha256sum mktemp cp find sort; do
    command -v "$tool" >/dev/null 2>&1 || fail "missing required tool: $tool"
done

version_args=()
if [[ -n "$version_input" ]]; then
    version_args=("$version_input")
fi
version=$("$script_dir/package-version.sh" "${version_args[@]}")
revision=1
pkgver="dec-fonts-${version}_${revision}"

mkdir -p "$output_dir"
output_dir=$(cd "$output_dir" && pwd)
workdir=$(mktemp -d "$output_dir/.voidbuild.XXXXXX")
trap 'rm -rf "$workdir"' EXIT
root="$workdir/root"

"$script_dir/stage-linux-package.sh" --format void --destdir "$root"

(
    cd "$output_dir"
    rm -f "dec-fonts-${version}_${revision}.noarch.xbps" \
          "dec-fonts-${version}_${revision}.noarch.xbps.sig" \
          "dec-fonts-${version}_${revision}.noarch.xbps.sha256" \
          ./*-repodata ./*-repodata.sig
    xbps-create \
        -A noarch \
        -n "$pkgver" \
        -s "DEC VT220 bitmap fonts" \
        -S "Bitmap fonts generated from a DEC VT220 ROM recreation for X core-font clients, fontconfig/Xft applications, and the Linux console." \
        -D "fontconfig>=0" \
        -H "https://github.com/htayj/DEC-Fonts" \
        -l "MIT" \
        -m "DEC-Fonts maintainers <noreply@example.invalid>" \
        -t "fonts" \
        -F "/etc/fonts/conf.d/75-dec-fonts.conf" \
        "$root" >/dev/null
    xbps-rindex -f -a "dec-fonts-${version}_${revision}.noarch.xbps" >/dev/null
    sha256sum "dec-fonts-${version}_${revision}.noarch.xbps" > "dec-fonts-${version}_${revision}.noarch.xbps.sha256"
)

echo "wrote $output_dir/dec-fonts-${version}_${revision}.noarch.xbps"
echo "wrote $output_dir/dec-fonts-${version}_${revision}.noarch.xbps.sha256"
