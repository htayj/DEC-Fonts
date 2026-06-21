#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
usage: scripts/stage-linux-package.sh --format deb|rpm|arch --destdir DIR

Stage generated DEC-Fonts outputs into a Linux package root.
USAGE
}

fail() {
    echo "stage-linux-package: $*" >&2
    exit 1
}

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
format=
destdir=

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
        --destdir)
            [[ $# -ge 2 ]] || fail "--destdir requires a directory"
            destdir=$2
            shift 2
            ;;
        --destdir=*)
            destdir=${1#--destdir=}
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

[[ -n "$destdir" ]] || fail "--destdir is required"
[[ "$destdir" != "/" ]] || fail "refusing to stage directly into /"

cd "$repo_root"
umask 022

for tool in install mkdir cp find sort dirname chmod; do
    command -v "$tool" >/dev/null 2>&1 || fail "missing required tool: $tool"
done

require_file() {
    local path=$1
    [[ -f "$path" ]] || fail "missing required file: $path"
}

require_glob() {
    local pattern=$1
    compgen -G "$pattern" >/dev/null || fail "missing files matching: $pattern"
}

copy_glob() {
    local src_dir=$1
    local pattern=$2
    local dst_dir=$3
    mkdir -p "$dst_dir"

    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(find "$src_dir" -maxdepth 1 -type f -name "$pattern" -print0 | sort -z)

    [[ ${#files[@]} -gt 0 ]] || fail "missing files matching: $src_dir/$pattern"
    install -m 0644 "${files[@]}" "$dst_dir/"
}

require_file README.org
require_file dist/dec.set
require_glob 'dist/fonts/bdf/*.bdf'
require_file dist/fonts/bdf/fonts.dir
require_file dist/fonts/bdf/fonts.scale
require_glob 'dist/fonts/otb/*.otb'
require_glob 'dist/fonts/psf/*.psf'

font_root="$destdir/usr/share/fonts/dec-fonts"
bdf_dest="$font_root/bdf"
otb_dest="$font_root/otb"
case "$format" in
    deb) psf_dest="$destdir/usr/share/consolefonts/dec-fonts" ;;
    rpm) psf_dest="$destdir/usr/lib/kbd/consolefonts/dec-fonts" ;;
    arch) psf_dest="$destdir/usr/share/kbd/consolefonts/dec-fonts" ;;
esac

copy_glob dist/fonts/bdf '*.bdf' "$bdf_dest"
install -m 0644 dist/fonts/bdf/fonts.dir dist/fonts/bdf/fonts.scale "$bdf_dest/"
copy_glob dist/fonts/otb '*.otb' "$otb_dest"
copy_glob dist/fonts/psf '*.psf' "$psf_dest"

install -D -m 0644 dist/dec.set "$destdir/usr/share/dec-fonts/dec.set"
install -D -m 0644 README.org "$destdir/usr/share/doc/dec-fonts/README.org"

fontconfig_available="$destdir/usr/share/fontconfig/conf.avail/75-dec-fonts.conf"
fontconfig_enabled="$destdir/etc/fonts/conf.d/75-dec-fonts.conf"
mkdir -p "$(dirname "$fontconfig_available")" "$(dirname "$fontconfig_enabled")"
cat > "$fontconfig_available" <<'XML'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <description>DEC VT220 bitmap fonts</description>
  <dir>/usr/share/fonts/dec-fonts</dir>
  <dir>/usr/share/fonts/dec-fonts/bdf</dir>
  <dir>/usr/share/fonts/dec-fonts/otb</dir>
  <selectfont>
    <acceptfont>
      <pattern>
        <patelt name="family"><string>vt220</string></patelt>
      </pattern>
    </acceptfont>
  </selectfont>
</fontconfig>
XML
chmod 0644 "$fontconfig_available"
cp -p "$fontconfig_available" "$fontconfig_enabled"

echo "staged $format package root at $destdir"
