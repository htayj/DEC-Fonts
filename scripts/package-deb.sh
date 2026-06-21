#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
usage: scripts/package-deb.sh [--version VERSION] [--output-dir DIR]

Build dec-fonts_<version>-1_all.deb.  Defaults to dist/packages/deb.
USAGE
}

fail() {
    echo "package-deb: $*" >&2
    exit 1
}

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
version_input=${VERSION:-}
output_dir=${DEB_PACKAGE_DIR:-${DIST_PACKAGE_DIR:-dist/packages}/deb}

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

for tool in dpkg-deb sha256sum mktemp du awk; do
    command -v "$tool" >/dev/null 2>&1 || fail "missing required tool: $tool"
done

version_args=()
if [[ -n "$version_input" ]]; then
    version_args=("$version_input")
fi
version=$("$script_dir/package-version.sh" "${version_args[@]}")
package_version="$version-1"
package_name="dec-fonts_${package_version}_all.deb"

mkdir -p "$output_dir"
output_dir=$(cd "$output_dir" && pwd)
workdir=$(mktemp -d "$output_dir/.debbuild.XXXXXX")
trap 'rm -rf "$workdir"' EXIT
root="$workdir/root"

"$script_dir/stage-linux-package.sh" --format deb --destdir "$root"

mkdir -p "$root/DEBIAN"
installed_size=$(du -sk "$root/usr" "$root/etc" 2>/dev/null | awk '{ total += $1 } END { print (total > 0 ? total : 1) }')
cat > "$root/DEBIAN/control" <<CONTROL
Package: dec-fonts
Version: $package_version
Section: fonts
Priority: optional
Architecture: all
Maintainer: DEC-Fonts maintainers <noreply@example.invalid>
Installed-Size: $installed_size
Depends: fontconfig
Multi-Arch: foreign
Homepage: https://github.com/htayj/DEC-Fonts
Description: DEC VT220 bitmap fonts
 Bitmap fonts generated from a DEC VT220 ROM recreation for X core-font
 clients, fontconfig/Xft applications, and the Linux console.
CONTROL
chmod 0644 "$root/DEBIAN/control"
cat > "$root/DEBIAN/conffiles" <<'CONFFILES'
/etc/fonts/conf.d/75-dec-fonts.conf
CONFFILES
chmod 0644 "$root/DEBIAN/conffiles"

package_path="$output_dir/$package_name"
checksum_path="$package_path.sha256"
rm -f "$package_path" "$checksum_path"
dpkg-deb --root-owner-group --build "$root" "$package_path"
(
    cd "$output_dir"
    sha256sum "$package_name" > "$(basename "$checksum_path")"
)

echo "wrote $package_path"
echo "wrote $checksum_path"
