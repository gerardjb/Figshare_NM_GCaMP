#!/usr/bin/env python3
"""Create manuscript-ready GCaMP parameter tables from JSON files.

This script reads `indicator.Gparams` from one or more JSON files (for example
`Table3/best_*_params.json`) and writes:

1) A CSV table for spreadsheet workflows.
2) A LaTeX table using `booktabs` for publication use.

By default, only the first 14 `Gparams` entries are used because the provided
parameter definitions correspond to 14 kinetic terms.
"""

from __future__ import annotations

import argparse
import csv
import glob
import json
import sys
from pathlib import Path
import re
from typing import List, Optional, Sequence, Tuple


# (parameter symbol, description, units for CSV, units for LaTeX, scale factor)
PARAM_SPECS: List[Tuple[str, str, str, str, float]] = [
    ("K_{aN}", "Affinity [N-term]", "microM", r"$\mu M$", 1e6),
    ("k_{offN}", "Off Rate [N-term]", "s^-1", r"$s^{-1}$", 1.0),
    ("H_N", "Hill coeff [N-term]", "unitless", "unitless", 1.0),
    ("K_{aC}", "Affinity [C-term]", "microM", r"$\mu M$", 1e6),
    ("k_{offC}", "Off Rate [C-term]", "s^-1", r"$s^{-1}$", 1.0),
    ("H_C", "Hill coeff [C-term]", "unitless", "unitless", 1.0),
    ("k_{onPN}", "On Rate N [N-lobe bound]", "s^-1", r"$s^{-1}$", 1.0),
    ("k_{offPN}", "Off Rate N [N-lobe bound]", "s^-1", r"$s^{-1}$", 1.0),
    ("k_{onPC}", "On Rate C [C-lobe bound]", "s^-1", r"$s^{-1}$", 1.0),
    ("k_{offPC}", "Off Rate C [C-lobe bound]", "s^-1", r"$s^{-1}$", 1.0),
    ("k_{onPN2}", "On Rate N [both bound]", "s^-1", r"$s^{-1}$", 1.0),
    ("k_{offPN2}", "Off Rate N [both bound]", "s^-1", r"$s^{-1}$", 1.0),
    ("k_{onPC2}", "On Rate C [both bound]", "s^-1", r"$s^{-1}$", 1.0),
    ("k_{offPC2}", "Off Rate C [both bound]", "s^-1", r"$s^{-1}$", 1.0),
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
# Mirrors Utilities/pickGCaMPcolorsMS.m for sensor-specific colors.
SENSOR_COLOR_HEX = {
    "gcamp6f": "0F1C79",
    "jgcamp7f": "CC5F09",
    "jgcamp8f": "9E0142",
    "jgcamp8m": "53338B",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build GCaMP parameter tables from JSON files."
    )
    parser.add_argument(
        "--input-csv",
        type=Path,
        help="Render the reviewed canonical source-data CSV, preserving its displayed numeric strings.",
    )
    parser.add_argument(
        "--input-glob",
        default="tables/supplementary/table2/inputs/best_*_params.json",
        help="Glob pattern for input JSON files.",
    )
    parser.add_argument(
        "--output-prefix",
        default="build/tables/supplementary/table2/gcamp_parameter_table",
        help="Output prefix path (writes <prefix>.csv and <prefix>.tex).",
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


def format_value_latex(value: float, sig_figs: int, sci_decimals: int) -> str:
    text = format_value(value, sig_figs, sci_decimals)
    if "e" not in text.lower():
        return f"${text}$"

    mantissa, exponent = text.lower().split("e")
    return rf"${mantissa}\times 10^{{{int(exponent)}}}$"


def latex_escape(text: str) -> str:
    replacements = {
        "\\": r"\textbackslash{}",
        "&": r"\&",
        "%": r"\%",
        "$": r"\$",
        "#": r"\#",
        "_": r"\_",
        "{": r"\{",
        "}": r"\}",
        "~": r"\textasciitilde{}",
        "^": r"\textasciicircum{}",
    }
    escaped = text
    for old, new in replacements.items():
        escaped = escaped.replace(old, new)
    return escaped


def sensor_name_for_csv(name: str) -> str:
    if "|" not in name:
        return name
    base, source = name.split("|", 1)
    return f"{base} {source}"


def sensor_color_for_name(name: str) -> Optional[str]:
    base = name.split("|", 1)[0]
    return SENSOR_COLOR_HEX.get(base.lower())


def sensor_name_for_latex(name: str) -> str:
    if "|" not in name:
        label = latex_escape(name)
    else:
        base, source = name.split("|", 1)
        label = rf"\shortstack[c]{{{latex_escape(base)}\\{latex_escape(source)}}}"

    color_hex = sensor_color_for_name(name)
    if color_hex is None:
        return label
    return rf"\textcolor[HTML]{{{color_hex}}}{{{label}}}"


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

        for i, (symbol, description, units_csv, _, scale_factor) in enumerate(PARAM_SPECS):
            row = [symbol, description, units_csv]
            row.extend(
                format_value(values[i] * scale_factor, sig_figs, sci_decimals)
                for values in sensor_values
            )
            writer.writerow(row)


def write_latex(
    out_path: Path,
    sensor_names: Sequence[str],
    sensor_values: Sequence[Sequence[float]],
    sig_figs: int,
    sci_decimals: int,
) -> None:
    align = "lll" + ("c" * len(sensor_names))

    lines: List[str] = [
        "% Requires: \\usepackage{booktabs}",
        "% Requires: \\usepackage{xcolor}  % for colored sensor headers",
        r"\begin{table}[htbp]",
        r"\centering",
        r"\small",
        r"\setlength{\tabcolsep}{6pt}",
        r"\caption{GCaMP model parameters sets.}",
        r"\label{tab:gcamp-params}",
        rf"\begin{{tabular}}{{{align}}}",
        r"\toprule",
        " & ".join(
            [latex_escape("Parameter"), latex_escape("Description"), latex_escape("Units")]
            + [sensor_name_for_latex(name) for name in sensor_names]
        )
        + r" \\",
        r"\midrule",
    ]

    for i, (symbol, description, _, units_tex, scale_factor) in enumerate(PARAM_SPECS):
        row = [
            rf"${symbol}$",
            latex_escape(description),
            units_tex,
        ]
        row.extend(
            format_value_latex(values[i] * scale_factor, sig_figs, sci_decimals)
            for values in sensor_values
        )
        lines.append(" & ".join(row) + r" \\")

    lines.extend(
        [
            r"\bottomrule",
            r"\end{tabular}",
            r"\end{table}",
            "",
        ]
    )

    out_path.write_text("\n".join(lines), encoding="utf-8")


def write_latex_from_csv(csv_path: Path, out_path: Path) -> None:
    """Render the reviewed CSV without scaling, rounding, or refitting its cells."""
    with csv_path.open("r", newline="", encoding="utf-8-sig") as stream:
        reader = csv.DictReader(stream)
        fields = reader.fieldnames or []
        if fields[:3] != ["Parameter", "Description", "Units"] or len(fields) < 4:
            raise ValueError("Canonical parameter CSV requires Parameter, Description, Units and sensor columns.")
        rows = list(reader)
    if not rows:
        raise ValueError("Canonical parameter CSV is empty.")
    sensor_names = []
    for header in fields[3:]:
        for suffix in (" Janelia", " Slice"):
            if header.endswith(suffix):
                header = header[:-len(suffix)] + "|" + suffix.strip()
                break
        sensor_names.append(header)
    units = {"microM": r"$\mu M$", "s^-1": r"$s^{-1}$", "unitless": "unitless"}

    def displayed_number(value: str) -> str:
        match = re.fullmatch(r"([+-]?(?:\d+(?:\.\d*)?|\.\d+))[eE]([+-]?\d+)", value)
        if match:
            return rf"${match.group(1)}\times 10^{{{int(match.group(2))}}}$"
        if not re.fullmatch(r"[+-]?(?:\d+(?:\.\d*)?|\.\d+)", value):
            raise ValueError(f"Unexpected nonnumeric canonical parameter value: {value!r}")
        return "$" + value + "$"

    lines = [
        "% Requires: \\usepackage{booktabs}",
        "% Requires: \\usepackage{xcolor}  % for colored sensor headers",
        r"\begin{table}[htbp]", r"\centering", r"\small",
        r"\setlength{\tabcolsep}{6pt}",
        r"\caption{GCaMP model parameters sets.}", r"\label{tab:gcamp-params}",
        r"\begin{tabular}{lll" + "c" * len(sensor_names) + "}",
        r"\toprule",
        " & ".join([latex_escape(x) for x in fields[:3]] + [sensor_name_for_latex(x) for x in sensor_names]) + r" \\",
        r"\midrule",
    ]
    for row in rows:
        values = [rf"${row['Parameter']}$", latex_escape(row["Description"]), units.get(row["Units"], latex_escape(row["Units"]))]
        values.extend(displayed_number(row[header]) for header in fields[3:])
        lines.append(" & ".join(values) + r" \\")
    lines.extend([r"\bottomrule", r"\end{tabular}", r"\end{table}", ""])
    out_path.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    args = parse_args()
    if args.input_csv is not None:
        source_bytes = args.input_csv.read_bytes()
        out_prefix = Path(args.output_prefix)
        out_prefix.parent.mkdir(parents=True, exist_ok=True)
        write_latex_from_csv(args.input_csv, out_prefix.with_suffix(".tex"))
        out_prefix.with_suffix(".csv").write_bytes(source_bytes)
        print(f"Rendered canonical CSV table: {args.input_csv}")
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
    tex_path = out_prefix.with_suffix(".tex")

    write_csv(csv_path, sensor_names, sensor_values, args.sig_figs, args.sci_decimals)
    write_latex(tex_path, sensor_names, sensor_values, args.sig_figs, args.sci_decimals)

    print(f"Wrote CSV table: {csv_path}")
    print(f"Wrote LaTeX table: {tex_path}")


if __name__ == "__main__":
    main()
