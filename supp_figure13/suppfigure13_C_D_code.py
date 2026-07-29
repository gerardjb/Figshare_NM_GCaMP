"""Standalone plotting script for supplementary figure 13 panels C and D."""

from __future__ import annotations

import argparse
import atexit
import shutil
import stat
import sys
from pathlib import Path

try:
    from SharedUtilities.trialwise_plots import (
        ensure_matplotlib_cache_dir,
        load_trace_panel_data,
        plot_corr_vs_sigma,
        plot_trace_panel,
    )
    from SharedUtilities.project_paths import figure_dir, figure_output_dir
except ImportError:
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    from SharedUtilities.trialwise_plots import (  # type: ignore
        ensure_matplotlib_cache_dir,
        load_trace_panel_data,
        plot_corr_vs_sigma,
        plot_trace_panel,
    )
    from SharedUtilities.project_paths import figure_dir, figure_output_dir  # type: ignore


HERE = figure_dir("supp_figure13", __file__)
DEFAULT_CSV = HERE / "trialwise_correlations_jG8f_param_comparison.csv"
DEFAULT_TRACE = HERE / "param_compare_out.npz"
DEFAULT_OUTPUT_DIR = figure_output_dir("supp_figure13", __file__)
TMP_DIR = HERE / "tmp"

BIOPHYS_SMC = "#009E73"
JANELIA_PARAM = "#000000"

METHODS = ["pgas@base", "pgas@pgas_jG8f_params"]
COLORS = {
    "pgas@base": BIOPHYS_SMC,
    "pgas@pgas_jG8f_params": JANELIA_PARAM,
}
LABELS = {
    "pgas@base": r"Biophys$_{SMC}$",
    "pgas@pgas_jG8f_params": "biophys_smc_J",
}
LINESTYLES = {
    "pgas@base": "-",
    "pgas@pgas_jG8f_params": "--",
}


def _canonicalize_trace_data(trace_path: Path) -> dict:
    data = load_trace_panel_data(trace_path)
    method_runs = [str(x) for x in data.get("method_runs", [])]
    raw_methods = [str(x) for x in data.get("methods", [])]

    method_keys = []
    for method, run in zip(raw_methods, method_runs):
        if run == "base" and method in {"biophys_ml", "pgas", "pgas@base"}:
            method_keys.append("pgas@base")
        elif run == "pgas_jG8f_params":
            method_keys.append("pgas@pgas_jG8f_params")
        else:
            method_keys.append(method)

    data["method_keys"] = method_keys
    data["method_labels"] = [LABELS.get(key, key) for key in method_keys]
    data["method_colors"] = [COLORS.get(key, "#333333") for key in method_keys]
    data["method_linestyles"] = [LINESTYLES.get(key, "-") for key in method_keys]
    data["title"] = "Excitatory cell sample"
    return data


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Create supplementary figure 13 panels C and D from packaged CSV/NPZ exports."
    )
    parser.add_argument("--csv", type=Path, default=DEFAULT_CSV, help="Parameter-comparison CSV for panel D.")
    parser.add_argument("--trace", type=Path, default=DEFAULT_TRACE, help="Trace-panel NPZ export for panel C.")
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
            ("suppfigure13_C_trace_param_compare", fig_c),
            ("suppfigure13_D_corr_vs_sigma_param_compare", fig_d),
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
