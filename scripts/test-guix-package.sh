#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
usage: scripts/test-guix-package.sh [--guix GUIX]

Build the local Guix dec-fonts package and verify its store output inside a
Guix container.
USAGE
}

fail() {
    echo "test-guix-package: $*" >&2
    exit 1
}

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
guix=${GUIX:-guix}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --guix)
            [[ $# -ge 2 ]] || fail "--guix requires a command"
            guix=$2
            shift 2
            ;;
        --guix=*)
            guix=${1#--guix=}
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

command -v "$guix" >/dev/null 2>&1 || fail "missing Guix command: $guix"

cd "$repo_root"
out=$("$guix" build -L packaging/guix dec-fonts --no-grafts)
[[ -n "$out" && -d "$out" ]] || fail "guix build did not return a store directory"

echo "built $out"
"$guix" shell --container --pure --network --expose="$out" \
    bash coreutils findutils grep sed fontconfig \
    -- bash -lc "cd $(printf '%q' "$repo_root") && bash ./scripts/verify-linux-package-install.sh --format guix --prefix $(printf '%q' "$out")"
