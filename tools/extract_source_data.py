"""Reproduce the Figure 1h and Figure 2i PPR CSVs from their original MAT input.

Outputs are written below build/extracted_source_data by default. Figure and
workbook generation use the supplied CSVs in each figure's source_data folder.
"""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path

import numpy as np
from scipy.io import loadmat

from publication_config import REPO_ROOT


def canonical_ppr(output_root: Path) -> list[dict[str, object]]:
    source = REPO_ROOT / "figures" / "main" / "figure1" / "inputs" / "figure1_H_J_data.mat"
    loaded = loadmat(source, squeeze_me=True, struct_as_record=False)
    ppr = loaded["PPR"]
    sensors = [("OGB5N", [10, 100]), ("G6f", [10, 20, 50, 100]), ("jG7f", [10, 20, 50, 100]), ("jG8f", [10, 20, 50, 100])]
    records: list[list[object]] = []
    for sensor, intervals in sensors:
        values = np.atleast_2d(np.asarray(getattr(ppr, sensor), dtype=float))
        if values.shape[1] != len(intervals):
            raise ValueError(f"Unexpected {sensor} PPR shape: {values.shape}")
        for row_index, row in enumerate(values, start=1):
            for interval, value in zip(intervals, row):
                records.append([sensor, row_index, interval, "" if np.isnan(value) else repr(float(value))])

    outputs = []
    for relative, with_selection in [
        (Path("Figure1") / "04_Panel_H_PPR.csv", False),
        (Path("Figure2") / "07_I_PPR_inputs.csv", True),
    ]:
        destination = output_root / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        header = ["indicator", "source_row_index", "stimulus_interval", "normalized_second_response"]
        if with_selection:
            header.append("selected_for_I")
        with destination.open("w", encoding="utf-8", newline="") as stream:
            writer = csv.writer(stream, lineterminator="\n")
            writer.writerow(header)
            for record in records:
                writer.writerow([*record, str(record[2] == 10)] if with_selection else record)
        outputs.append({
            "source": source.relative_to(REPO_ROOT).as_posix(),
            "output": str(destination.resolve()),
            "rows": len(records),
        })
    return outputs


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, default=REPO_ROOT / "build" / "extracted_source_data")
    parser.add_argument("--report", type=Path, help="Optional JSON summary of the generated CSVs.")
    args = parser.parse_args()
    outputs = canonical_ppr(args.output_dir)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(outputs, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(outputs, indent=2))


if __name__ == "__main__":
    main()
