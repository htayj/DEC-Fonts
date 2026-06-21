#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$repo_root"

bdf_dir=./dist/fonts/bdf
otb_dir=./dist/fonts/otb
psf_dir=./dist/fonts/psf
dec_set=./dist/dec.set
equivalents=/usr/share/bdf2psf/standard.equivalents

mkdir -p "$bdf_dir" "$otb_dir" "$psf_dir"

for tool in python3 mkbold mkitalic mkbolditalic fonttosfnt bdf2psf mkfontscale mkfontdir; do
    command -v "$tool" >/dev/null || {
        echo "missing required tool: $tool" >&2
        exit 1
    }
done

[[ -f "$equivalents" ]] || {
    echo "missing bdf2psf equivalents file: $equivalents" >&2
    exit 1
}

# Make repeated runs safe: generated style variants must always be derived from
# the selected base BDFs, never from already-bold or already-italic BDFs.
find "$bdf_dir" -maxdepth 1 -type f \( \
    -name '*-Bold-*' -o \
    -name '*-Italic-*' -o \
    -name '*-BoldItalic-*' \
\) -delete
find "$otb_dir" -maxdepth 1 -type f -name 'DIGITAL-VT220-Normal-*.otb' -delete
find "$psf_dir" -maxdepth 1 -type f -name 'DIGITAL-VT220-Normal-*.psf' -delete

mapfile -d '' base_bdfs < <(find "$bdf_dir" -maxdepth 1 -type f -name '*.bdf' \
    ! -name '*-Bold-*' \
    ! -name '*-Italic-*' \
    ! -name '*-BoldItalic-*' \
    -print0 | sort -z)

if [[ ${#base_bdfs[@]} -eq 0 ]]; then
    echo "no base BDF files found in $bdf_dir; run the Lisp generator first" >&2
    exit 1
fi

# fonttosfnt embeds timestamps in OTB files. Use a stable default so repeated
# conversions are deterministic; callers can override this if desired.
export SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-1731361680}

set_spacing() {
    local bdf_file=$1
    local spacing=$2
    python3 - "$bdf_file" "$spacing" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
spacing = sys.argv[2]
lines = path.read_text(encoding="ascii").splitlines()
for index, line in enumerate(lines):
    if line.startswith("FONT "):
        font_name = line[5:]
        parts = font_name.split("-")
        if len(parts) == 15 and parts[0] == "":
            parts[11] = spacing
            lines[index] = "FONT " + "-".join(parts)
    elif line.startswith("SPACING "):
        lines[index] = f'SPACING "{spacing}"'
path.write_text("\n".join(lines) + "\n", encoding="ascii")
PY
}

for filename in "${base_bdfs[@]}"; do
    basename=$(basename "$filename" .bdf)

    bold_filename=${filename/col/col-Bold}
    italic_filename=${filename/col/col-Italic}
    bolditalic_filename=${filename/col/col-BoldItalic}

    echo "making bold $filename"
    mkbold "$filename" > "$bold_filename"

    echo "making italic $filename"
    mkitalic "$filename" > "$italic_filename"
    set_spacing "$italic_filename" m

    echo "making bolditalic $filename"
    mkbolditalic "$filename" > "$bolditalic_filename"
    set_spacing "$bolditalic_filename" m

    echo "converting $filename to otb"
    fonttosfnt -o "$otb_dir/$basename.otb" "$filename"

    echo "converting $filename to psf"
    bdf2psf --fb "$filename" "$equivalents" "$dec_set" 256 "$psf_dir/$basename.psf" >/dev/null
done

(
    cd "$bdf_dir"
    mkfontscale
    mkfontdir
)
