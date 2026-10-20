"""Render publication tables directly from CSV with ReportLab.

This presentation layer preserves the source numeric strings. Table 1 first
uses its existing Figure 4 summary calculation; parameter tables read their
canonical CSVs. No TeX installation or operating-system shell is required.
"""
from __future__ import annotations

import argparse
import csv
import importlib.util
import re
import shutil
from html import escape
from pathlib import Path

import matplotlib
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle


ROOT = Path(__file__).resolve().parents[1]
TABLES = {
    "Table1": ("tables/main/table1", "table1_precision_recall_fscore", "Table 1. Spike-inference performance."),
    "SupplementaryTable1": ("tables/supplementary/table1", "table2_cell_parameters", "Supplementary Table 1. Single-cell model parameter values."),
    "SupplementaryTable2": ("tables/supplementary/table2", "gcamp_parameter_table", "Supplementary Table 2. GCaMP model parameter sets."),
    "SupplementaryTable3": ("tables/supplementary/table3", "Table4_cell_parameter_priors", "Supplementary Table 3. Cell-parameter prior means and approximate ranges."),
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


def register_fonts() -> None:
    """Embed fonts bundled with the already-required Matplotlib package."""
    directory = Path(matplotlib.get_data_path()) / "fonts" / "ttf"
    for name, filename in [("TableSans", "DejaVuSans.ttf"), ("TableSans-Bold", "DejaVuSans-Bold.ttf"), ("TableSans-Italic", "DejaVuSans-Oblique.ttf"), ("TableSans-BoldItalic", "DejaVuSans-BoldOblique.ttf")]:
        if name not in pdfmetrics.getRegisteredFontNames():
            pdfmetrics.registerFont(TTFont(name, str(directory / filename)))
    pdfmetrics.registerFontFamily("TableSans", normal="TableSans", bold="TableSans-Bold", italic="TableSans-Italic", boldItalic="TableSans-BoldItalic")


def markup(text: str) -> str:
    """Translate the limited scientific notation present in the source CSVs.

    Color commands retain their text in monochrome. Unknown commands raise an
    error rather than silently dropping mathematical or explanatory content.
    """
    text = str(text).replace(r"\n", "\n").replace("\r\n", "\n")
    position = 0
    symbols = {"Delta": "Δ", "gamma": "γ", "kappa": "κ", "mu": "μ", "times": "×", "pm": "±"}

    def group() -> str:
        nonlocal position
        if position >= len(text) or text[position] != "{":
            raise ValueError(f"Expected a grouped expression in {text!r}")
        position += 1
        result = parse("}")
        return result

    def parse(stop: str = "") -> str:
        nonlocal position
        result = []
        while position < len(text):
            char = text[position]
            position += 1
            if char == "}":
                if stop:
                    return "".join(result)
                raise ValueError(f"Unmatched closing brace in {text!r}")
            if char == "{":
                result.append(parse("}"))
            elif char in "_^":
                tag = "sub" if char == "_" else "super"
                if position < len(text) and text[position] == "{":
                    content = group()
                else:
                    match = re.match(r"[+-]?\d+|.", text[position:])
                    if not match:
                        raise ValueError(f"Missing subscript/superscript in {text!r}")
                    content = escape(match[0])
                    position += len(match[0])
                result.append(f"<{tag}>{content}</{tag}>")
            elif char == "\\":
                match = re.match(r"[A-Za-z]+|.", text[position:])
                if not match:
                    raise ValueError(f"Incomplete command in {text!r}")
                command = match[0]
                position += len(command)
                if command in symbols:
                    result.append(symbols[command])
                elif command in {"mathrm", "text", "textbf"}:
                    content = group()
                    result.append(f"<b>{content}</b>" if command == "textbf" else content)
                elif command == "textcolor":
                    if text[position:position + 6] == "[HTML]":
                        position += 6
                    group()  # Discard the color specification, preserve its text.
                    result.append(group())
                elif command in {",", ";", " "}:
                    result.append(" ")
                elif command in {"&", "%", "#", "_", "{", "}", "$"}:
                    result.append(escape(command))
                else:
                    raise ValueError(f"Unsupported table notation \\{command} in {text!r}")
            elif char == "$":
                continue
            elif char == "\n":
                result.append("<br/>")
            else:
                result.append(escape(char))
        if stop:
            raise ValueError(f"Unclosed expression in {text!r}")
        return "".join(result)

    return parse()


def split_parameter(text: str) -> tuple[str, str]:
    match = re.fullmatch(r"(.+?)\s*\(([^)]*)\)\s*", text.strip())
    return (match[1].strip(), match[2].strip()) if match else (text.strip(), "")


def units_text(text: str) -> str:
    return {"microM": "μM", "um": "μM", "microM^-1*s^-1": "μM^-1 s^-1", "um^-1*s^-1": "μM^-1 s^-1"}.get(text, text)


def parameter_text(text: str) -> str:
    parameter, units = split_parameter(text)
    return parameter + (f" ({units_text(units)})" if units else "")


def read_csv(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    with path.open(encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        fields = reader.fieldnames or []
        rows = list(reader)
    if not fields or not rows:
        raise ValueError(f"Table CSV is empty: {path}")
    if any(None in row or any(value is None for value in row.values()) for row in rows):
        raise ValueError(f"Malformed CSV row: {path}")
    return fields, rows


def table1_csv(item: Path, destination: Path) -> None:
    """Call the existing scientific calculation without changing its arithmetic."""
    path = item / "code/make_table1_precision_recall_fscore_csv.py"
    spec = importlib.util.spec_from_file_location("table1_calculation", path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load Table 1 calculation: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    data = module.calculate_table(ROOT / "figures/main/figure4/source_data/02_Epoch_precision_recall.csv", ROOT / "figures/main/figure4/source_data/01_Matched_spike_bias.csv")
    data.to_csv(destination, index=False, encoding="utf-8")


def render(item_id: str, output_dir: Path | None = None) -> Path:
    relative, stem, title = TABLES[item_id]
    item = ROOT / relative
    output_dir = output_dir.resolve() if output_dir else ROOT / "build" / relative
    output_dir.mkdir(parents=True, exist_ok=True)
    csv_path = output_dir / f"{stem}.csv"
    if item_id == "Table1":
        table1_csv(item, csv_path)
    else:
        source = item / "source_data" / {"SupplementaryTable1": "01_ST1_existing_values.csv", "SupplementaryTable2": "01_ST2_existing_values.csv", "SupplementaryTable3": "01_ST3_existing_values.csv"}[item_id]
        if source.resolve() != csv_path.resolve():
            shutil.copyfile(source, csv_path)
    fields, rows = read_csv(csv_path)
    register_fonts()
    wide = item_id == "SupplementaryTable2"
    page = landscape(A4) if wide else A4
    available_width = page[0] - 72
    body = ParagraphStyle("TableBody", fontName="TableSans", fontSize=8.5, leading=11, alignment=TA_LEFT)
    center = ParagraphStyle("TableCenter", parent=body, alignment=TA_CENTER)
    bold = ParagraphStyle("TableBold", parent=body, fontName="TableSans-Bold")
    heading = ParagraphStyle("TableTitle", parent=bold, fontSize=11, leading=15, spaceAfter=12, keepWithNext=True)
    definition = ParagraphStyle("TableDefinition", parent=body, spaceAfter=5)

    def cell(value: str, style: ParagraphStyle = body) -> Paragraph:
        return Paragraph(markup(value), style)

    keys: list[str] = []
    sections: list[int] = []
    data: list[list[Paragraph]] = []
    if item_id == "Table1":
        if fields[0] != "Method":
            raise ValueError("Table 1 requires a Method column.")
        headers = ["Method", *("Uncertainty (ms)" if x == "Mean error (ms)" else x for x in fields[1:])]
        fractions = [0.17, 0.135, 0.135, 0.135, 0.135, 0.145, 0.145]
        data = [[cell(x, bold) for x in headers]]
        data += [[cell(row[x], body if j == 0 else center) for j, x in enumerate(fields)] for row in rows]
    elif item_id == "SupplementaryTable2":
        if fields[:3] != ["Parameter", "Description", "Units"] or len(fields) < 4:
            raise ValueError("GCaMP CSV requires Parameter, Description, Units and sensor columns.")
        headers = [x.replace(" Janelia", "\nJanelia").replace(" Slice", "\nSlice") for x in fields]
        fractions = [0.10, 0.22, 0.08] + [0.60 / (len(fields) - 3)] * (len(fields) - 3)
        data = [[cell(x, bold) for x in headers]]
        for row in rows:
            values = [row["Parameter"], row["Description"], units_text(row["Units"])]
            for field in fields[3:]:
                value = row[field]
                match = re.fullmatch(r"([+-]?(?:\d+(?:\.\d*)?|\.\d+))[eE]([+-]?\d+)", value)
                if match:
                    value = rf"{match[1]} \times 10^{{{int(match[2])}}}"
                elif not re.fullmatch(r"[+-]?(?:\d+(?:\.\d*)?|\.\d+)", value):
                    raise ValueError(f"Unexpected nonnumeric GCaMP parameter: {value!r}")
                values.append(value)
            data.append([cell(value, body if j < 3 else center) for j, value in enumerate(values)])
    else:
        st1 = item_id == "SupplementaryTable1"
        columns = ["Parameter (units)", "Cell Type", "Value", "References"] if st1 else ["Parameter (units)", "Fixed/Free", "Mean", "Approximate Range", "References"]
        if not set(["RowType", *columns]).issubset(fields):
            raise ValueError(f"Missing parameter-table columns: {csv_path}")
        fractions = [0.34, 0.15, 0.10, 0.41] if st1 else [0.25, 0.13, 0.19, 0.19, 0.24]
        data = [[cell(x, bold) for x in columns]]
        for row in rows:
            kind = row["RowType"].strip().lower()
            if kind == "section":
                sections.append(len(data))
                data.append([cell(row[columns[0]], bold), *[cell("") for _ in columns[1:]]])
            elif kind == "entry":
                key, _ = split_parameter(row[columns[0]])
                if key not in keys:
                    keys.append(key)
                values = [parameter_text(row[columns[0]]), *[row[x] for x in columns[1:]]]
                data.append([cell(value, body if j in {0, len(columns) - 1} else center) for j, value in enumerate(values)])
            else:
                raise ValueError(f"Unsupported RowType: {kind!r}")
        if any(key not in DESCRIPTIONS for key in keys):
            raise ValueError("Missing definition for a table parameter.")

    if len(fractions) != len(data[0]):
        raise ValueError("Unexpected number of table columns.")
    widths = [available_width * x / sum(fractions) for x in fractions]
    styles = [("VALIGN", (0, 0), (-1, -1), "TOP"), ("LEFTPADDING", (0, 0), (-1, -1), 5), ("RIGHTPADDING", (0, 0), (-1, -1), 5), ("TOPPADDING", (0, 0), (-1, -1), 6), ("BOTTOMPADDING", (0, 0), (-1, -1), 6), ("LINEABOVE", (0, 0), (-1, 0), 0.8, colors.black), ("LINEBELOW", (0, 0), (-1, 0), 0.6, colors.black), ("LINEBELOW", (0, -1), (-1, -1), 0.8, colors.black)]
    for row_index in sections:
        styles += [("SPAN", (0, row_index), (-1, row_index)), ("LINEABOVE", (0, row_index), (-1, row_index), 0.3, colors.HexColor("#999999")), ("NOSPLIT", (0, row_index), (-1, min(row_index + 1, len(data) - 1)))]
    table = Table(data, colWidths=widths, repeatRows=1, hAlign="LEFT", style=TableStyle(styles))
    story = [Paragraph(escape(title), heading), table]
    if keys:
        story += [Spacer(1, 14), Paragraph("Parameter definitions", heading)]
        for key in keys:
            story.append(Paragraph(f"<b>{markup(key)}</b>: {markup(DESCRIPTIONS[key])}", definition))
    pdf = output_dir / f"{stem}.pdf"
    document = SimpleDocTemplate(str(pdf), pagesize=page, leftMargin=36, rightMargin=36, topMargin=36, bottomMargin=36, title=title, author="Broussard et al.")
    document.build(story)
    return pdf


def main(default_item: str | None = None) -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--item", choices=TABLES, default=default_item, required=default_item is None)
    parser.add_argument("--output-dir", type=Path, help="Destination directory for the table CSV and PDF.")
    args = parser.parse_args()
    print(render(args.item, args.output_dir))


if __name__ == "__main__":
    main()
