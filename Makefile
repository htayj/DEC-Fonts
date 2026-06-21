.PHONY: help bdf convert fonts check package ci package-deb package-rpm package-arch package-void distro-packages aur-srcinfo guix-lint guix-build test-guix-package nix-metadata nix-check test-deb-package test-rpm-package test-arch-package test-void-package test-gentoo-package test-nix-flake-container test-distro-packages clean-release clean-packages

export GENERATOR_OPTIONS ?=
export VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
export RELEASE_DIR ?= dist/release
export DIST_PACKAGE_DIR ?= dist/packages
export CONTAINER_RUNTIME ?= docker
export NIX_CONTAINER_IMAGE ?= docker.io/nixos/nix:latest
export GENTOO_CONTAINER_IMAGE ?= docker.io/gentoo/stage3:latest
export VOID_CONTAINER_IMAGE ?= docker.io/voidlinux/voidlinux:latest
export SOURCE_DATE_EPOCH ?= 1731361680
GUIX ?= guix
NIX ?= nix --extra-experimental-features nix-command --extra-experimental-features flakes

help:
	@printf '%s\n' \
	  'DEC-Fonts build targets:' \
	  '  make bdf                    Regenerate BDF fonts with scripts/generate-fonts.sh' \
	  '  make convert                Convert BDF fonts to derived BDF/OTB/PSF artifacts' \
	  '  make fonts                  Regenerate BDFs, convert, and check metadata' \
	  '  make check                  Audit BDF/XLFD metadata in dist/fonts/bdf' \
	  '  make package                Build fonts, check metadata, and create release tarball' \
	  '  make package-deb            Build fonts and create a Debian package' \
	  '  make package-rpm            Build fonts and create a Fedora/RPM package' \
	  '  make package-arch           Build fonts and create a local Arch package' \
	  '  make package-void           Build fonts and create a local Void package' \
	  '  make distro-packages        Build DEB, RPM, and Arch packages' \
	  '  make aur-srcinfo            Refresh packaging/aur/dec-fonts-git/.SRCINFO' \
	  '  make guix-lint              Lint the local Guix package module' \
	  '  make guix-build             Build the local Guix package' \
	  '  make test-guix-package      Build and verify the Guix package in a Guix container' \
	  '  make nix-metadata           Show Nix flake metadata' \
	  '  make nix-check              Run Nix flake checks' \
	  '  make test-deb-package       Install the DEB in a container and verify fonts' \
	  '  make test-rpm-package       Install the RPM in a container and verify fonts' \
	  '  make test-arch-package      Install the Arch package in a container and verify fonts' \
	  '  make test-void-package      Install the Void package in a container and verify fonts' \
	  '  make test-gentoo-package    Smoke-test the Gentoo ebuild in a container' \
	  '  make test-nix-flake-container  Run nix flake check in a Nix container' \
	  '  make test-distro-packages   Test all distro packages in containers' \
	  '  make ci                     Run the same local build path used by CI' \
	  "  make clean-release         Remove $$RELEASE_DIR" \
	  "  make clean-packages        Remove $$DIST_PACKAGE_DIR" \
	  '' \
	  'Variables:' \
	  '  GENERATOR_OPTIONS="--include-scaled-sizes --include-132-column"' \
	  "  VERSION=$$VERSION" \
	  "  RELEASE_DIR=$$RELEASE_DIR" \
	  "  DIST_PACKAGE_DIR=$$DIST_PACKAGE_DIR" \
	  "  CONTAINER_RUNTIME=$$CONTAINER_RUNTIME" \
	  "  NIX_CONTAINER_IMAGE=$$NIX_CONTAINER_IMAGE" \
	  "  GENTOO_CONTAINER_IMAGE=$$GENTOO_CONTAINER_IMAGE" \
	  "  VOID_CONTAINER_IMAGE=$$VOID_CONTAINER_IMAGE" \
	  "  SOURCE_DATE_EPOCH=$$SOURCE_DATE_EPOCH" \
	  "  GUIX=$(GUIX)" \
	  "  NIX=$(NIX)"

bdf:
	set -f; ./scripts/generate-fonts.sh $${GENERATOR_OPTIONS}

convert:
	./convert.bash

fonts:
	set -f; ./scripts/build-fonts.sh $${GENERATOR_OPTIONS}

check:
	python3 scripts/check-bdf-metadata.py dist/fonts/bdf

package: fonts
	./scripts/package-release.sh

ci: package

package-deb: fonts
	./scripts/package-deb.sh --version "$${VERSION}" --output-dir "$${DIST_PACKAGE_DIR}/deb"

package-rpm: fonts
	./scripts/package-rpm.sh --version "$${VERSION}" --output-dir "$${DIST_PACKAGE_DIR}/rpm"

package-arch: fonts
	./scripts/package-arch.sh --version "$${VERSION}" --output-dir "$${DIST_PACKAGE_DIR}/arch"

package-void: fonts
	./scripts/package-void.sh --version "$${VERSION}" --output-dir "$${DIST_PACKAGE_DIR}/void" --runtime "$${CONTAINER_RUNTIME}" --image "$${VOID_CONTAINER_IMAGE}"

distro-packages: package-deb package-rpm package-arch

aur-srcinfo:
	cd packaging/aur/dec-fonts-git && makepkg --printsrcinfo > .SRCINFO

guix-lint:
	$(GUIX) lint -L packaging/guix dec-fonts

guix-build:
	$(GUIX) build -L packaging/guix dec-fonts --no-grafts

test-guix-package:
	./scripts/test-guix-package.sh --guix "$(GUIX)"

nix-metadata:
	$(NIX) flake metadata path:$(CURDIR) --no-write-lock-file

nix-check:
	$(NIX) flake check path:$(CURDIR) --no-write-lock-file

test-deb-package:
	@set -- "$${DIST_PACKAGE_DIR}"/deb/*.deb; \
	if [ "$$#" -ne 1 ] || [ ! -f "$$1" ]; then \
	  echo "expected exactly one DEB under $${DIST_PACKAGE_DIR}/deb" >&2; \
	  exit 1; \
	fi; \
	./scripts/test-linux-package-container.sh --runtime "$${CONTAINER_RUNTIME}" --format deb --package "$$1"

test-rpm-package:
	@set -- "$${DIST_PACKAGE_DIR}"/rpm/*.rpm; \
	if [ "$$#" -ne 1 ] || [ ! -f "$$1" ]; then \
	  echo "expected exactly one RPM under $${DIST_PACKAGE_DIR}/rpm" >&2; \
	  exit 1; \
	fi; \
	./scripts/test-linux-package-container.sh --runtime "$${CONTAINER_RUNTIME}" --format rpm --package "$$1"

test-arch-package:
	@set --; \
	for package in "$${DIST_PACKAGE_DIR}"/arch/*.pkg.tar*; do \
	  [ -f "$$package" ] || continue; \
	  case "$$package" in *.sha256|*.sig) continue ;; esac; \
	  set -- "$$@" "$$package"; \
	done; \
	if [ "$$#" -ne 1 ] || [ ! -f "$$1" ]; then \
	  echo "expected exactly one Arch package under $${DIST_PACKAGE_DIR}/arch" >&2; \
	  exit 1; \
	fi; \
	./scripts/test-linux-package-container.sh --runtime "$${CONTAINER_RUNTIME}" --format arch --package "$$1"

test-void-package:
	@set -- "$${DIST_PACKAGE_DIR}"/void/*.xbps; \
	if [ "$$#" -ne 1 ] || [ ! -f "$$1" ]; then \
	  echo "expected exactly one Void package under $${DIST_PACKAGE_DIR}/void" >&2; \
	  exit 1; \
	fi; \
	./scripts/test-linux-package-container.sh --runtime "$${CONTAINER_RUNTIME}" --format void --package "$$1" --image "$${VOID_CONTAINER_IMAGE}"

test-gentoo-package:
	./scripts/test-gentoo-package-container.sh --runtime "$${CONTAINER_RUNTIME}" --image "$${GENTOO_CONTAINER_IMAGE}"

test-nix-flake-container:
	./scripts/test-nix-flake-container.sh --runtime "$${CONTAINER_RUNTIME}" --image "$${NIX_CONTAINER_IMAGE}"

test-distro-packages: test-deb-package test-rpm-package test-arch-package

clean-release:
	rm -rf -- "$${RELEASE_DIR}"

clean-packages:
	rm -rf -- "$${DIST_PACKAGE_DIR}"
