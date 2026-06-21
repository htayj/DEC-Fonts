#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
usage: scripts/test-gentoo-package-container.sh [--runtime docker|podman] [--image IMAGE]

Smoke-test the Gentoo live ebuild in a gentoo/stage3 container using the
current checkout as DEC_FONTS_SOURCE_DIR.  The test runs an emerge --pretend
check for overlay metadata/keywording, then uses ebuild install/qmerge for a
practical package-image check.  It skips fontconfig runtime checks because the
minimal stage3 image does not include fontconfig.
USAGE
}

fail() {
    echo "test-gentoo-package-container: $*" >&2
    exit 1
}

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
runtime=${CONTAINER_RUNTIME:-docker}
image=${GENTOO_CONTAINER_IMAGE:-docker.io/gentoo/stage3:latest}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --runtime)
            [[ $# -ge 2 ]] || fail "--runtime requires docker or podman"
            runtime=$2
            shift 2
            ;;
        --runtime=*)
            runtime=${1#--runtime=}
            shift
            ;;
        --image)
            [[ $# -ge 2 ]] || fail "--image requires a container image"
            image=$2
            shift 2
            ;;
        --image=*)
            image=${1#--image=}
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

case "$runtime" in
    docker|podman) ;;
    *) fail "--runtime must be docker or podman: $runtime" ;;
esac
command -v "$runtime" >/dev/null 2>&1 || fail "missing container runtime: $runtime"

volume_suffix=:ro
if [[ "$runtime" == podman ]]; then
    volume_suffix=:ro,Z
fi

echo "Testing Gentoo ebuild in $image with $runtime"
"$runtime" run --rm -i \
    -v "$repo_root:/repo$volume_suffix" \
    "$image" bash -lc '
set -euo pipefail
emerge-webrsync --quiet >/tmp/emerge-webrsync.log 2>&1 || { cat /tmp/emerge-webrsync.log >&2; exit 1; }
rm -rf /tmp/dec-fonts-overlay
mkdir -p /tmp/dec-fonts-overlay
cp -a /repo/packaging/gentoo/. /tmp/dec-fonts-overlay/
mkdir -p /etc/portage/repos.conf
cat >/etc/portage/repos.conf/dec-fonts.conf <<EOF
[dec-fonts]
location = /tmp/dec-fonts-overlay
masters = gentoo
auto-sync = no
EOF
if [ -f /etc/portage/package.accept_keywords ]; then
    printf "%s\n" "=media-fonts/dec-fonts-9999 **" >> /etc/portage/package.accept_keywords
else
    mkdir -p /etc/portage/package.accept_keywords
    printf "%s\n" "=media-fonts/dec-fonts-9999 **" > /etc/portage/package.accept_keywords/dec-fonts
fi
DEC_FONTS_SOURCE_DIR=/repo emerge -p =media-fonts/dec-fonts-9999
cd /tmp/dec-fonts-overlay/media-fonts/dec-fonts
DEC_FONTS_SOURCE_DIR=/repo ebuild dec-fonts-9999.ebuild manifest clean install qmerge
bash /repo/scripts/verify-linux-package-install.sh --format gentoo --skip-fontconfig
'
