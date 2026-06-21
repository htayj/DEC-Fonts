#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
usage: scripts/verify-linux-package-install.sh --format deb|rpm|arch|gentoo|void|guix [--prefix PATH] [--skip-package-db] [--skip-fontconfig]

Run inside an installed package container to verify dec-fonts package manager
state, files, and fontconfig visibility.  Guix mode validates a store output
and requires --prefix PATH.
USAGE
}

fail() {
    echo "verify-linux-package-install: $*" >&2
    exit 1
}

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
format=
prefix=
skip_package_db=false
skip_fontconfig=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --format)
            [[ $# -ge 2 ]] || fail "--format requires deb, rpm, arch, gentoo, void, or guix"
            format=$2
            shift 2
            ;;
        --format=*)
            format=${1#--format=}
            shift
            ;;
        --prefix)
            [[ $# -ge 2 ]] || fail "--prefix requires a path"
            prefix=$2
            shift 2
            ;;
        --prefix=*)
            prefix=${1#--prefix=}
            shift
            ;;
        --skip-package-db)
            skip_package_db=true
            shift
            ;;
        --skip-fontconfig)
            skip_fontconfig=true
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

case "$format" in
    deb|rpm|arch|gentoo|void|guix) ;;
    "") fail "--format is required" ;;
    *) fail "--format must be deb, rpm, arch, gentoo, void, or guix: $format" ;;
esac

need_tool() {
    command -v "$1" >/dev/null 2>&1 || fail "missing required tool: $1"
}

allow_missing_doc=false
layout=fhs
prefix=${prefix:-/}
case "$format" in
    deb)
        psf_dir=/usr/share/consolefonts/dec-fonts
        if [[ "$skip_package_db" != true ]]; then
            need_tool dpkg-query
            dpkg-query -W -f='${db:Status-Abbrev} ${binary:Package} ${Version}\n' dec-fonts | grep -q '^ii ' || \
                fail "dec-fonts is not installed according to dpkg"
        fi
        ;;
    rpm)
        psf_dir=/usr/lib/kbd/consolefonts/dec-fonts
        if [[ "$skip_package_db" != true ]]; then
            need_tool rpm
            rpm -q dec-fonts >/dev/null || fail "dec-fonts is not installed according to rpm"
        fi
        ;;
    arch)
        psf_dir=/usr/share/kbd/consolefonts/dec-fonts
        if [[ "$skip_package_db" != true ]]; then
            need_tool pacman
            if ! pacman -Q dec-fonts-git >/dev/null 2>&1 && ! pacman -Q dec-fonts >/dev/null 2>&1; then
                fail "dec-fonts-git/dec-fonts is not installed according to pacman"
            fi
            # Some minimal Arch container images configure pacman NoExtract
            # rules for /usr/share/doc.  The package should still own the
            # README path even when the test image elects not to extract it.
            if [[ ! -f /usr/share/doc/dec-fonts/README.org ]]; then
                if ! pacman -Qlq dec-fonts-git 2>/dev/null | grep -Fxq /usr/share/doc/dec-fonts/README.org && \
                   ! pacman -Qlq dec-fonts 2>/dev/null | grep -Fxq /usr/share/doc/dec-fonts/README.org; then
                    fail "package does not own expected doc file: /usr/share/doc/dec-fonts/README.org"
                fi
                allow_missing_doc=true
            fi
        fi
        ;;
    gentoo)
        psf_dir=/usr/share/consolefonts/dec-fonts
        if [[ "$skip_package_db" != true ]] && ! compgen -G '/var/db/pkg/media-fonts/dec-fonts-*' >/dev/null; then
            fail "dec-fonts is not installed according to Gentoo package database"
        fi
        ;;
    void)
        psf_dir=/usr/share/kbd/consolefonts/dec-fonts
        if [[ "$skip_package_db" != true ]]; then
            need_tool xbps-query
            xbps-query dec-fonts >/dev/null || fail "dec-fonts is not installed according to xbps"
        fi
        ;;
    guix)
        layout=guix
        [[ -n "$prefix" && "$prefix" != / ]] || fail "--prefix PATH is required for guix format"
        psf_dir="$prefix/share/consolefonts/dec-fonts"
        skip_package_db=true
        ;;
esac

args=(--layout "$layout" --prefix "$prefix" --psf-dir "$psf_dir")
[[ "$allow_missing_doc" == true ]] && args+=(--allow-missing-doc)
[[ "$skip_fontconfig" == true ]] && args+=(--skip-fontconfig)
bash "$script_dir/verify-package-files.sh" "${args[@]}"

echo "dec-fonts $format package verification passed"
