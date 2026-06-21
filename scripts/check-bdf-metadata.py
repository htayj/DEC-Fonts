#!/usr/bin/env python3
"""Audit DEC-Fonts BDF/XLFD metadata.

This is intentionally small and repository-specific: it checks the invariants
that generated DEC-Fonts BDF files should satisfy, rather than trying to be a
complete BDF validator.
"""

from __future__ import annotations

import argparse
import math
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


XLFD_FIELDS = (
    "foundry",
    "family_name",
    "weight_name",
    "slant",
    "setwidth_name",
    "add_style_name",
    "pixel_size",
    "point_size",
    "resolution_x",
    "resolution_y",
    "spacing",
    "average_width",
    "charset_registry",
    "charset_encoding",
)

STRING_PROPS = {
    "FOUNDRY",
    "FAMILY_NAME",
    "WEIGHT_NAME",
    "SLANT",
    "SETWIDTH_NAME",
    "ADD_STYLE_NAME",
    "SPACING",
    "CHARSET_REGISTRY",
    "CHARSET_ENCODING",
}


@dataclass(frozen=True)
class Glyph:
    name: str
    encoding: int | None
    swidth: tuple[int, int] | None
    dwidth: tuple[int, int] | None
    bbx: tuple[int, int, int, int] | None


@dataclass(frozen=True)
class BdfFont:
    path: Path
    font_name: str
    xlfd: dict[str, str]
    size: tuple[int, int, int]
    font_bbx: tuple[int, int, int, int]
    property_count: int
    properties: dict[str, str | int]
    chars_count: int
    glyphs: list[Glyph]


def unquote(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == '"' and value[-1] == '"':
        return value[1:-1].replace('""', '"')
    return value


def parse_property(line: str) -> tuple[str, str | int]:
    key, _, raw_value = line.partition(" ")
    raw_value = raw_value.strip()
    if key in STRING_PROPS:
        return key, unquote(raw_value)
    try:
        return key, int(raw_value)
    except ValueError:
        return key, unquote(raw_value)


def parse_xlfd(font_name: str) -> dict[str, str]:
    if not font_name.startswith("-"):
        raise ValueError("FONT is not an XLFD name starting with '-'")
    parts = font_name.split("-")
    if len(parts) != 15 or parts[0] != "":
        raise ValueError(f"FONT is not a 14-field XLFD name: got {len(parts) - 1} fields")
    return dict(zip(XLFD_FIELDS, parts[1:], strict=True))


def parse_bdf(path: Path) -> BdfFont:
    lines = path.read_text(encoding="ascii", errors="strict").splitlines()
    font_name: str | None = None
    size: tuple[int, int, int] | None = None
    font_bbx: tuple[int, int, int, int] | None = None
    property_count: int | None = None
    properties: dict[str, str | int] = {}
    chars_count: int | None = None
    glyphs: list[Glyph] = []

    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith("FONT "):
            font_name = line[5:]
        elif line.startswith("SIZE "):
            parts = line.split()
            size = tuple(map(int, parts[1:4]))  # type: ignore[assignment]
        elif line.startswith("FONTBOUNDINGBOX "):
            parts = line.split()
            font_bbx = tuple(map(int, parts[1:5]))  # type: ignore[assignment]
        elif line.startswith("STARTPROPERTIES "):
            property_count = int(line.split()[1])
            i += 1
            while i < len(lines) and lines[i] != "ENDPROPERTIES":
                key, value = parse_property(lines[i])
                properties[key] = value
                i += 1
        elif line.startswith("CHARS "):
            chars_count = int(line.split()[1])
        elif line.startswith("STARTCHAR "):
            name = line.split(maxsplit=1)[1]
            encoding: int | None = None
            swidth: tuple[int, int] | None = None
            dwidth: tuple[int, int] | None = None
            bbx: tuple[int, int, int, int] | None = None
            i += 1
            while i < len(lines) and lines[i] != "ENDCHAR":
                glyph_line = lines[i]
                if glyph_line.startswith("ENCODING "):
                    parts = glyph_line.split()
                    encoding = int(parts[1])
                elif glyph_line.startswith("SWIDTH "):
                    parts = glyph_line.split()
                    swidth = (int(parts[1]), int(parts[2]))
                elif glyph_line.startswith("DWIDTH "):
                    parts = glyph_line.split()
                    dwidth = (int(parts[1]), int(parts[2]))
                elif glyph_line.startswith("BBX "):
                    parts = glyph_line.split()
                    bbx = tuple(map(int, parts[1:5]))  # type: ignore[assignment]
                i += 1
            glyphs.append(Glyph(name, encoding, swidth, dwidth, bbx))
        i += 1

    missing = []
    if font_name is None:
        missing.append("FONT")
    if size is None:
        missing.append("SIZE")
    if font_bbx is None:
        missing.append("FONTBOUNDINGBOX")
    if property_count is None:
        missing.append("STARTPROPERTIES")
    if chars_count is None:
        missing.append("CHARS")
    if missing:
        raise ValueError(f"missing required top-level lines: {', '.join(missing)}")

    assert font_name is not None
    return BdfFont(
        path=path,
        font_name=font_name,
        xlfd=parse_xlfd(font_name),
        size=size,  # type: ignore[arg-type]
        font_bbx=font_bbx,  # type: ignore[arg-type]
        property_count=property_count,  # type: ignore[arg-type]
        properties=properties,
        chars_count=chars_count,  # type: ignore[arg-type]
        glyphs=glyphs,
    )


def atom_equal(left: object, right: object) -> bool:
    return str(left).casefold() == str(right).casefold()


def nearest_integer(value: float) -> int:
    return math.floor(value + 0.5)


def expected_swidth_x(dwidth_x: int, point_size: int, resolution_x: int) -> int:
    # BDF SWIDTH is in 1/1000ths of SIZE point-size.  Converting SWIDTH to
    # device pixels is: swidth * point_size / 1000 * resolution / 72.
    return nearest_integer(dwidth_x * 72000 / (point_size * resolution_x))


def check_font(font: BdfFont) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []
    props = font.properties
    xlfd = font.xlfd
    size_point, size_xres, size_yres = font.size
    fbb_w, fbb_h, fbb_x, fbb_y = font.font_bbx

    def require_prop(name: str) -> object | None:
        if name not in props:
            errors.append(f"missing property {name}")
            return None
        return props[name]

    if font.property_count != len(props):
        errors.append(
            f"STARTPROPERTIES says {font.property_count}, found {len(props)} properties"
        )

    if font.chars_count != len(font.glyphs):
        errors.append(f"CHARS says {font.chars_count}, found {len(font.glyphs)} STARTCHAR blocks")

    for field, prop_name in [
        ("foundry", "FOUNDRY"),
        ("family_name", "FAMILY_NAME"),
        ("weight_name", "WEIGHT_NAME"),
        ("slant", "SLANT"),
        ("setwidth_name", "SETWIDTH_NAME"),
        ("add_style_name", "ADD_STYLE_NAME"),
        ("spacing", "SPACING"),
        ("charset_registry", "CHARSET_REGISTRY"),
        ("charset_encoding", "CHARSET_ENCODING"),
    ]:
        value = require_prop(prop_name)
        if value is not None and not atom_equal(value, xlfd[field]):
            errors.append(f"{prop_name}={value!r} does not match XLFD {field}={xlfd[field]!r}")

    numeric_fields = [
        ("pixel_size", "PIXEL_SIZE"),
        ("point_size", "POINT_SIZE"),
        ("resolution_x", "RESOLUTION_X"),
        ("resolution_y", "RESOLUTION_Y"),
        ("average_width", "AVERAGE_WIDTH"),
    ]
    for field, prop_name in numeric_fields:
        value = require_prop(prop_name)
        if value is not None and int(value) != int(xlfd[field]):
            errors.append(f"{prop_name}={value} does not match XLFD {field}={xlfd[field]}")

    if size_point * 10 != int(xlfd["point_size"]):
        errors.append(f"SIZE point {size_point} does not match XLFD POINT_SIZE {xlfd['point_size']}")
    if size_xres != int(xlfd["resolution_x"]):
        errors.append(f"SIZE xres {size_xres} does not match XLFD RESOLUTION_X {xlfd['resolution_x']}")
    if size_yres != int(xlfd["resolution_y"]):
        errors.append(f"SIZE yres {size_yres} does not match XLFD RESOLUTION_Y {xlfd['resolution_y']}")

    for prop_name, expected in [
        ("RESOLUTION_X", size_xres),
        ("RESOLUTION_Y", size_yres),
        ("POINT_SIZE", size_point * 10),
    ]:
        value = require_prop(prop_name)
        if value is not None and int(value) != expected:
            errors.append(f"{prop_name}={value} does not match expected {expected}")

    pixel_size = require_prop("PIXEL_SIZE")
    font_ascent = require_prop("FONT_ASCENT")
    font_descent = require_prop("FONT_DESCENT")
    default_char = require_prop("DEFAULT_CHAR")
    average_width = require_prop("AVERAGE_WIDTH")
    quad_width = require_prop("QUAD_WIDTH")
    spacing = require_prop("SPACING")

    if pixel_size is not None and int(pixel_size) != fbb_h:
        errors.append(f"PIXEL_SIZE={pixel_size} does not match FONTBOUNDINGBOX height {fbb_h}")
    if font_ascent is not None and font_descent is not None and pixel_size is not None:
        if int(font_ascent) + int(font_descent) != int(pixel_size):
            errors.append(
                f"FONT_ASCENT + FONT_DESCENT = {int(font_ascent) + int(font_descent)}, "
                f"expected PIXEL_SIZE {pixel_size}"
            )
    cell_width: int | None = None
    if average_width is not None:
        if int(average_width) % 10 != 0:
            errors.append(f"AVERAGE_WIDTH={average_width} is not an integral pixel width in tenths")
        cell_width = int(average_width) // 10
    if quad_width is not None and cell_width is not None and int(quad_width) != cell_width:
        errors.append(f"QUAD_WIDTH={quad_width} does not match AVERAGE_WIDTH cell width {cell_width}")
    if spacing is not None and not atom_equal(spacing, "C") and not atom_equal(spacing, "M"):
        warnings.append(f"SPACING={spacing!r}; expected character-cell C or monospace M")
    if spacing is not None and atom_equal(spacing, "C") and cell_width is not None:
        if fbb_x != 0 or fbb_w != cell_width:
            errors.append(
                f"SPACING C requires ink inside the character cell; "
                f"FONTBOUNDINGBOX={font.font_bbx}, cell width={cell_width}"
            )

    encodings = {glyph.encoding for glyph in font.glyphs if glyph.encoding is not None}
    if default_char is not None and int(default_char) not in encodings:
        errors.append(f"DEFAULT_CHAR={default_char} is not present in encoded glyphs")

    for glyph in font.glyphs:
        if glyph.encoding is None:
            errors.append(f"{glyph.name}: missing ENCODING")
        if glyph.swidth is None:
            errors.append(f"{glyph.name}: missing SWIDTH")
        if glyph.dwidth is None:
            errors.append(f"{glyph.name}: missing DWIDTH")
        if glyph.bbx is None:
            errors.append(f"{glyph.name}: missing BBX")
        if glyph.swidth is None or glyph.dwidth is None or glyph.bbx is None:
            continue

        swidth_x, swidth_y = glyph.swidth
        dwidth_x, dwidth_y = glyph.dwidth
        bbx_w, bbx_h, bbx_x, bbx_y = glyph.bbx

        if swidth_y != 0:
            errors.append(f"{glyph.name}: SWIDTH y={swidth_y}, expected 0")
        if dwidth_y != 0:
            errors.append(f"{glyph.name}: DWIDTH y={dwidth_y}, expected 0")
        if cell_width is not None and dwidth_x != cell_width:
            errors.append(f"{glyph.name}: DWIDTH x={dwidth_x}, expected cell width {cell_width}")
        if spacing is not None and atom_equal(spacing, "C") and cell_width is not None:
            if bbx_x < 0 or bbx_x + bbx_w > cell_width:
                errors.append(f"{glyph.name}: SPACING C glyph BBX {glyph.bbx} exceeds cell width {cell_width}")
        expected_swidth = expected_swidth_x(dwidth_x, size_point, size_xres)
        if abs(swidth_x - expected_swidth) > 1:
            errors.append(f"{glyph.name}: SWIDTH x={swidth_x}, expected {expected_swidth}")

        if bbx_x < fbb_x or bbx_y < fbb_y:
            errors.append(f"{glyph.name}: BBX origin {glyph.bbx} outside FONTBOUNDINGBOX {font.font_bbx}")
        if bbx_x + bbx_w > fbb_x + fbb_w or bbx_y + bbx_h > fbb_y + fbb_h:
            errors.append(f"{glyph.name}: BBX extent {glyph.bbx} outside FONTBOUNDINGBOX {font.font_bbx}")
        if font_ascent is not None and bbx_y + bbx_h > int(font_ascent):
            errors.append(f"{glyph.name}: BBX rises above FONT_ASCENT {font_ascent}")
        if font_descent is not None and bbx_y < -int(font_descent):
            errors.append(f"{glyph.name}: BBX falls below FONT_DESCENT {font_descent}")

    return errors, warnings


def iter_bdf_paths(inputs: Iterable[Path]) -> list[Path]:
    paths: list[Path] = []
    for input_path in inputs:
        if input_path.is_dir():
            paths.extend(sorted(input_path.glob("*.bdf")))
        else:
            paths.append(input_path)
    return paths


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "paths",
        nargs="*",
        type=Path,
        default=[Path("dist/fonts/bdf")],
        help="BDF files or directories to audit (default: dist/fonts/bdf)",
    )
    parser.add_argument("--warnings-as-errors", action="store_true")
    args = parser.parse_args()

    bdf_paths = iter_bdf_paths(args.paths)
    if not bdf_paths:
        print("No BDF files found", file=sys.stderr)
        return 2

    total_errors = 0
    total_warnings = 0
    for path in bdf_paths:
        try:
            font = parse_bdf(path)
            errors, warnings = check_font(font)
        except Exception as exc:  # noqa: BLE001 - report parse errors per file.
            errors = [f"parse error: {exc}"]
            warnings = []
        if errors or warnings:
            print(path)
        for warning in warnings:
            total_warnings += 1
            print(f"  warning: {warning}")
        for error in errors:
            total_errors += 1
            print(f"  error: {error}")

    if total_errors or (args.warnings_as_errors and total_warnings):
        print(f"FAILED: {total_errors} errors, {total_warnings} warnings", file=sys.stderr)
        return 1
    print(f"OK: {len(bdf_paths)} BDF files checked ({total_warnings} warnings)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
