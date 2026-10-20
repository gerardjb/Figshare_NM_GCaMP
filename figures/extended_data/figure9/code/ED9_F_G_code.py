"""Standalone plotting script for Extended Data Figure 9 panels F and G."""

from __future__ import annotations

import argparse
import atexit
import shutil
import stat
import sys
from pathlib import Path

import numpy as np
import pandas as pd

PROJECT_ROOT = Path(__file__).resolve().parents[4]
SHARED_PYTHON = PROJECT_ROOT / "shared" / "python"
if str(SHARED_PYTHON) not in sys.path:
    sys.path.insert(0, str(SHARED_PYTHON))

from SharedUtilities.trialwise_plots import (  # noqa: E402
    ensure_matplotlib_cache_dir,
    load_trace_panel_data,
    plot_corr_vs_sigma,
    plot_trace_panel,
)
from SharedUtilities.project_paths import figure_dir, figure_output_dir  # noqa: E402


HERE = figure_dir("extended_data/figure9", __file__)
FIGURE_ROOT = Path(__file__).resolve().parents[1]
SOURCE_DATA = FIGURE_ROOT / "source_data"
DEFAULT_CSV = SOURCE_DATA / "02_Epoch_correlations.csv"
DEFAULT_TRACE = SOURCE_DATA / "03_ED9F_trace_values.csv"
DEFAULT_SPIKES = SOURCE_DATA / "F_ground_truth_spikes.csv"
DEFAULT_OUTPUT_DIR = figure_output_dir("extended_data/figure9", __file__)
TMP_DIR = HERE / "tmp"

METHODS = [
    "pgas@pgasraw",
    "biophys_ml=ens2@ens2_jG8m_sweep2_best_k2_r9_s2p0_d0p45_sb19000",
    "ens2=ens2@cascadein_nodisc_ens2",
    "cascade@cascade_updated_model",
    "mlspike@matlab_mlspike_jG8m2",
    "pgbar@pgbar_janelia_8m",
]

COLORS = {
    "pgas@pgasraw": "#009E73",
    "biophys_ml": "#007755",
    "ens2": "#A6780C",
    "cascade": "#F3AE14",
    "mlspike": "#0072B2",
    "pgbar": "#4A4A4A",
}

LABELS = {
    "pgas@pgasraw": r"Biophys$_{SMC}$",
    "biophys_ml": r"Biophys$_{ML}$",
    "ens2": r"ENS$^2$",
    "cascade": "CASCADE",
    "mlspike": "MLspike",
    "pgbar": "PGBAR",
}


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


def _canonicalize_trace_data(trace_path: Path, spike_path: Path = DEFAULT_SPIKES) -> dict:
    table = pd.read_csv(trace_path)
    keys = ["pgas@pgasraw", "pgbar", "biophys_ml", "ens2", "cascade", "mlspike"]
    columns = [
        "prediction_Biophys$_{SMC}$", "prediction_PGBAR",
        "prediction_Biophys$_{ML}$", "prediction_ENS$^2$",
        "prediction_CASCADE", "prediction_MLspike",
    ]
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
        "method_correlations": correlations,
        "spike_times": spikes,
        "title": "Excitatory cell sample",
    }


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Create Extended Data Figure 9 panels F and G from reviewed CSV exports."
    )
    parser.add_argument("--csv", type=Path, default=DEFAULT_CSV, help="jGCaMP8m trialwise correlation CSV.")
    parser.add_argument("--trace", type=Path, default=DEFAULT_TRACE, help="Trace-panel CSV export for panel F.")
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
        method_count = len(trace_data["method_traces"])
        trace_height = 4.8 + 0.7 * max(0, method_count - 5)
        fig_f, _, _ = plot_trace_panel(
            trace_data,
            figsize=(4.4, trace_height),
            fluorescence_linewidth=1.35,
            ground_truth_linewidth=1.45,
            method_linewidth=1.55,
        )

        fig_g, _ = plot_corr_vs_sigma(
            csv_path=args.csv.resolve(),
            methods=METHODS,
            smoothings=["raw"],
            colors=COLORS,
            labels=LABELS,
            title=None,
            ylim=(0.6, 1.0),
            xlim=(0.0, 110.0),
            figsize=(7.2, 2.8),
            match_c_spikes_axes=True,
        )

        for stem, fig in [
            ("ED9_F_trace_jG8m_compare", fig_f),
            ("ED9_G_corr_vs_sigma_jG8m", fig_g),
        ]:
            for fmt in output_formats:
                out_path = output_dir / f"{stem}.{fmt}"
                fig.savefig(out_path, bbox_inches="tight", pad_inches=0.02)
                print(f"Saved {out_path}")

        if args.show:
            plt.show()
    finally:
        plt.close("all")
        _cleanup_tmp_dir()


if __name__ == "__main__":
    main()
