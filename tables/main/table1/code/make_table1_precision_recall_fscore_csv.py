"""Calculate the Table 1 summary statistics from Figure 4 artifacts."""

from __future__ import annotations

import argparse
from pathlib import Path

import pandas as pd


METHOD_ORDER = [
    "Biophys_{SMC}",
    "PGBAR",
    "MLspike",
    "Biophys_{ML}",
    "CASCADE",
    "ENS^2",
]

PERFORMANCE_COLUMNS = {
    "precision": "Precision",
    "recall": "Recall",
    "f": "F-Score",
    "accuracy": "Accuracy",
}

TIMING_COLUMNS = {
    "bias": "Mean bias (ms)",
    "uncertainty": "Mean error (ms)",
}


def require_columns(data: pd.DataFrame, columns: set[str], source: Path) -> None:
    missing = sorted(columns.difference(data.columns))
    if missing:
        raise ValueError(f"{source} is missing required columns: {missing}")


def require_methods(data: pd.DataFrame, source: Path) -> None:
    present = set(data["method"].dropna().unique())
    missing = [method for method in METHOD_ORDER if method not in present]
    if missing:
        raise ValueError(f"{source} is missing required methods: {missing}")


def mean_sd(summary: pd.DataFrame, value: str, method: str) -> str:
    mean = summary.loc[method, (value, "mean")]
    std = summary.loc[method, (value, "std")]
    return f"{mean:.2f} ± {std:.2f}"


def calculate_table(sna_path: Path, matched_path: Path) -> pd.DataFrame:
    sna = pd.read_csv(sna_path)
    matched = pd.read_csv(matched_path)

    require_columns(
        sna,
        {"method", "cell", "trial", *PERFORMANCE_COLUMNS},
        sna_path,
    )
    require_columns(
        matched,
        {"method", "cell_epoch", *TIMING_COLUMNS},
        matched_path,
    )
    require_methods(sna, sna_path)
    require_methods(matched, matched_path)

    # Each row in sna_matching_trials.csv is one method/cell/trial result.
    duplicate_trials = sna.duplicated(["method", "cell", "trial"])
    if duplicate_trials.any():
        raise ValueError(
            f"{sna_path} contains duplicate method/cell/trial rows; "
            "Table 1 expects one performance result per trial."
        )
    performance = sna.groupby("method")[list(PERFORMANCE_COLUMNS)].agg(
        ["mean", "std"]
    )

    # matched_bias_uncert.csv has one row per matched spike. Give every trial
    # equal weight by averaging its events first, then summarize trials.
    timing_by_epoch = (
        matched.groupby(["method", "cell_epoch"])[list(TIMING_COLUMNS)]
        .mean()
        .mul(1000)  # seconds to milliseconds
        .reset_index()
    )
    timing = timing_by_epoch.groupby("method")[list(TIMING_COLUMNS)].agg(
        ["mean", "std"]
    )

    rows: list[dict[str, str]] = []
    for method in METHOD_ORDER:
        row = {"Method": method}
        row.update(
            {
                label: mean_sd(performance, source, method)
                for source, label in PERFORMANCE_COLUMNS.items()
            }
        )
        row.update(
            {
                label: mean_sd(timing, source, method)
                for source, label in TIMING_COLUMNS.items()
            }
        )
        rows.append(row)

    return pd.DataFrame(rows)


def main() -> None:
    script_dir = Path(__file__).resolve().parent
    repo_root = script_dir.parents[3]
    parser = argparse.ArgumentParser(
        description="Calculate Table 1 from the Figure 4 matching artifacts."
    )
    parser.add_argument(
        "--sna",
        type=Path,
        default=repo_root / "figures" / "main" / "figure4" / "source_data" / "02_Epoch_precision_recall.csv",
        help="Trial-level spike matching metrics.",
    )
    parser.add_argument(
        "--matched",
        type=Path,
        default=repo_root / "figures" / "main" / "figure4" / "source_data" / "01_Matched_spike_bias.csv",
        help="Matched-spike bias and uncertainty records.",
    )
    parser.add_argument(
        "--output-csv",
        type=Path,
        default=repo_root / "build" / "tables" / "main" / "table1" / "table1_precision_recall_fscore.csv",
        help="Generated Table 1 summary CSV.",
    )
    args = parser.parse_args()

    table = calculate_table(args.sna, args.matched)
    args.output_csv.parent.mkdir(parents=True, exist_ok=True)
    table.to_csv(args.output_csv, index=False, encoding="utf-8")
    print(f"Wrote CSV: {args.output_csv}")


if __name__ == "__main__":
    main()
