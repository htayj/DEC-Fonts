#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
usage: scripts/package-rpm.sh [--version VERSION] [--output-dir DIR]

Build dec-fonts-<version>-1.noarch.rpm.  Defaults to dist/packages/rpm.
USAGE
}

fail() {
    echo "package-rpm: $*" >&2
    exit 1
}

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
version_input=${VERSION:-}
output_dir=${RPM_PACKAGE_DIR:-${DIST_PACKAGE_DIR:-dist/packages}/rpm}

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

for tool in rpmbuild sha256sum mktemp cp mkdir; do
    command -v "$tool" >/dev/null 2>&1 || fail "missing required tool: $tool"
done

version_args=()
if [[ -n "$version_input" ]]; then
    version_args=("$version_input")
fi
version=$("$script_dir/package-version.sh" "${version_args[@]}")
[[ "$version" != *-* ]] || fail "RPM Version must not contain '-': $version"

mkdir -p "$output_dir"
output_dir=$(cd "$output_dir" && pwd)
workdir=$(mktemp -d "$output_dir/.rpmbuild.XXXXXX")
trap 'rm -rf "$workdir"' EXIT
topdir="$workdir/rpmbuild"
mkdir -p "$topdir/BUILD" "$topdir/BUILDROOT" "$topdir/RPMS" "$topdir/SOURCES" "$topdir/SPECS" "$topdir/SRPMS"
spec_path="$topdir/SPECS/dec-fonts.spec"

cat > "$spec_path" <<SPEC
%global debug_package %{nil}
Name: dec-fonts
Version: $version
Release: 1
Summary: DEC VT220 bitmap fonts
License: LicenseRef-Unknown
URL: https://github.com/htayj/DEC-Fonts
BuildArch: noarch
Requires: fontconfig
AutoReqProv: no

%description
Bitmap fonts generated from a DEC VT220 ROM recreation for X core-font
clients, fontconfig/Xft applications, and the Linux console.

%prep

%build

%install
rm -rf "%{buildroot}"
"$script_dir/stage-linux-package.sh" --format rpm --destdir "%{buildroot}"

%files
%dir /usr/share/fonts/dec-fonts
%dir /usr/share/fonts/dec-fonts/bdf
/usr/share/fonts/dec-fonts/bdf/*
%dir /usr/share/fonts/dec-fonts/otb
/usr/share/fonts/dec-fonts/otb/*
%dir /usr/lib/kbd/consolefonts/dec-fonts
/usr/lib/kbd/consolefonts/dec-fonts/*
%dir /usr/share/dec-fonts
/usr/share/dec-fonts/dec.set
/usr/share/fontconfig/conf.avail/75-dec-fonts.conf
%config(noreplace) /etc/fonts/conf.d/75-dec-fonts.conf
/usr/share/doc/dec-fonts/README.org

%changelog
* Mon Nov 11 2024 DEC-Fonts maintainers <noreply@example.invalid> - $version-1
- Automated package build
SPEC

rpmbuild -bb "$spec_path" \
    --define "_topdir $topdir" \
    --define "_build_id_links none"

built_rpm="$topdir/RPMS/noarch/dec-fonts-$version-1.noarch.rpm"
[[ -f "$built_rpm" ]] || fail "rpmbuild did not produce expected RPM: $built_rpm"
package_path="$output_dir/$(basename "$built_rpm")"
checksum_path="$package_path.sha256"
rm -f "$package_path" "$checksum_path"
cp -f "$built_rpm" "$package_path"
(
    cd "$output_dir"
    sha256sum "$(basename "$package_path")" > "$(basename "$checksum_path")"
)

echo "wrote $package_path"
echo "wrote $checksum_path"
