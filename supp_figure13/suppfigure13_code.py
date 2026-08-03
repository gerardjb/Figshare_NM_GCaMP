"""Standalone plotting script for supplementary figure 13 trialwise analyses."""

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
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    from SharedUtilities.trialwise_plots import (  # type: ignore
        ensure_matplotlib_cache_dir,
        load_trace_panel_data,
        plot_raincloud_by_downsample,
        plot_trace_panel,
    )
    from SharedUtilities.project_paths import figure_dir, figure_output_dir  # type: ignore


HERE = figure_dir("supp_figure13", __file__)
DEFAULT_CSV = HERE / "trialwise_correlations_jG8f.csv"
DEFAULT_OUTPUT_DIR = figure_output_dir("supp_figure13", __file__)
DEFAULT_TRACE_DIR = HERE / "trace_panel_exports"
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


def _write_trace_panels(trace_files: list[Path], output_dir: Path, output_formats: list[str]) -> None:
    import matplotlib.pyplot as plt

    if not trace_files:
        print(
            "No exported trace-panel .npz/.mat files found; skipping trace panels. "
            f"Looked in {DEFAULT_TRACE_DIR} unless --trace-panel was supplied."
        )
        return

    fig, axes = plt.subplots(
        1,
        len(trace_files),
        figsize=(3.2 * len(trace_files), 5.2),
        squeeze=False,
    )
    for ax, trace_file in zip(axes.ravel(), trace_files):
        trace_data = load_trace_panel_data(trace_file)
        plot_trace_panel(trace_data, ax=ax)
    for fmt in output_formats:
        out_path = output_dir / f"suppfigure13_trace_panels.{fmt}"
        fig.savefig(out_path)
        print(f"Saved {out_path}")
    plt.close(fig)


def _cleanup_tmp_dir() -> None:
    if TMP_DIR.exists():
        shutil.rmtree(TMP_DIR, ignore_errors=True)


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Create the supplementary figure 13 raincloud and trace panels from "
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
            out_path = output_dir / f"suppfigure13_raincloud_downsample.{fmt}"
            fig_rain.savefig(out_path)
            print(f"Saved {out_path}")

        if args.trace_panel is not None:
            trace_inputs = args.trace_panel
        else:
            trace_inputs = [DEFAULT_TRACE_DIR, *sorted(HERE.glob("smoothing_plot_panel*.npz"))]
        trace_files = _existing_trace_files(trace_inputs)
        _write_trace_panels(trace_files, output_dir, output_formats)

        if args.show:
            plt.show()
    finally:
        plt.close("all")
        _cleanup_tmp_dir()


if __name__ == "__main__":
    main()
