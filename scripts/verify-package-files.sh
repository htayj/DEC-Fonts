#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
usage: scripts/verify-package-files.sh --layout fhs|guix --prefix PATH --psf-dir PATH [--allow-missing-doc] [--skip-fontconfig]

Verify DEC-Fonts files and, unless skipped, fontconfig visibility under an
installed package root or a Guix store output.
USAGE
}

fail() {
    echo "verify-package-files: $*" >&2
    exit 1
}

layout=fhs
prefix=/
psf_dir=
allow_missing_doc=false
skip_fontconfig=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --layout)
            [[ $# -ge 2 ]] || fail "--layout requires fhs or guix"
            layout=$2
            shift 2
            ;;
        --layout=*)
            layout=${1#--layout=}
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
        --psf-dir)
            [[ $# -ge 2 ]] || fail "--psf-dir requires a path"
            psf_dir=$2
            shift 2
            ;;
        --psf-dir=*)
            psf_dir=${1#--psf-dir=}
            shift
            ;;
        --allow-missing-doc)
            allow_missing_doc=true
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

case "$layout" in
    fhs|guix) ;;
    *) fail "--layout must be fhs or guix: $layout" ;;
esac

join_path() {
    local base=${1%/}
    local rest=${2#/}
    if [[ -z "$base" || "$base" == / ]]; then
        printf '/%s' "$rest"
    else
        printf '%s/%s' "$base" "$rest"
    fi
}

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
need_tool head
need_tool sort
need_tool mktemp

case "$layout" in
    fhs)
        font_root=$(join_path "$prefix" /usr/share/fonts/dec-fonts)
        data_file=$(join_path "$prefix" /usr/share/dec-fonts/dec.set)
        doc_file=$(join_path "$prefix" /usr/share/doc/dec-fonts/README.org)
        fontconfig_available=$(join_path "$prefix" /usr/share/fontconfig/conf.avail/75-dec-fonts.conf)
        fontconfig_enabled=$(join_path "$prefix" /etc/fonts/conf.d/75-dec-fonts.conf)
        ;;
    guix)
        font_root=$(join_path "$prefix" /share/fonts/dec-fonts)
        data_file=$(join_path "$prefix" /share/dec-fonts/dec.set)
        doc_file=$(join_path "$prefix" /share/doc/dec-fonts/README.org)
        fontconfig_available=$(join_path "$prefix" /share/fontconfig/conf.avail/75-dec-fonts.conf)
        fontconfig_enabled=$(join_path "$prefix" /etc/fonts/conf.d/75-dec-fonts.conf)
        ;;
esac

if [[ -z "$psf_dir" ]]; then
    case "$layout" in
        guix) psf_dir=$(join_path "$prefix" /share/consolefonts/dec-fonts) ;;
        fhs) fail "--psf-dir is required for fhs layout" ;;
    esac
fi

bdf_dir="$font_root/bdf"
otb_dir="$font_root/otb"

assert_dir "$font_root"
assert_dir "$bdf_dir"
assert_dir "$otb_dir"
assert_dir "$psf_dir"
assert_glob "$bdf_dir/*.bdf"
assert_glob "$otb_dir/*.otb"
assert_glob "$psf_dir/*.psf"
assert_nonempty_file "$bdf_dir/fonts.dir"
assert_nonempty_file "$bdf_dir/fonts.scale"
assert_nonempty_file "$data_file"
if [[ -f "$doc_file" ]]; then
    assert_nonempty_file "$doc_file"
elif [[ "$allow_missing_doc" == true ]]; then
    echo "doc file omitted by package manager policy: $doc_file"
else
    fail "missing expected file: $doc_file"
fi
assert_nonempty_file "$fontconfig_available"
assert_nonempty_file "$fontconfig_enabled"

if ! head -n 1 "$bdf_dir/fonts.dir" | grep -Eq '^[0-9]+$'; then
    fail "fonts.dir does not start with an XLFD font count"
fi
if ! head -n 1 "$bdf_dir/fonts.scale" | grep -Eq '^[0-9]+$'; then
    fail "fonts.scale does not start with an XLFD font count"
fi

if [[ "$skip_fontconfig" == true ]]; then
    echo "fontconfig checks skipped"
    exit 0
fi

need_tool fc-cache
need_tool fc-query
need_tool fc-list
need_tool fc-match

otb_file=$(find "$otb_dir" -maxdepth 1 -type f -name '*.otb' | sort | head -n 1)
[[ -n "$otb_file" ]] || fail "no OTB font found"

echo "fc-query evidence for $otb_file:"
fc_query_output=$(fc-query --format 'file=%{file}\nfamily=%{family}\nfullname=%{fullname}\nfoundry=%{foundry}\nfontformat=%{fontformat}\n' "$otb_file")
printf '%s\n' "$fc_query_output"
printf '%s\n' "$fc_query_output" | grep -Eiq 'vt220|digital|digi' || \
    fail "fc-query did not expose DIGITAL/VT220 metadata for $otb_file"

fontconfig_tmp=$(mktemp -d)
trap 'rm -rf "$fontconfig_tmp"' EXIT
mkdir -p "$fontconfig_tmp/cache"
cat > "$fontconfig_tmp/fonts.conf" <<XML
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <dir>$font_root</dir>
  <dir>$bdf_dir</dir>
  <dir>$otb_dir</dir>
  <include ignore_missing="yes">$fontconfig_available</include>
  <cachedir>$fontconfig_tmp/cache</cachedir>
</fontconfig>
XML

fontconfig_env=(env FONTCONFIG_FILE="$fontconfig_tmp/fonts.conf" XDG_CACHE_HOME="$fontconfig_tmp/cache")

echo "fc-cache: refreshing $font_root"
"${fontconfig_env[@]}" fc-cache -f "$font_root"

echo "fc-list evidence for packaged font files:"
font_list=$("${fontconfig_env[@]}" fc-list : file family fullname foundry 2>/dev/null | grep -F "$font_root/" || true)
[[ -n "$font_list" ]] || fail "fontconfig did not list any files under $font_root"
printf '%s\n' "$font_list"
printf '%s\n' "$font_list" | grep -Eiq 'vt220|digital|digi' || \
    fail "fc-list did not expose DIGITAL/VT220 metadata"

echo "fc-match evidence for vt220:"
font_match=$("${fontconfig_env[@]}" fc-match -f 'file=%{file}\nfamily=%{family}\nfullname=%{fullname}\nfoundry=%{foundry}\n' 'vt220' || true)
printf '%s\n' "$font_match"
printf '%s\n' "$font_match" | grep -Fq "$font_root/" || \
    fail "fc-match vt220 did not resolve to a packaged DEC font"

echo "dec-fonts file/fontconfig verification passed for $font_root"
