#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
usage: scripts/test-nix-flake-container.sh [--runtime docker|podman] [--image IMAGE] [--arg ARG ...]

Run the Nix flake check in a clean Nix container. Extra --arg values are
appended to the nix flake check command.
USAGE
}

fail() {
    echo "test-nix-flake-container: $*" >&2
    exit 1
}

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
runtime=${CONTAINER_RUNTIME:-docker}
image=${NIX_CONTAINER_IMAGE:-docker.io/nixos/nix:latest}
extra_args=()

while [[ $# -gt 0 ]]; do
    case "$1" in
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
        --arg)
            [[ $# -ge 2 ]] || fail "--arg requires a nix argument"
            extra_args+=("$2")
            shift 2
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

case "$runtime" in
    docker|podman) ;;
    *) fail "--runtime must be docker or podman: $runtime" ;;
esac
command -v "$runtime" >/dev/null 2>&1 || fail "missing container runtime: $runtime"

volume_suffix=:ro
if [[ "$runtime" == podman ]]; then
    volume_suffix=:ro,Z
fi

container_args=(
    --extra-experimental-features
    "nix-command flakes"
    flake
    check
    path:/repo
    --no-write-lock-file
)
container_args+=("${extra_args[@]}")

printf 'Testing Nix flake in %s with %s\n' "$image" "$runtime"
printf 'nix'
printf ' %q' "${container_args[@]}"
printf '\n'

"$runtime" run --rm -i \
    -v "$repo_root:/repo$volume_suffix" \
    "$image" \
    nix "${container_args[@]}"
