#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
usage: scripts/verify-linux-package-install.sh --format deb|rpm|arch

Run inside an installed package container to verify dec-fonts files and
fontconfig visibility.
USAGE
}

fail() {
    echo "verify-linux-package-install: $*" >&2
    exit 1
}

format=
while [[ $# -gt 0 ]]; do
    case "$1" in
        --format)
            [[ $# -ge 2 ]] || fail "--format requires deb, rpm, or arch"
            format=$2
            shift 2
            ;;
        --format=*)
            format=${1#--format=}
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
    deb|rpm|arch) ;;
    "") fail "--format is required" ;;
    *) fail "--format must be deb, rpm, or arch: $format" ;;
esac

need_tool() {
    command -v "$1" >/dev/null 2>&1 || fail "missing required tool: $1"
}

assert_file() {
    local path=$1
    [[ -f "$path" ]] || fail "missing expected file: $path"
}

assert_nonempty_file() {
    local path=$1
    assert_file "$path"
    [[ -s "$path" ]] || fail "expected non-empty file: $path"
}

assert_dir() {
    local path=$1
    [[ -d "$path" ]] || fail "missing expected directory: $path"
}

assert_glob() {
    local pattern=$1
    compgen -G "$pattern" >/dev/null || fail "missing files matching: $pattern"
}

need_tool find
need_tool grep
need_tool sort
need_tool fc-cache
need_tool fc-query
need_tool fc-list
need_tool fc-match

case "$format" in
    deb)
        need_tool dpkg-query
        dpkg-query -W -f='${db:Status-Abbrev} ${binary:Package} ${Version}\n' dec-fonts | grep -q '^ii ' || \
            fail "dec-fonts is not installed according to dpkg"
        psf_dir=/usr/share/consolefonts/dec-fonts
        ;;
    rpm)
        need_tool rpm
        rpm -q dec-fonts >/dev/null || fail "dec-fonts is not installed according to rpm"
        psf_dir=/usr/lib/kbd/consolefonts/dec-fonts
        ;;
    arch)
        need_tool pacman
        if ! pacman -Q dec-fonts-git >/dev/null 2>&1 && ! pacman -Q dec-fonts >/dev/null 2>&1; then
            fail "dec-fonts-git/dec-fonts is not installed according to pacman"
        fi
        psf_dir=/usr/share/kbd/consolefonts/dec-fonts
        ;;
esac

assert_dir /usr/share/fonts/dec-fonts
assert_dir /usr/share/fonts/dec-fonts/bdf
assert_dir /usr/share/fonts/dec-fonts/otb
assert_dir "$psf_dir"
assert_glob '/usr/share/fonts/dec-fonts/bdf/*.bdf'
assert_glob '/usr/share/fonts/dec-fonts/otb/*.otb'
assert_glob "$psf_dir/*.psf"
assert_nonempty_file /usr/share/fonts/dec-fonts/bdf/fonts.dir
assert_nonempty_file /usr/share/fonts/dec-fonts/bdf/fonts.scale
assert_nonempty_file /usr/share/dec-fonts/dec.set
if [[ "$format" == arch ]]; then
    # Some minimal Arch container images configure pacman NoExtract rules for
    # /usr/share/doc.  The package should still own the README path even when
    # the test image elects not to extract it.
    if [[ -f /usr/share/doc/dec-fonts/README.org ]]; then
        assert_nonempty_file /usr/share/doc/dec-fonts/README.org
    elif ! pacman -Qlq dec-fonts-git 2>/dev/null | grep -Fxq /usr/share/doc/dec-fonts/README.org && \
         ! pacman -Qlq dec-fonts 2>/dev/null | grep -Fxq /usr/share/doc/dec-fonts/README.org; then
        fail "package does not own expected doc file: /usr/share/doc/dec-fonts/README.org"
    else
        echo "doc file omitted by pacman NoExtract: /usr/share/doc/dec-fonts/README.org"
    fi
else
    assert_nonempty_file /usr/share/doc/dec-fonts/README.org
fi
assert_nonempty_file /usr/share/fontconfig/conf.avail/75-dec-fonts.conf
assert_nonempty_file /etc/fonts/conf.d/75-dec-fonts.conf

if ! head -n 1 /usr/share/fonts/dec-fonts/bdf/fonts.dir | grep -Eq '^[0-9]+$'; then
    fail "fonts.dir does not start with an XLFD font count"
fi
if ! head -n 1 /usr/share/fonts/dec-fonts/bdf/fonts.scale | grep -Eq '^[0-9]+$'; then
    fail "fonts.scale does not start with an XLFD font count"
fi

otb_file=$(find /usr/share/fonts/dec-fonts/otb -maxdepth 1 -type f -name '*.otb' | sort | head -n 1)
[[ -n "$otb_file" ]] || fail "no OTB font found"

echo "fc-cache: refreshing /usr/share/fonts/dec-fonts"
fc-cache -f /usr/share/fonts/dec-fonts

echo "fc-query evidence for $otb_file:"
fc_query_output=$(fc-query --format 'file=%{file}\nfamily=%{family}\nfullname=%{fullname}\nfoundry=%{foundry}\nfontformat=%{fontformat}\n' "$otb_file")
printf '%s\n' "$fc_query_output"
printf '%s\n' "$fc_query_output" | grep -Eiq 'vt220|digital|digi' || \
    fail "fc-query did not expose DIGITAL/VT220 metadata for $otb_file"

echo "fc-list evidence for packaged font files:"
font_list=$(fc-list : file family fullname foundry 2>/dev/null | grep -F '/usr/share/fonts/dec-fonts/' || true)
[[ -n "$font_list" ]] || fail "fontconfig did not list any files under /usr/share/fonts/dec-fonts"
printf '%s\n' "$font_list"
printf '%s\n' "$font_list" | grep -Eiq 'vt220|digital|digi' || \
    fail "fc-list did not expose DIGITAL/VT220 metadata"

echo "fc-match evidence for vt220:"
font_match=$(fc-match -f 'file=%{file}\nfamily=%{family}\nfullname=%{fullname}\nfoundry=%{foundry}\n' 'vt220' || true)
printf '%s\n' "$font_match"
printf '%s\n' "$font_match" | grep -Fq '/usr/share/fonts/dec-fonts/' || \
    fail "fc-match vt220 did not resolve to a packaged DEC font"

echo "dec-fonts $format package verification passed"
