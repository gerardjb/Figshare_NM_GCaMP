"""Reproduce figure panels, tables, and source-data workbooks."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

from publication_config import ITEMS, REPO_ROOT


TOOLS = Path(__file__).resolve().parent


def run(script: str, *arguments: str) -> None:
    subprocess.run([sys.executable, str(TOOLS / script), *arguments], cwd=REPO_ROOT, check=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target", choices=["workbooks", "figures", "extract", "all"])
    parser.add_argument("--matlab", default="matlab", help="MATLAB executable for figure generation.")
    parser.add_argument("--item", action="append", help="Publication ID, such as Figure1, ED8, or SupplementaryTable1; may be repeated.")
    parser.add_argument("--csv-only", action="store_true", help="For figure generation, use only scripts that read the packaged CSV data.")
    args = parser.parse_args()
    selected = set(args.item or [])
    known = {str(item["publication_id"]) for item in ITEMS}
    unknown = sorted(selected - known)
    if unknown:
        parser.error(f"Unknown publication IDs: {', '.join(unknown)}")
    if args.target == "extract":
        if selected or args.csv_only:
            parser.error("extract reproduces the PPR CSVs for Figures 1h and 2i; --item and --csv-only do not apply.")
        run("extract_source_data.py")
        return
    if args.csv_only and args.target == "workbooks":
        parser.error("--csv-only applies to figures or all; workbooks already use the packaged CSV data.")

    if args.target in {"workbooks", "all"}:
        workbook_items = [
            str(item["source_data_item"]) for item in ITEMS
            if item["source_data_item"] is not None
            and (not selected or item["publication_id"] in selected)
        ]
        if not workbook_items and args.target == "workbooks":
            parser.error("The selected items have no source-data workbook.")
        if workbook_items:
            workbook_args = [argument for item in workbook_items for argument in ("--item", item)]
            run("build_workbooks.py", *workbook_args)
    if args.target in {"figures", "all"}:
        figure_args = ["--matlab", args.matlab]
        for item in args.item or []:
            figure_args += ["--item", item]
        if args.csv_only:
            figure_args.append("--csv-only")
        run("build_figures.py", *figure_args)


if __name__ == "__main__":
    main()
