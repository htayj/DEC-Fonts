#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)

for argument in "$@"; do
    case "$argument" in
        --dist-root|--dist-root=*)
            echo "scripts/build-fonts.sh does not support $argument because convert.bash writes to ./dist." >&2
            echo "Run scripts/generate-fonts.sh separately if you need a custom generator dist root." >&2
            exit 2
            ;;
    esac
done

cd "$repo_root"

./scripts/generate-fonts.sh "$@"
./convert.bash
python3 scripts/check-bdf-metadata.py dist/fonts/bdf
