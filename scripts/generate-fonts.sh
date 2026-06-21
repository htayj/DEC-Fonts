#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
quicklisp_setup=${QUICKLISP_SETUP:-$HOME/quicklisp/setup.lisp}
load_mode=${DEC_FONTS_ASDF_LOAD_MODE:-quicklisp}

cd "$repo_root"

if ! command -v sbcl >/dev/null 2>&1; then
    echo "missing required tool: sbcl" >&2
    exit 1
fi

case "$load_mode" in
    quicklisp)
        if [[ ! -f "$quicklisp_setup" ]]; then
            echo "missing Quicklisp setup file: $quicklisp_setup" >&2
            echo "Install Quicklisp or set QUICKLISP_SETUP to an existing setup.lisp." >&2
            exit 1
        fi

        exec sbcl \
            --load "$quicklisp_setup" \
            --eval '(asdf:load-asd (merge-pathnames "dec-fonts.asd" (uiop:getcwd)))' \
            --eval '(ql:quickload :dec-fonts)' \
            --eval '(dec-fonts.generator:cli-main)' \
            --quit -- "$@"
        ;;
    asdf|nix)
        exec sbcl \
            --eval '(require :asdf)' \
            --eval '(asdf:load-asd (merge-pathnames "dec-fonts.asd" (uiop:getcwd)))' \
            --eval '(asdf:load-system :dec-fonts)' \
            --eval '(dec-fonts.generator:cli-main)' \
            --quit -- "$@"
        ;;
    *)
        echo "DEC_FONTS_ASDF_LOAD_MODE must be quicklisp, asdf, or nix: $load_mode" >&2
        exit 2
        ;;
esac
