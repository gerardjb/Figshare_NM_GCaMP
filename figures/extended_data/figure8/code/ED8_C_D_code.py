"""Standalone plotting script for Extended Data Figure 8 panels C and D."""

from __future__ import annotations

import argparse
import atexit
import shutil
import stat
import sys
from pathlib import Path

import numpy as np
import pandas as pd

try:
    from SharedUtilities.trialwise_plots import (
        ensure_matplotlib_cache_dir,
        load_trace_panel_data,
        plot_corr_vs_sigma,
        plot_trace_panel,
    )
    from SharedUtilities.project_paths import figure_dir, figure_output_dir
except ImportError:
    sys.path.insert(0, str(Path(__file__).resolve().parents[4] / "shared" / "python"))
    from SharedUtilities.trialwise_plots import (  # type: ignore
        ensure_matplotlib_cache_dir,
        load_trace_panel_data,
        plot_corr_vs_sigma,
        plot_trace_panel,
    )
    from SharedUtilities.project_paths import figure_dir, figure_output_dir  # type: ignore


HERE = figure_dir("extended_data/figure8", __file__)
FIGURE_ROOT = Path(__file__).resolve().parents[1]
SOURCE_DATA = FIGURE_ROOT / "source_data"
DEFAULT_CSV = SOURCE_DATA / "01_Epoch_correlations.csv"
DEFAULT_TRACE = SOURCE_DATA / "02_ED8C_trace_values.csv"
DEFAULT_SPIKES = SOURCE_DATA / "C_ground_truth_spikes.csv"
DEFAULT_OUTPUT_DIR = figure_output_dir("extended_data/figure8", __file__)
TMP_DIR = HERE / "tmp"

BIOPHYS_SMC = "#009E73"
# The published parameter-comparison panels distinguish the two traces by
# dash pattern while retaining the Biophys_SMC green for both.
JANELIA_PARAM = BIOPHYS_SMC

METHODS = ["pgas@base", "pgas@pgas_jG8f_params"]
COLORS = {
    "pgas@base": BIOPHYS_SMC,
    "pgas@pgas_jG8f_params": JANELIA_PARAM,
}
LABELS = {
    "pgas@base": "BiophysSMC (ex vivo)",
    "pgas@pgas_jG8f_params": "BiophysSMC (Janelia)",
}
LINESTYLES = {
    "pgas@base": "-",
    "pgas@pgas_jG8f_params": "--",
}


def _canonicalize_trace_data(trace_path: Path, spike_path: Path = DEFAULT_SPIKES) -> dict:
    table = pd.read_csv(trace_path)
    # Preserve the published panel-C row order: Janelia parameters above the
    # ex-vivo parameters.
    keys = ["pgas@pgas_jG8f_params", "pgas@base"]
    columns = ["prediction_BiophysSMC_Janelia", "prediction_BiophysSMC_exvivo"]
    traces = table[columns].to_numpy(float).T
    gt = table["ground_truth_trace"].to_numpy(float)
    correlations = [float(np.corrcoef(gt, trace)[0, 1]) for trace in traces]
    spikes = pd.read_csv(spike_path)["spike_time_s"].to_numpy(float)
    return {
        "time": table["time_s"].to_numpy(float),
        "fluorescence": table["fluorescence_raw_dff"].to_numpy(float),
        "fluorescence_plot": table["fluorescence_display_dff"].to_numpy(float),
        "ground_truth": gt,
        "method_traces": traces,
        "method_keys": keys,
        "method_labels": [LABELS[key] for key in keys],
        "method_colors": [COLORS[key] for key in keys],
        "method_linestyles": [LINESTYLES[key] for key in keys],
        "method_correlations": correlations,
        "spike_times": spikes,
        "title": "Excitatory cell sample",
    }


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Create Extended Data Figure 8 panels C and D from reviewed CSV exports."
    )
    parser.add_argument("--csv", type=Path, default=DEFAULT_CSV, help="Parameter-comparison CSV for panel D.")
    parser.add_argument("--trace", type=Path, default=DEFAULT_TRACE, help="Trace-panel CSV export for panel C.")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR, help="Directory for output figures.")
    parser.add_argument(
        "--format",
        dest="formats",
        action="append",
        default=None,
        choices=["pdf", "png", "svg"],
        help="Output format. Repeat for multiple formats. Defaults to pdf.",
    )
    parser.add_argument("--show", action="store_true", help="Display figures interactively after saving.")
    return parser


def _cleanup_tmp_dir() -> None:
    if not TMP_DIR.exists():
        return
    for path in sorted(TMP_DIR.rglob("*"), key=lambda p: len(p.parts), reverse=True):
        try:
            path.chmod(stat.S_IREAD | stat.S_IWRITE | stat.S_IEXEC)
        except OSError:
            pass
    try:
        TMP_DIR.chmod(stat.S_IREAD | stat.S_IWRITE | stat.S_IEXEC)
    except OSError:
        pass
    shutil.rmtree(TMP_DIR, ignore_errors=True)
    if not TMP_DIR.exists():
        return
    for path in sorted(TMP_DIR.rglob("*"), key=lambda p: len(p.parts), reverse=True):
        try:
            path.chmod(stat.S_IREAD | stat.S_IWRITE | stat.S_IEXEC)
        except OSError:
            pass
        try:
            if path.is_dir():
                path.rmdir()
            else:
                path.unlink()
        except OSError:
            pass
    try:
        TMP_DIR.chmod(stat.S_IREAD | stat.S_IWRITE | stat.S_IEXEC)
    except OSError:
        pass
    try:
        TMP_DIR.rmdir()
    except OSError:
        pass


def main(argv: list[str] | None = None) -> None:
    args = build_arg_parser().parse_args(argv)
    ensure_matplotlib_cache_dir(TMP_DIR / "mpl_cache")
    atexit.register(_cleanup_tmp_dir)

    import matplotlib.pyplot as plt

    try:
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

        trace_data = _canonicalize_trace_data(args.trace.resolve())
        fig_c, _, _ = plot_trace_panel(trace_data, figsize=(3.4, 4.8), ymax=4.6)

        fig_d, _ = plot_corr_vs_sigma(
            csv_path=args.csv.resolve(),
            methods=METHODS,
            smoothings=["raw"],
            colors=COLORS,
            labels=LABELS,
            linestyles=LINESTYLES,
            title=None,
            ylim=(0.6, 1.0),
            xlim=(0.0, 110.0),
            figsize=(3.4, 2.6),
        )

        for stem, fig in [
            ("ED8_C_trace_param_compare", fig_c),
            ("ED8_D_corr_vs_sigma_param_compare", fig_d),
        ]:
            for fmt in output_formats:
                out_path = output_dir / f"{stem}.{fmt}"
                fig.savefig(out_path)
                print(f"Saved {out_path}")

        if args.show:
            plt.show()
    finally:
        plt.close("all")
        _cleanup_tmp_dir()


if __name__ == "__main__":
    main()
