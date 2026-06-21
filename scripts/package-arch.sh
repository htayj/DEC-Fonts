#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
usage: scripts/package-arch.sh [--version VERSION] [--output-dir DIR]

Build dec-fonts-git-<version>-1-any.pkg.tar.* from the current checkout.
Defaults to dist/packages/arch.
USAGE
}

fail() {
    echo "package-arch: $*" >&2
    exit 1
}

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
version_input=${VERSION:-}
output_dir=${ARCH_PACKAGE_DIR:-${DIST_PACKAGE_DIR:-dist/packages}/arch}

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

for tool in makepkg sha256sum mktemp cp find sort; do
    command -v "$tool" >/dev/null 2>&1 || fail "missing required tool: $tool"
done

version_args=()
if [[ -n "$version_input" ]]; then
    version_args=("$version_input")
fi
version=$("$script_dir/package-version.sh" "${version_args[@]}")
[[ "$version" != *-* ]] || fail "Arch pkgver must not contain '-': $version"

mkdir -p "$output_dir"
output_dir=$(cd "$output_dir" && pwd)
workdir=$(mktemp -d "$output_dir/.archbuild.XXXXXX")
trap 'rm -rf "$workdir"' EXIT
builddir="$workdir/build"
pkgdest="$workdir/packages"
mkdir -p "$builddir" "$pkgdest"

cat > "$workdir/PKGBUILD" <<PKGBUILD
# Maintained in DEC-Fonts for local package smoke tests.  The AUR VCS
# PKGBUILD lives in packaging/aur/dec-fonts-git/PKGBUILD.
pkgname=dec-fonts-git
pkgver=$version
pkgrel=1
pkgdesc='DEC VT220 bitmap fonts'
arch=('any')
url='https://github.com/htayj/DEC-Fonts'
license=('MIT')
depends=('fontconfig')
optdepends=('kbd: Linux console setfont support')
provides=("dec-fonts=\$pkgver")
conflicts=('dec-fonts')
backup=('etc/fonts/conf.d/75-dec-fonts.conf')
options=('!strip')

package() {
    cd '$repo_root'
    ./scripts/stage-linux-package.sh --format arch --destdir "\$pkgdir"
}
PKGBUILD

(
    cd "$workdir"
    BUILDDIR="$builddir" PKGDEST="$pkgdest" makepkg --nodeps --force --noconfirm
)

mapfile -t built_packages < <(find "$pkgdest" -maxdepth 1 -type f -name 'dec-fonts-git-*.pkg.tar*' ! -name '*.sig' | sort)
[[ ${#built_packages[@]} -eq 1 ]] || fail "expected one Arch package, found ${#built_packages[@]}"

package_path="$output_dir/$(basename "${built_packages[0]}")"
checksum_path="$package_path.sha256"
rm -f "$package_path" "$checksum_path"
cp -f "${built_packages[0]}" "$package_path"
(
    cd "$output_dir"
    sha256sum "$(basename "$package_path")" > "$(basename "$checksum_path")"
)

echo "wrote $package_path"
echo "wrote $checksum_path"
