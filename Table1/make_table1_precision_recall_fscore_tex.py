"""Build the Table 1 precision/recall/F-score LaTeX document from CSV."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

import pandas as pd


METHOD_COLORS = {
    "Biophys_{SMC}": "009E73",
    "MLspike": "0072B2",
    "Biophys_{ML}": "007755",
    "CASCADE": "F3AE14",
    "ENS^2": "A6780C",
}

COLUMN_LABELS = {
    "Mean error (ms)": "Uncertainty (ms)",
}


def latexify(text: object) -> object:
    if not isinstance(text, str):
        return text

    text = text.replace("Â±", r"$\pm$")
    text = text.replace("±", r"$\pm$")

    def replace_subsup(match: re.Match[str]) -> str:
        sign = match.group(1)
        block = match.group(2)
        if block.startswith("{"):
            return "$" + sign + r"\mathrm" + block + "$"
        return "$" + sign + r"\mathrm{" + block + "}$"

    return re.sub(r"([\^_])(\{[^}]+\}|\S)", replace_subsup, text)


def colored_method(method: str) -> str:
    color = METHOD_COLORS.get(method)
    latex_method = latexify(method)
    if color is None:
        return str(latex_method)
    return rf"\textcolor[HTML]{{{color}}}{{{latex_method}}}"


def build_table_tex(csv_path: Path) -> str:
    df = pd.read_csv(csv_path, index_col=0)
    df.index.name = ""
    df.rename(columns=COLUMN_LABELS, inplace=True)

    lines = [
        r"\documentclass{article}",
        r"\usepackage[margin=0.2in]{geometry}",
        r"\usepackage[HTML]{xcolor}",
        r"\usepackage{booktabs}",
        r"\usepackage[utf8]{inputenc}",
        r"\usepackage[T1]{fontenc}",
        r"\begin{document}",
        "",
        r"\noindent",
        r"\begin{minipage}{\textwidth}",
        r"\raggedright",
        r"\begin{tabular}{lcccccc}",
        r"\toprule",
    ]

    header = " & " + " & ".join(latexify(col) for col in df.columns) + r" \\"
    lines.extend([header, r"\midrule"])

    for method, row in df.iterrows():
        cells = [str(latexify(value)) for value in row]
        lines.append(colored_method(str(method)) + " & " + " & ".join(cells) + r" \\")

    lines.extend(
        [
            r"\bottomrule",
            r"\end{tabular}",
            r"\end{minipage}",
            "",
            r"\end{document}",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> None:
    script_dir = Path(__file__).resolve().parent
    parser = argparse.ArgumentParser(
        description="Generate the standalone LaTeX document for Table 1."
    )
    parser.add_argument(
        "--csv",
        type=Path,
        default=script_dir / "table1_precision_recall_fscore.csv",
        help="Input CSV containing Table 1 values.",
    )
    parser.add_argument(
        "--output-tex",
        type=Path,
        default=script_dir / "table1_precision_recall_fscore.tex",
        help="Output standalone LaTeX document.",
    )
    args = parser.parse_args()

    tex = build_table_tex(args.csv)
    args.output_tex.parent.mkdir(parents=True, exist_ok=True)
    args.output_tex.write_text(tex, encoding="utf-8")
    print(f"Wrote TeX: {args.output_tex}")


if __name__ == "__main__":
    main()
