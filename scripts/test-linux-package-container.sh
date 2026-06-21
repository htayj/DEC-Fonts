#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
usage: scripts/test-linux-package-container.sh --runtime docker|podman --format deb|rpm|arch|void --package PATH [--image IMAGE]

Install a built dec-fonts package in a clean container and run
scripts/verify-linux-package-install.sh inside the container.
USAGE
}

fail() {
    echo "test-linux-package-container: $*" >&2
    exit 1
}

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
runtime=${CONTAINER_RUNTIME:-docker}
format=
package_path=
image=

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
        --format)
            [[ $# -ge 2 ]] || fail "--format requires deb, rpm, arch, or void"
            format=$2
            shift 2
            ;;
        --format=*)
            format=${1#--format=}
            shift
            ;;
        --package)
            [[ $# -ge 2 ]] || fail "--package requires a package path"
            package_path=$2
            shift 2
            ;;
        --package=*)
            package_path=${1#--package=}
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
case "$format" in
    deb|rpm|arch|void) ;;
    "") fail "--format is required" ;;
    *) fail "--format must be deb, rpm, arch, or void: $format" ;;
esac
[[ -n "$package_path" ]] || fail "--package is required"
command -v "$runtime" >/dev/null 2>&1 || fail "missing container runtime: $runtime"

if [[ "$package_path" != /* ]]; then
    package_path="$PWD/$package_path"
fi
[[ -f "$package_path" ]] || fail "package does not exist: $package_path"
package_dir=$(cd "$(dirname "$package_path")" && pwd)
package_basename=$(basename "$package_path")

if [[ -z "$image" ]]; then
    case "$format" in
        deb) image=debian:bookworm ;;
        rpm) image=fedora:latest ;;
        arch) image=archlinux:base-devel ;;
        void) image=${VOID_CONTAINER_IMAGE:-docker.io/voidlinux/voidlinux:latest} ;;
    esac
fi

volume_suffix=:ro
if [[ "$runtime" == podman ]]; then
    volume_suffix=:ro,Z
fi

echo "Testing $package_path in $image with $runtime"
"$runtime" run --rm -i \
    -e "FORMAT=$format" \
    -e "PACKAGE_BASENAME=$package_basename" \
    -v "$repo_root:/repo$volume_suffix" \
    -v "$package_dir:/packages$volume_suffix" \
    "$image" sh -s <<'CONTAINER'
set -eu
pkg="/packages/$PACKAGE_BASENAME"
[ -f "$pkg" ] || { echo "missing mounted package: $pkg" >&2; exit 1; }

case "$FORMAT" in
  deb)
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$pkg"
    ;;
  rpm)
    if command -v dnf5 >/dev/null 2>&1; then
      dnf5 -y --setopt=tsflags= install "$pkg"
    elif command -v dnf >/dev/null 2>&1; then
      dnf -y --setopt=tsflags= install "$pkg"
    elif command -v microdnf >/dev/null 2>&1; then
      microdnf -y --setopt=tsflags= install "$pkg"
    else
      echo "missing Fedora package manager (dnf5, dnf, or microdnf)" >&2
      exit 1
    fi
    ;;
  arch)
    pacman -Sy --noconfirm --needed bash fontconfig
    pacman -U --noconfirm "$pkg"
    ;;
  void)
    mkdir -p /etc/xbps.d
    printf '%s\n' 'repository=https://repo-default.voidlinux.org/current' > /etc/xbps.d/00-repository-main.conf
    xbps-install -Syu -y xbps || xbps-install -Syu -y xbps
    xbps-install -S -y bash fontconfig
    xbps-install -R /packages -y dec-fonts
    ;;
  *)
    echo "unsupported FORMAT: $FORMAT" >&2
    exit 1
    ;;
esac

bash /repo/scripts/verify-linux-package-install.sh --format "$FORMAT"
CONTAINER
