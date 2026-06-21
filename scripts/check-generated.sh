#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: $0 BASELINE_DIR" >&2
    echo "BASELINE_DIR must contain cl-generated.sha256 captured before refactoring." >&2
    exit 2
fi

baseline_dir=$1
manifest="$baseline_dir/cl-generated.sha256"
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

if [[ ! -f "$manifest" ]]; then
    echo "missing manifest: $manifest" >&2
    exit 2
fi

cd "$repo_root"
sbcl --load "$HOME/quicklisp/setup.lisp" \
    --eval '(asdf:load-asd (merge-pathnames "dec-fonts.asd" (uiop:getcwd)))' \
    --eval '(ql:quickload :dec-fonts)' \
    --eval '(dec-fonts.generator:main)' \
    --quit
sha256sum -c "$manifest"
