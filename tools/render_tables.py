"""Portable CSV-to-TeX/PDF counterpart of the four Windows table wrappers.

The generators and table layout are unchanged. Windows entry points retain
their PowerShell wrappers; Linux publication builds dispatch here instead.
"""
from __future__ import annotations

import argparse
import csv
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


TABLES = {
    "render_table1_precision_recall_fscore_pdf": ("table1_precision_recall_fscore", 1),
    "render_table2_cell_parameters_pdf": ("table2_cell_parameters", 2),
    "render_gcamp_parameter_table_pdf": ("gcamp_parameter_table", 3),
    "render_table4_cell_parameter_priors_pdf": ("Table4_cell_parameter_priors", 4),
}
DESCRIPTIONS = {
    "[GCaMP]": "Total intracellular indicator concentration used in the model.",
    "R_f": r"Apparent fluorescence dynamic range (scaling factor mapping indicator state to measured $\Delta F/F$).",
    r"\Delta Ca_{spike}": "Per-spike calcium increment delivered to the modeled compartment.",
    "ca_0": "Basal intracellular calcium concentration.",
    r"\gamma": "Effective first-order calcium clearance rate constant.",
    "Buffer_{Endo}": "Total endogenous calcium buffer concentration.",
    "k_{on, Endo}": "Calcium binding on-rate to the endogenous buffer.",
    "k_{off, Endo}": "Calcium unbinding off-rate from the endogenous buffer.",
    "[ATP]": "Total ATP concentration.",
    "k_{on, ATP}": "Calcium binding on-rate to the ATP buffer.",
    "k_{off, ATP}": "Calcium unbinding off-rate from the ATP buffer.",
    "[Parv]": "Total parvalbumin concentration.",
    "k_{on, Parv, Ca^{2+}}": "Calcium binding on-rate to the parvalbumin buffer.",
    "k_{off, Parv, Ca^{2+}}": "Calcium unbinding off-rate from the parvalbumin buffer.",
    "k_{on, Parv, Mg^{2+}}": "Magnesium binding on-rate to the parvalbumin buffer.",
    "k_{off, Parv, Mg^{2+}}": "Magnesium unbinding off-rate from the parvalbumin buffer.",
    "mg_0": "Basal intracellular magnesium concentration.",
    r"\gamma_{in}": "Rate constant governing calcium influx/exchange into the modeled intracellular compartment.",
    r"\gamma_{out}": "Rate constant governing calcium efflux/exchange out of the modeled intracellular compartment.",
    r"\kappa_{B}": "Linearized endogenous buffering factor applied to intracellular calcium dynamics.",
}


def split_parameter(text: str) -> tuple[str, str]:
    match = re.fullmatch(r"(.+?)\s*\(([^)]*)\)\s*", text.strip())
    return (match[1].strip(), match[2].strip()) if match else (text.strip(), "")


def units_latex(text: str) -> str:
    compact = re.sub(r"\s+", "", text).lower()
    return {"microm": r"$\mu M$", "um": r"$\mu M$", "s^-1": r"$s^{-1}$",
            "unitless": "unitless", "microm^-1*s^-1": r"$\mu M^{-1}\,s^{-1}$",
            "um^-1*s^-1": r"$\mu M^{-1}\,s^{-1}$"}.get(compact, text.strip())


def lines_cell(text: str, *, plain: bool = False, trim_single: bool = False) -> str:
    text = (text or "").replace(r"\n", "\n")
    def escape(value: str) -> str:
        if not plain:
            return value
        for old, new in [("\\", r"\textbackslash{}"), ("&", r"\&"), ("%", r"\%"),
                         ("#", r"\#"), ("_", r"\_")]:
            value = value.replace(old, new)
        return value
    if "\n" not in text and "\r" not in text:
        return escape(text.strip() if trim_single or plain else text)
    parts = [escape(part.rstrip()) for part in text.splitlines() if part.rstrip()]
    if not parts:
        return ""
    if plain and len(parts) == 1:
        return parts[0]
    return r"\shortstack[c]{" + r"\\\\[-0.3ex]".join(parts) + "}"


def parameter_cell(text: str, *, always_math: bool) -> str:
    parameter, units = split_parameter(text)
    if not units:
        return "$" + parameter + "$" if always_math and parameter else parameter
    return "$" + parameter + "$ (" + units_latex(units) + ")"


def parameter_table(csv_path: Path, destination: Path, number: int) -> None:
    """Port the existing PowerShell ST1/ST3 TeX generators cell-for-cell."""
    with csv_path.open(encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        fields = reader.fieldnames or []
        rows = list(reader)
    required = ["RowType", "Parameter (units)", "Cell Type", "Value", "References"] if number == 2 else ["Parameter (units)", "Fixed/Free", "Mean", "Approximate Range", "References"]
    if not rows or not set(required).issubset(fields):
        raise ValueError(f"Missing required CSV rows/columns: {csv_path}")
    st1 = number == 2
    keys = list(dict.fromkeys(split_parameter(row["Parameter (units)"])[0] for row in rows if row.get("RowType", "").strip().lower() == "entry")) if st1 else ["[GCaMP]", "R_f", r"\Delta Ca_{spike}", "ca_0", r"\gamma", r"\gamma_{in}", r"\gamma_{out}", r"\kappa_{B}"]
    if any(key not in DESCRIPTIONS for key in keys) or (st1 and not keys):
        raise ValueError("Missing parameter descriptions or entry rows.")
    caption = "Single-cell model parameter values." if st1 else "Cell-parameter prior means and approximate ranges."
    label = "single-cell-parameters" if st1 else "cell-parameter-priors"
    specs = r"L{0.30\linewidth} C{0.14\linewidth} C{0.14\linewidth} L{0.34\linewidth}" if st1 else r"L{0.24\linewidth} C{0.10\linewidth} C{0.14\linewidth} C{0.18\linewidth} L{0.34\linewidth}"
    headers = ["Parameter (units)", "Cell Type", "Value", "References"] if st1 else ["Parameter (units)", "Fixed/Free", "Mean", "Approximate range", "References"]
    lines = [f"% Auto-generated from: {csv_path}", r"% Requires: \\usepackage{booktabs}",
             r"% Requires: \\usepackage{xcolor}" + ("" if st1 else "  % for colored sensor labels in cells"),
             r"% Requires: \\usepackage{array}" + ("" if st1 else "   % for column formatting"),
             r"\begin{table}[htbp]", r"\centering", r"\small", r"\setlength{\tabcolsep}{6pt}",
             r"\renewcommand{\arraystretch}{1.35}", r"\caption{" + caption + "}",
             r"\label{tab:" + label + "}", r"\newcolumntype{L}[1]{>{\raggedright\arraybackslash}p{#1}}",
             r"\newcolumntype{C}[1]{>{\centering\arraybackslash}p{#1}}", r"\begin{tabular}{" + specs + "}",
             r"\toprule", " & ".join(r"\textbf{" + h + "}" for h in headers) + r" \\", r"\midrule"]
    for row in rows:
        row_type = row.get("RowType", "").strip().lower()
        if row_type == "section":
            title = lines_cell(row["Parameter (units)"], plain=st1)
            if st1:
                title = title.replace("Ca^{2+}", "$Ca^{2+}$").replace("Mg^{2+}", "$Mg^{2+}$")
            if title:
                lines += [r"\addlinespace[0.45em]", rf"\multicolumn{{{len(headers)}}}{{c}}{{\textbf{{{title}}}}} \\", r"\addlinespace[0.15em]"]
            continue
        if st1 and row_type != "entry":
            raise ValueError(f"Unsupported RowType {row_type!r}")
        cells = [parameter_cell(row["Parameter (units)"], always_math=st1)]
        columns = ["Cell Type", "Value", "References"] if st1 else ["Fixed/Free", "Mean", "Approximate Range", "References"]
        cells += [lines_cell(row[field], plain=st1) for field in columns]
        lines.append(" & ".join(cells) + r" \\")
    lines += [r"\bottomrule", r"\end{tabular}", r"\end{table}", "", r"% Bracket commands for description labels (avoids `]` inside \item[...] optional args).", r"\providecommand{\lbrack}{[}", r"\providecommand{\rbrack}{]}", "", r"\noindent\textbf{Parameter definitions.}", r"\begin{description}", r"\setlength{\itemsep}{0.25em}"]
    for key in keys:
        display = key.replace("[", r"\lbrack ").replace("]", r"\rbrack")
        lines.append(r"\item[$" + display + "$] " + DESCRIPTIONS[key])
    lines += [r"\end{description}", ""]
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text("\n".join(lines) + "\n", encoding="utf-8")


def run(command: list[str], *, cwd: Path) -> None:
    subprocess.run(command, cwd=cwd, check=True)


def render(wrapper: Path, python: str, output_dir: Path | None = None,
           pdflatex: str = "pdflatex", keep_build: bool = False) -> Path:
    wrapper = wrapper.resolve()
    stem, number = TABLES[wrapper.stem]
    item = wrapper.parents[1]
    root = next(parent for parent in item.parents if (parent / "tools/publication_config.py").is_file())
    output_dir = output_dir.resolve() if output_dir else root / "build" / item.relative_to(root)
    output_dir.mkdir(parents=True, exist_ok=True)
    tex = output_dir / f"{stem}.tex"
    if number == 1:
        run([python, str(wrapper.parent / "make_table1_precision_recall_fscore_csv.py"), "--sna", str(root / "figures/main/figure4/source_data/02_Epoch_precision_recall.csv"), "--matched", str(root / "figures/main/figure4/source_data/01_Matched_spike_bias.csv"), "--output-csv", str(tex.with_suffix('.csv'))], cwd=root)
        run([python, str(wrapper.parent / "make_table1_precision_recall_fscore_tex.py"), "--csv", str(tex.with_suffix('.csv')), "--output-tex", str(tex)], cwd=root)
    elif number == 3:
        run([python, str(wrapper.parent / "make_gcamp_params_table.py"), "--input-csv", str(item / "source_data/01_ST2_existing_values.csv"), "--output-prefix", str(output_dir / stem)], cwd=root)
    else:
        csv_name = "01_ST1_existing_values.csv" if number == 2 else "01_ST3_existing_values.csv"
        parameter_table(item / "source_data" / csv_name, tex, number)
    if shutil.which(pdflatex) is None:
        raise FileNotFoundError("pdflatex not found. Install TeX Live (including booktabs, xcolor and array) or pass --pdflatex.")
    build = Path(tempfile.mkdtemp(prefix=".latex_build_", dir=output_dir))
    try:
        document = build / "table_wrapper.tex"
        if number == 1:
            shutil.copyfile(tex, document)
        else:
            document.write_text("\n".join([r"\documentclass[10pt]{article}", r"\usepackage[margin=0.75in]{geometry}", r"\usepackage{booktabs}", r"\usepackage{xcolor}", *([r"\usepackage{array}"] if number != 3 else []), r"\begin{document}", r"\pagestyle{empty}", rf"\setcounter{{table}}{{{number - 1}}}", r"\input{" + tex.as_posix() + "}", r"\end{document}", ""]), encoding="utf-8")
        logs = []
        try:
            for _ in range(2):
                result = subprocess.run([pdflatex, "-file-line-error", "-interaction=batchmode", "-halt-on-error", document.name], cwd=build, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, errors="replace", check=False)
                logs.append(result.stdout or "")
                if result.returncode:
                    raise RuntimeError(f"pdflatex failed ({result.returncode}); see {output_dir / (stem + '.latex.log')} and {output_dir / (stem + '.pdflatex.log')}")
        finally:
            (output_dir / f"{stem}.pdflatex.log").write_text("\n".join(logs), encoding="utf-8")
            if document.with_suffix('.log').exists():
                shutil.copyfile(document.with_suffix('.log'), output_dir / f"{stem}.latex.log")
        pdf = output_dir / f"{stem}.pdf"
        shutil.copyfile(document.with_suffix('.pdf'), pdf)
        return pdf
    finally:
        if not keep_build:
            shutil.rmtree(build)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--wrapper", required=True, type=Path)
    parser.add_argument("--python", default=sys.executable)
    parser.add_argument("--output-dir", type=Path)
    parser.add_argument("--pdflatex", default="pdflatex")
    parser.add_argument("--keep-build-dir", action="store_true")
    args = parser.parse_args()
    if args.wrapper.stem not in TABLES:
        parser.error("Unknown table wrapper")
    print(render(args.wrapper, args.python, args.output_dir, args.pdflatex, args.keep_build_dir))


if __name__ == "__main__":
    main()
