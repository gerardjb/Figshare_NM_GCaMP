"""Standalone plotting script for Extended Data Figure 7 trialwise analyses."""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path
from typing import Iterable

try:
    from SharedUtilities.trialwise_plots import (
        ensure_matplotlib_cache_dir,
        load_trace_panel_data,
        plot_raincloud_by_downsample,
        plot_trace_panel,
    )
    from SharedUtilities.project_paths import figure_dir, figure_output_dir
except ImportError:
    sys.path.insert(0, str(Path(__file__).resolve().parents[4] / "shared" / "python"))
    from SharedUtilities.trialwise_plots import (  # type: ignore
        ensure_matplotlib_cache_dir,
        load_trace_panel_data,
        plot_raincloud_by_downsample,
        plot_trace_panel,
    )
    from SharedUtilities.project_paths import figure_dir, figure_output_dir  # type: ignore


HERE = figure_dir("extended_data/figure7", __file__)
SOURCE_DATA_DIR = Path(__file__).resolve().parents[1] / "source_data"
DEFAULT_CSV = SOURCE_DATA_DIR / "01_Plotted_epoch_correlations.csv"
DEFAULT_OUTPUT_DIR = figure_output_dir("extended_data/figure7", __file__)
TMP_DIR = HERE / "tmp"

DEFAULT_METHODS = [
    "pgas@base",
    "biophys_ml=ens2@updated_biophys-ml_cascade",
    "ens2=ens2@base",
    "cascade@updated_biophys-ml_cascade",
    "mlspike@matlab_mlspike",
]

DEFAULT_SMOOTHINGS = ["raw", "30Hz", "10Hz"]


def _existing_trace_files(paths: Iterable[Path]) -> list[Path]:
    out: list[Path] = []
    for path in paths:
        path = Path(path)
        if path.is_dir():
            out.extend(sorted(path.glob("*.npz")))
            out.extend(sorted(path.glob("*.mat")))
        elif path.exists() and path.suffix.lower() in {".npz", ".mat"}:
            out.append(path)
    return out


def _registered_trace_panel(condition_index: int) -> dict:
    import numpy as np
    import pandas as pd

    fluorescence = pd.read_csv(
        SOURCE_DATA_DIR / f"A_condition{condition_index}_fluorescence_groundtruth.csv"
    )
    predictions = pd.read_csv(
        SOURCE_DATA_DIR / f"A_condition{condition_index}_predictions.csv"
    )
    spikes = pd.read_csv(
        SOURCE_DATA_DIR / f"A_condition{condition_index}_spike_times.csv"
    )
    metadata = pd.read_csv(SOURCE_DATA_DIR / "A_trace_metadata_correlations.csv")
    metadata = metadata[metadata["condition_index"] == condition_index]
    method_keys = list(metadata["method"])
    method_palette = {
        "pgas@base": "#009E73",
        "biophys_ml": "#007755",
        "ens2": "#A6780C",
        "cascade@updated_biophys-ml_cascade": "#F3AE14",
        "mlspike@matlab_mlspike": "#0072B2",
    }
    method_traces = np.vstack([
        predictions.loc[
            predictions["method"] == method, "displayed_normalized_prediction"
        ].to_numpy(dtype=float)
        for method in method_keys
    ])
    acquisition = str(metadata["acquisition_condition"].iloc[0])
    return {
        "time": fluorescence["time_s"].to_numpy(dtype=float),
        "fluorescence": fluorescence["displayed_baseline_subtracted_DeltaF_over_F"].to_numpy(dtype=float),
        "fluorescence_plot": fluorescence["displayed_baseline_subtracted_DeltaF_over_F"].to_numpy(dtype=float),
        "ground_truth": fluorescence["displayed_normalized_ground_truth"].to_numpy(dtype=float),
        "method_traces": method_traces,
        "method_keys": method_keys,
        "method_labels": list(metadata["method_label"]),
        "method_colors": [method_palette.get(method, "#333333") for method in method_keys],
        "method_correlations": metadata["pearson_r"].to_numpy(dtype=float),
        "spike_times": spikes["spike_time_s"].to_numpy(dtype=float),
        "title": acquisition,
    }


def _write_trace_panels(trace_inputs: list, output_dir: Path, output_formats: list[str]) -> None:
    import matplotlib.pyplot as plt

    if not trace_inputs:
        print("No trace-panel inputs found; skipping trace panels.")
        return

    fig, axes = plt.subplots(
        1,
        len(trace_inputs),
        figsize=(3.2 * len(trace_inputs), 5.2),
        squeeze=False,
    )
    for ax, trace_input in zip(axes.ravel(), trace_inputs):
        trace_data = (
            load_trace_panel_data(trace_input)
            if isinstance(trace_input, Path) else trace_input
        )
        plot_trace_panel(trace_data, ax=ax)
    for fmt in output_formats:
        out_path = output_dir / f"ED7_trace_panels.{fmt}"
        fig.savefig(out_path)
        print(f"Saved {out_path}")
    plt.close(fig)


def _cleanup_tmp_dir() -> None:
    if TMP_DIR.exists():
        shutil.rmtree(TMP_DIR, ignore_errors=True)


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Create the Extended Data Figure 7 raincloud and trace panels from "
            "the packaged CSV and exported trace arrays."
        )
    )
    parser.add_argument("--csv", type=Path, default=DEFAULT_CSV, help="Trialwise correlation CSV.")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR, help="Directory for output figures.")
    parser.add_argument(
        "--trace-panel",
        type=Path,
        nargs="*",
        default=None,
        help="Optional exported trace-panel .npz/.mat files or directories.",
    )
    parser.add_argument(
        "--format",
        dest="formats",
        action="append",
        default=None,
        choices=["pdf", "png", "svg"],
        help="Output format. Repeat for multiple formats. Defaults to pdf.",
    )
    parser.add_argument(
        "--show",
        action="store_true",
        help="Display figures interactively after saving.",
    )
    return parser


def main(argv: list[str] | None = None) -> None:
    args = build_arg_parser().parse_args(argv)
    ensure_matplotlib_cache_dir(TMP_DIR / "mpl_cache")
    import matplotlib.pyplot as plt

    try:
        csv_path = args.csv.resolve()
        output_dir = args.output_dir.resolve()
        output_dir.mkdir(parents=True, exist_ok=True)
        output_formats = args.formats or ["pdf"]

        plt.rcParams["font.family"] = "Arial"
        plt.rcParams["font.sans-serif"] = ["Arial"]
        plt.rcParams["pdf.fonttype"] = 42
        plt.rcParams["ps.fonttype"] = 42
        plt.rcParams["text.usetex"] = False
        plt.rcParams["mathtext.fontset"] = "custom"
        plt.rcParams["mathtext.rm"] = "Arial"
        plt.rcParams["mathtext.it"] = "Arial:italic"
        plt.rcParams["mathtext.bf"] = "Arial:bold"

        fig_rain, _ = plot_raincloud_by_downsample(
            csv_path=csv_path,
            corr_sigma_ms=30,
            methods=DEFAULT_METHODS,
            smoothings=DEFAULT_SMOOTHINGS,
            title="Trialwise correlations at 30 ms kernel",
            ylim=(0.0, 1.0),
            figsize=(7.2, 4.2),
            method_label_x_offset_frac=-0.05,
        )

        for fmt in output_formats:
            out_path = output_dir / f"ED7_raincloud_downsample.{fmt}"
            fig_rain.savefig(out_path)
            print(f"Saved {out_path}")

        if args.trace_panel is not None:
            trace_inputs = _existing_trace_files(args.trace_panel)
        else:
            trace_inputs = [_registered_trace_panel(index) for index in range(3)]
        _write_trace_panels(trace_inputs, output_dir, output_formats)

        if args.show:
            plt.show()
    finally:
        plt.close("all")
        _cleanup_tmp_dir()


if __name__ == "__main__":
    main()
