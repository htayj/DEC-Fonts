.PHONY: help bdf convert fonts check package ci clean-release

export GENERATOR_OPTIONS ?=
export VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
export RELEASE_DIR ?= dist/release
export SOURCE_DATE_EPOCH ?= 1731361680

help:
	@printf '%s\n' \
	  'DEC-Fonts build targets:' \
	  '  make bdf       Regenerate BDF fonts with scripts/generate-fonts.sh' \
	  '  make convert   Convert BDF fonts to derived BDF/OTB/PSF artifacts' \
	  '  make fonts     Regenerate BDFs, convert, and check metadata' \
	  '  make check     Audit BDF/XLFD metadata in dist/fonts/bdf' \
	  '  make package   Build fonts, check metadata, and create release tarball' \
	  '  make ci        Run the same local build path used by CI' \
	  "  make clean-release  Remove $$RELEASE_DIR" \
	  '' \
	  'Variables:' \
	  '  GENERATOR_OPTIONS="--include-scaled-sizes --include-132-column"' \
	  "  VERSION=$$VERSION" \
	  "  RELEASE_DIR=$$RELEASE_DIR" \
	  "  SOURCE_DATE_EPOCH=$$SOURCE_DATE_EPOCH"

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

clean-release:
	rm -rf -- "$${RELEASE_DIR}"
