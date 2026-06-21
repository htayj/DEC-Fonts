# Copyright 2026 DEC-Fonts maintainers
# Distributed under the terms of the MIT License

EAPI=8

inherit font git-r3

DESCRIPTION="DEC VT220 bitmap fonts"
HOMEPAGE="https://github.com/htayj/DEC-Fonts"
EGIT_REPO_URI="https://github.com/htayj/DEC-Fonts.git"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""

RDEPEND="media-libs/fontconfig"

src_unpack() {
	if [[ -n ${DEC_FONTS_SOURCE_DIR:-} ]]; then
		mkdir -p "${S}" || die
		cp -a "${DEC_FONTS_SOURCE_DIR}"/. "${S}"/ || die
	else
		git-r3_src_unpack
	fi
}

src_install() {
	docompress -x /usr/share/doc/dec-fonts
	"${S}"/scripts/stage-linux-package.sh --format gentoo --destdir "${D}" || die
}
