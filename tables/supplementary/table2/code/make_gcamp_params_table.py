#!/usr/bin/env python3
"""Create the GCaMP parameter CSV from JSON inputs or copy its canonical CSV.

The first 14 indicator.Gparams entries define the kinetic terms. The ReportLab
renderer consumes the resulting CSV separately, preserving displayed strings.
"""

from __future__ import annotations

import argparse
import csv
import glob
import json
import sys
from pathlib import Path
import re
from typing import List, Sequence, Tuple


# (parameter symbol, description, units for CSV, scale factor)
PARAM_SPECS: List[Tuple[str, str, str, float]] = [
    ('K_{aN}', 'Affinity [N-term]', 'microM', 1000000.0),
    ('k_{offN}', 'Off Rate [N-term]', 's^-1', 1.0),
    ('H_N', 'Hill coeff [N-term]', 'unitless', 1.0),
    ('K_{aC}', 'Affinity [C-term]', 'microM', 1000000.0),
    ('k_{offC}', 'Off Rate [C-term]', 's^-1', 1.0),
    ('H_C', 'Hill coeff [C-term]', 'unitless', 1.0),
    ('k_{onPN}', 'On Rate N [N-lobe bound]', 's^-1', 1.0),
    ('k_{offPN}', 'Off Rate N [N-lobe bound]', 's^-1', 1.0),
    ('k_{onPC}', 'On Rate C [C-lobe bound]', 's^-1', 1.0),
    ('k_{offPC}', 'Off Rate C [C-lobe bound]', 's^-1', 1.0),
    ('k_{onPN2}', 'On Rate N [both bound]', 's^-1', 1.0),
    ('k_{offPN2}', 'Off Rate N [both bound]', 's^-1', 1.0),
    ('k_{onPC2}', 'On Rate C [both bound]', 's^-1', 1.0),
    ('k_{offPC2}', 'Off Rate C [both bound]', 's^-1', 1.0),
]

EXPECTED_PARAM_COUNT = len(PARAM_SPECS)
FILENAME_PATTERN = re.compile(r"best_(?P<name>.+?)_params\.json$", re.IGNORECASE)
SENSOR_NAME_RULES: List[Tuple[re.Pattern[str], str]] = [
    (re.compile(r"^G(?P<tag>\d+[A-Za-z0-9]*)$"), r"GCaMP\g<tag>"),
    (re.compile(r"^jG(?P<tag>\d+[A-Za-z0-9]*)$"), r"jGCaMP\g<tag>"),
]
SENSOR_WITH_SOURCE_PATTERN = re.compile(
    r"^(?P<prefix>j?)G(?P<tag>\d+[A-Za-z0-9]*?)_(?P<source>.+)$",
    re.IGNORECASE,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build GCaMP parameter tables from JSON files."
    )
    parser.add_argument(
        "--input-csv",
        type=Path,
        help="Copy the canonical source-data CSV, preserving its displayed numeric strings.",
    )
    parser.add_argument(
        "--input-glob",
        default="tables/supplementary/table2/inputs/best_*_params.json",
        help="Glob pattern for input JSON files.",
    )
    parser.add_argument(
        "--output-prefix",
        default="build/tables/supplementary/table2/gcamp_parameter_table",
        help="Output prefix path (writes <prefix>.csv).",
    )
    parser.add_argument(
        "--sig-figs",
        type=int,
        default=3,
        help="Significant figures used when formatting numeric values.",
    )
    parser.add_argument(
        "--sci-decimals",
        type=int,
        default=2,
        help="Digits after decimal for scientific-notation values.",
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help=(
            "Fail if `Gparams` length is not exactly 14. "
            "By default, entries beyond 14 are ignored silently."
        ),
    )
    parser.add_argument(
        "--show-warnings",
        action="store_true",
        help="Print non-fatal warnings (for example when extra Gparams are ignored).",
    )
    return parser.parse_args()


def sensor_name_from_filename(path: Path) -> str:
    match = FILENAME_PATTERN.match(path.name)
    raw = match.group("name") if match else path.stem
    return normalize_sensor_name(raw)


def normalize_source_label(source: str) -> str:
    cleaned = re.sub(r"[_\-]+", " ", source).strip()
    lowered = cleaned.lower()
    if lowered == "janelia":
        return "Janelia"
    if lowered == "slice":
        return "Slice"
    return cleaned.title()


def normalize_sensor_name(name: str) -> str:
    source_match = SENSOR_WITH_SOURCE_PATTERN.match(name)
    if source_match:
        prefix = source_match.group("prefix").lower()
        tag = source_match.group("tag")
        source = normalize_source_label(source_match.group("source"))
        base = f"{'j' if prefix == 'j' else ''}GCaMP{tag}"
        return f"{base}|{source}"

    for pattern, replacement in SENSOR_NAME_RULES:
        if pattern.match(name):
            return pattern.sub(replacement, name)
    return name


def make_unique_names(names: Sequence[str]) -> List[str]:
    counts = {}
    unique = []
    for name in names:
        counts[name] = counts.get(name, 0) + 1
        if counts[name] == 1:
            unique.append(name)
        else:
            unique.append(f"{name}_{counts[name]}")
    return unique


def load_gparams(path: Path, strict: bool, show_warnings: bool) -> List[float]:
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)

    try:
        gparams = data["indicator"]["Gparams"]
    except KeyError as exc:
        raise KeyError(f"{path}: missing field `indicator.Gparams`.") from exc

    if not isinstance(gparams, list):
        raise TypeError(f"{path}: `indicator.Gparams` must be a list.")

    try:
        values = [float(v) for v in gparams]
    except (TypeError, ValueError) as exc:
        raise TypeError(f"{path}: `indicator.Gparams` contains non-numeric values.") from exc

    if len(values) < EXPECTED_PARAM_COUNT:
        raise ValueError(
            f"{path}: expected at least {EXPECTED_PARAM_COUNT} `Gparams` entries, "
            f"found {len(values)}."
        )

    if len(values) > EXPECTED_PARAM_COUNT:
        msg = (
            f"{path}: found {len(values)} `Gparams` entries; using first "
            f"{EXPECTED_PARAM_COUNT} and ignoring the rest."
        )
        if strict:
            raise ValueError(msg)
        if show_warnings:
            print(f"Warning: {msg}", file=sys.stderr)

    return values[:EXPECTED_PARAM_COUNT]


def format_value(value: float, sig_figs: int, sci_decimals: int) -> str:
    if value == 0:
        return "0"

    magnitude = abs(value)
    if magnitude < 1e-3 or magnitude >= 1e4:
        return f"{value:.{sci_decimals}e}"
    return f"{value:.{sig_figs}g}"


def sensor_name_for_csv(name: str) -> str:
    if "|" not in name:
        return name
    base, source = name.split("|", 1)
    return f"{base} {source}"


def write_csv(
    out_path: Path,
    sensor_names: Sequence[str],
    sensor_values: Sequence[Sequence[float]],
    sig_figs: int,
    sci_decimals: int,
) -> None:
    with out_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        csv_header_names = [sensor_name_for_csv(name) for name in sensor_names]
        writer.writerow(["Parameter", "Description", "Units", *csv_header_names])

        for i, (symbol, description, units_csv, scale_factor) in enumerate(PARAM_SPECS):
            row = [symbol, description, units_csv]
            row.extend(
                format_value(values[i] * scale_factor, sig_figs, sci_decimals)
                for values in sensor_values
            )
            writer.writerow(row)


def main() -> None:
    args = parse_args()
    if args.input_csv is not None:
        source_bytes = args.input_csv.read_bytes()
        out_prefix = Path(args.output_prefix)
        out_prefix.parent.mkdir(parents=True, exist_ok=True)
        with args.input_csv.open(encoding="utf-8-sig", newline="") as stream:
            reader = csv.DictReader(stream)
            if not reader.fieldnames or reader.fieldnames[:3] != ["Parameter", "Description", "Units"]:
                raise ValueError("Canonical parameter CSV requires Parameter, Description, Units and sensor columns.")
            if not list(reader):
                raise ValueError("Canonical parameter CSV is empty.")
        out_prefix.with_suffix(".csv").write_bytes(source_bytes)
        print(f"Copied canonical CSV table: {args.input_csv}")
        return

    json_paths = sorted(Path(p) for p in glob.glob(args.input_glob))
    if not json_paths:
        raise FileNotFoundError(f"No JSON files matched: {args.input_glob}")

    sensor_names = make_unique_names([sensor_name_from_filename(p) for p in json_paths])
    sensor_values = [
        load_gparams(path, strict=args.strict, show_warnings=args.show_warnings)
        for path in json_paths
    ]

    out_prefix = Path(args.output_prefix)
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    csv_path = out_prefix.with_suffix(".csv")

    write_csv(csv_path, sensor_names, sensor_values, args.sig_figs, args.sci_decimals)

    print(f"Wrote CSV table: {csv_path}")


if __name__ == "__main__":
    main()
