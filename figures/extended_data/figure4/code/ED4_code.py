"""Standalone plotting script for Extended Data Figure 4 simulation panels."""

from __future__ import annotations

import argparse
import shutil
import stat
import sys
from pathlib import Path

try:
    from SharedUtilities.project_paths import figure_dir, figure_output_dir
    from SharedUtilities.trialwise_plots import ensure_matplotlib_cache_dir
except ImportError:
    sys.path.insert(0, str(Path(__file__).resolve().parents[4] / "shared" / "python"))
    from SharedUtilities.project_paths import figure_dir, figure_output_dir  # type: ignore
    from SharedUtilities.trialwise_plots import ensure_matplotlib_cache_dir  # type: ignore


HERE = figure_dir("extended_data/figure4", __file__)
SOURCE_DATA_DIR = Path(__file__).resolve().parents[1] / "source_data"
DEFAULT_OUTPUT_DIR = figure_output_dir("extended_data/figure4", __file__)
TMP_DIR = HERE / "tmp"

BIOPHYS_SMC = "#009E73"
EXC_COLOR = "0.45"
INH_COLOR = "0.0"
GT_COLOR = "0.78"
SINGLE_AP_TIME_MS = 200.0

DATASETS = [
    {
        "cell_type": "pyramidal",
        "actual_snr": "SNR_02_5",
        "display_snr": "SNR_02_5",
        "metric_tag": "pyr",
        "r_label": "r = 0.90",
        "recovered_label": "% Spikes Recovered = 99.8",
    },
    {
        "cell_type": "pyramidal",
        "actual_snr": "SNR_05",
        "display_snr": "SNR_05",
        "metric_tag": "pyr",
        "r_label": "r = 0.91",
        "recovered_label": "% Spikes Recovered = 100",
    },
    {
        "cell_type": "interneuron",
        "actual_snr": "SNR_05",
        "display_snr": "SNR_02_5",
        "metric_tag": "pyr_mod_pv",
        "r_label": "r = 0.92",
        "recovered_label": "% Spikes Recovered = 92.7",
    },
    {
        "cell_type": "interneuron",
        "actual_snr": "SNR_10",
        "display_snr": "SNR_05",
        "metric_tag": "pyr_mod_pv",
        "r_label": "r = 0.92",
        "recovered_label": "% Spikes Recovered = 99.7",
    },
]


def _snr_label(snr_tag: str) -> str:
    return "SNR=2.5" if snr_tag == "SNR_02_5" else "SNR=5"


def _load_csv(path: Path):
    import pandas as pd

    return pd.read_csv(path)


def _inference_paths(cell_type: str, display_snr: str) -> tuple[Path, Path]:
    prefix = "pyr" if cell_type == "pyramidal" else "inh"
    number = {
        ("inh", "SNR_02_5"): ("02", "03"),
        ("inh", "SNR_05"): ("04", "05"),
        ("pyr", "SNR_02_5"): ("06", "07"),
        ("pyr", "SNR_05"): ("08", "09"),
    }[(prefix, display_snr)]
    return (
        SOURCE_DATA_DIR / f"{number[0]}_{prefix}_{display_snr}_trace.csv",
        SOURCE_DATA_DIR / f"{number[1]}_{prefix}_{display_snr}_posterior.csv",
    )


def _load_inference_data(cell_type: str, display_snr: str):
    trace_path, spikes_path = _inference_paths(cell_type, display_snr)
    return _load_csv(trace_path), _load_csv(spikes_path)


def _load_gt_spikes():
    return _load_csv(SOURCE_DATA_DIR / "01_ground_truth_spike_times.csv")["spike_time_s"].to_numpy()


def _find_dataset(cell_type: str, display_snr: str) -> dict:
    for dataset in DATASETS:
        if dataset["cell_type"] == cell_type and dataset["display_snr"] == display_snr:
            return dataset
    raise KeyError((cell_type, display_snr))


def _hide_axes(ax) -> None:
    ax.set_xticks([])
    ax.set_yticks([])
    for spine in ax.spines.values():
        spine.set_visible(False)


def _draw_scale_bar(ax, x_len: float, y_len: float, x_text: str, y_text: str, x_frac: float = 0.08, y_frac: float = 0.08) -> None:
    xlim = ax.get_xlim()
    ylim = ax.get_ylim()
    x0 = xlim[1] - x_frac * (xlim[1] - xlim[0])
    y0 = ylim[1] - y_frac * (ylim[1] - ylim[0])
    ax.plot([x0 - x_len, x0], [y0, y0], color="k", lw=1.1)
    ax.plot([x0, x0], [y0, y0 - y_len], color="k", lw=1.1)
    ax.text(x0 - x_len / 2, y0 + 0.04 * (ylim[1] - ylim[0]), x_text, ha="center", va="bottom", fontsize=6)
    ax.text(x0 + 0.02 * (xlim[1] - xlim[0]), y0 - y_len / 2, y_text, va="center", fontsize=6)


def _plot_inference_dataset(axes, cell_type: str, display_snr: str, show_y_labels: bool = False) -> None:
    import numpy as np

    trace_df, spikes_df = _load_inference_data(cell_type, display_snr)
    gt_spikes = _load_gt_spikes()
    dataset = _find_dataset(cell_type, display_snr)

    time_s = trace_df["time_s"].to_numpy()
    dff = trace_df["dff"].to_numpy()
    avg_spike = trace_df["avg_spike_count"].to_numpy()
    windows = [(6.0, 11.0), (6.0, 7.1)]
    trace_color = EXC_COLOR if cell_type == "pyramidal" else INH_COLOR
    unique_draws = list(spikes_df["draw"].drop_duplicates())[:6]

    for col, (start_s, stop_s) in enumerate(windows):
        mask = (time_s >= start_s) & (time_s <= stop_s)
        if not np.any(mask):
            raise ValueError(f"No data in window {start_s}-{stop_s} s for {cell_type} {display_snr}")
        x = time_s[mask]
        axes[0, col].plot(x, dff[mask], color=trace_color, lw=0.6)
        axes[0, col].set_ylim(-0.2, 1.0)

        for row_idx, draw in enumerate(unique_draws):
            draw_spikes = spikes_df[spikes_df["draw"] == draw]
            draw_spikes = draw_spikes[(draw_spikes["time_s"] >= start_s) & (draw_spikes["time_s"] <= stop_s)]
            axes[1, col].scatter(
                draw_spikes["time_s"],
                [-row_idx * 0.2] * len(draw_spikes),
                color=BIOPHYS_SMC,
                s=5,
                linewidths=0,
            )

        axes[2, col].plot(x, avg_spike[mask], color=BIOPHYS_SMC, lw=0.6)
        axes[2, col].set_ylim(-0.05, max(0.7, float(np.nanmax(avg_spike[mask])) * 1.05))

        xmin, xmax = float(x[0]), float(x[-1])
        for row in range(3):
            axes[row, col].set_xlim(xmin, xmax)
            for spike in gt_spikes[(gt_spikes >= xmin) & (gt_spikes <= xmax)]:
                axes[row, col].axvline(spike, ls="--", color=GT_COLOR, lw=0.55, alpha=0.8)
            _hide_axes(axes[row, col])

    if show_y_labels:
        axes[0, 0].set_ylabel("GCaMP\nfluorescence", fontsize=6)
        axes[1, 0].set_ylabel("Inferred spike\nsamples", fontsize=6)
        axes[2, 0].set_ylabel("Avg inferred\nspike count", fontsize=6)

    axes[0, 0].set_title(_snr_label(display_snr), fontsize=7, pad=1)
    axes[0, 1].set_title("", fontsize=7, pad=1)
    axes[1, 1].text(0.62, 0.6, r"Biophys$_{\mathrm{SMC}}$", color=BIOPHYS_SMC, transform=axes[1, 1].transAxes, fontsize=6)
    _draw_scale_bar(axes[0, 0], 0.5, 0.3, "500 ms", "0.3 ΔF/F")
    _draw_scale_bar(axes[0, 1], 0.3, 0.3, "300 ms", "0.3 ΔF/F", x_frac=0.14)
    ax = axes[2, 0]
    xlim = ax.get_xlim()
    ylim = ax.get_ylim()
    x0 = xlim[1] - 0.08 * (xlim[1] - xlim[0])
    y0 = ylim[1] - 0.08 * (ylim[1] - ylim[0])
    ax.plot([x0, x0], [y0, y0 - 0.5], color="k", lw=1.0)
    ax.text(x0 + 0.02 * (xlim[1] - xlim[0]), y0 - 0.25, "0.5 spikes", va="center", fontsize=6)
    axes[2, 0].text(0.50, -0.22, dataset["r_label"], transform=axes[2, 0].transAxes, ha="center", va="top", fontsize=6)
    axes[2, 1].text(0.50, -0.22, dataset["recovered_label"], transform=axes[2, 1].transAxes, ha="center", va="top", fontsize=6)


def _single_ap_df():
    return _load_csv(SOURCE_DATA_DIR / "10_single_ap_traces.csv")


def _plot_single_ap_pair(ax, df, cell_type: str, display_snr: str | None = None, normalize: bool = False, title: str | None = None) -> None:
    import numpy as np

    explicit = df[(df["cell_type"] == cell_type) & (df["trace_kind"] == "explicit")]
    if display_snr is None:
        inferred = None
    else:
        inferred = df[(df["cell_type"] == cell_type) & (df["trace_kind"] == "inferred") & (df["display_snr"] == display_snr)]

    explicit_y = explicit["dff"].to_numpy()
    if normalize and explicit_y.size and np.nanmax(explicit_y) != 0:
        explicit_y = explicit_y / np.nanmax(explicit_y)
    color = EXC_COLOR if cell_type == "pyramidal" else INH_COLOR
    label = "Simulated Pyramidal-Like Cell" if cell_type == "pyramidal" else "Simulated Interneuron-Like Cell"
    ax.plot(explicit["time_ms"], explicit_y, color=color, lw=0.9, label=label)

    if inferred is not None and not inferred.empty:
        inferred_y = inferred["dff"].to_numpy()
        if normalize and inferred_y.size and np.nanmax(inferred_y) != 0:
            inferred_y = inferred_y / np.nanmax(inferred_y)
        ax.plot(inferred["time_ms"], inferred_y, color=BIOPHYS_SMC, lw=0.9, label="Inferred Single AP Response")

    ax.axvline(SINGLE_AP_TIME_MS, linestyle="--", color="k", lw=0.65)
    ax.set_xlim(90, 700)
    if normalize:
        ax.set_ylim(-0.03, 1.05)
        y_len = 0.2
        y_text = "0.2 norm. ΔF/F"
    elif cell_type == "interneuron":
        ax.set_ylim(-0.01, 0.16)
        y_len = 0.05
        y_text = "0.05 ΔF/F"
    else:
        ax.set_ylim(-0.02, 0.42)
        y_len = 0.1
        y_text = "0.1 ΔF/F"
    _hide_axes(ax)
    _draw_scale_bar(ax, 100, y_len, "100 ms", y_text, x_frac=0.35, y_frac=0.12)
    if title:
        ax.set_title(title, fontsize=7, pad=2)


def _plot_panel_a_axes(ax_norm, ax_raw, df) -> None:
    _plot_single_ap_pair(ax_norm, df, "pyramidal", normalize=True, title="Normalized")
    explicit_inh = df[(df["cell_type"] == "interneuron") & (df["trace_kind"] == "explicit")]
    inh_y = explicit_inh["dff"].to_numpy()
    if inh_y.size and inh_y.max() != 0:
        inh_y = inh_y / inh_y.max()
    ax_norm.plot(explicit_inh["time_ms"], inh_y, color=INH_COLOR, lw=0.9, label="Simulated Interneuron-Like Cell")

    _plot_single_ap_pair(ax_raw, df, "pyramidal", normalize=False, title="Unnormalized")
    explicit_inh_raw = explicit_inh["dff"].to_numpy()
    ax_raw.plot(
        explicit_inh["time_ms"],
        explicit_inh_raw,
        color=INH_COLOR,
        lw=0.9,
        label="Simulated Interneuron-Like Cell",
    )


def plot_panel_a(figsize=(6.8, 1.65)):
    import matplotlib.pyplot as plt

    df = _single_ap_df()
    fig, axes = plt.subplots(1, 2, figsize=figsize)
    _plot_panel_a_axes(axes[0], axes[1], df)
    handles, labels = axes[1].get_legend_handles_labels()
    fig.legend(handles, labels, frameon=False, fontsize=5.5, loc="lower right", bbox_to_anchor=(0.98, 0.02))
    fig.suptitle("Explicit Buffer Model Simulated Single AP", fontsize=9, y=0.98)
    fig.subplots_adjust(wspace=0.16, top=0.82, bottom=0.16)
    return fig


def plot_inference_panel(cell_type: str, figsize=(3.55, 5.1)):
    import matplotlib.pyplot as plt

    fig = plt.figure(figsize=figsize)
    grid = fig.add_gridspec(2, 1, hspace=0.28)
    for block_idx, display_snr in enumerate(["SNR_02_5", "SNR_05"]):
        axes = np_axes(fig, grid[block_idx, 0].subgridspec(3, 2, hspace=0.06, wspace=0.24))
        _plot_inference_dataset(axes, cell_type, display_snr, show_y_labels=block_idx == 0)
    title = "Biophys$_{\\mathrm{SMC}}$ on Simulated Pyramidal-Like Cell"
    if cell_type == "interneuron":
        title = "Biophys$_{\\mathrm{SMC}}$ on Simulated Interneuron-Like Cell"
    fig.suptitle(title, fontsize=8, y=0.99)
    return fig


def np_axes(fig, subgrid):
    import numpy as np

    axes = np.empty((3, 2), dtype=object)
    for row in range(3):
        for col in range(2):
            axes[row, col] = fig.add_subplot(subgrid[row, col])
    return axes


def plot_panel_d_e(figsize=(6.8, 1.7)):
    import matplotlib.pyplot as plt

    df = _single_ap_df()
    fig, axes = plt.subplots(1, 4, figsize=figsize)
    specs = [
        ("pyramidal", "SNR_02_5", "SNR = 2.5"),
        ("pyramidal", "SNR_05", "SNR = 5"),
        ("interneuron", "SNR_02_5", "SNR = 2.5"),
        ("interneuron", "SNR_05", "SNR = 5"),
    ]
    for ax, (cell_type, snr, title) in zip(axes, specs):
        _plot_single_ap_pair(ax, df, cell_type, snr, normalize=False, title=title)
    axes[0].legend(frameon=False, fontsize=5, loc="upper right")
    axes[2].legend(frameon=False, fontsize=5, loc="upper right")
    fig.subplots_adjust(wspace=0.22)
    return fig


def plot_full_figure(figsize=(7.2, 9.4)):
    import matplotlib.pyplot as plt

    fig = plt.figure(figsize=figsize)
    outer = fig.add_gridspec(3, 2, height_ratios=[0.9, 4.8, 1.1], hspace=0.34, wspace=0.22)

    df = _single_ap_df()
    top = outer[0, :].subgridspec(1, 2, wspace=0.16)
    _plot_panel_a_axes(fig.add_subplot(top[0, 0]), fig.add_subplot(top[0, 1]), df)
    fig.text(0.50, 0.962, "Explicit Buffer Model Simulated Single AP", ha="center", fontsize=9)

    left = outer[1, 0].subgridspec(2, 1, hspace=0.24)
    right = outer[1, 1].subgridspec(2, 1, hspace=0.24)
    for block_idx, display_snr in enumerate(["SNR_02_5", "SNR_05"]):
        _plot_inference_dataset(
            np_axes(fig, left[block_idx, 0].subgridspec(3, 2, hspace=0.05, wspace=0.22)),
            "pyramidal",
            display_snr,
            show_y_labels=True,
        )
        _plot_inference_dataset(
            np_axes(fig, right[block_idx, 0].subgridspec(3, 2, hspace=0.05, wspace=0.22)),
            "interneuron",
            display_snr,
            show_y_labels=True,
        )

    bottom = outer[2, :].subgridspec(1, 4, wspace=0.22)
    specs = [
        ("pyramidal", "SNR_02_5", "SNR = 2.5"),
        ("pyramidal", "SNR_05", "SNR = 5"),
        ("interneuron", "SNR_02_5", "SNR = 2.5"),
        ("interneuron", "SNR_05", "SNR = 5"),
    ]
    for idx, (cell_type, snr, title) in enumerate(specs):
        _plot_single_ap_pair(fig.add_subplot(bottom[0, idx]), df, cell_type, snr, normalize=False, title=title)

    fig.text(0.02, 0.965, "A", fontsize=9)
    fig.text(0.02, 0.765, "B", fontsize=9)
    fig.text(0.51, 0.765, "C", fontsize=9)
    fig.text(0.02, 0.205, "D", fontsize=9)
    fig.text(0.51, 0.205, "E", fontsize=9)
    fig.text(0.25, 0.77, "Biophys$_{\\mathrm{SMC}}$ on Simulated Pyramidal-Like Cell", ha="center", fontsize=8)
    fig.text(0.74, 0.77, "Biophys$_{\\mathrm{SMC}}$ on Simulated Interneuron-Like Cell", ha="center", fontsize=8)
    fig.text(0.50, 0.235, "Simulated vs. Inferred Single AP", ha="center", fontsize=8)
    return fig


def _configure_matplotlib() -> None:
    import matplotlib.pyplot as plt

    plt.rcParams["font.family"] = "Arial"
    plt.rcParams["font.sans-serif"] = ["Arial", "DejaVu Sans"]
    plt.rcParams["pdf.fonttype"] = 42
    plt.rcParams["ps.fonttype"] = 42
    plt.rcParams["text.usetex"] = False
    plt.rcParams["mathtext.fontset"] = "custom"
    plt.rcParams["mathtext.rm"] = "Arial"
    plt.rcParams["mathtext.it"] = "Arial:italic"
    plt.rcParams["mathtext.bf"] = "Arial:bold"


def _cleanup_tmp_dir() -> None:
    if not TMP_DIR.exists():
        return
    for path in sorted(TMP_DIR.rglob("*"), key=lambda p: len(p.parts), reverse=True):
        try:
            path.chmod(stat.S_IREAD | stat.S_IWRITE | stat.S_IEXEC)
        except OSError:
            pass
    try:
        shutil.rmtree(TMP_DIR, ignore_errors=True)
    except OSError:
        pass


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Create Extended Data Figure 4 panels from compact processed CSV exports."
    )
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

    import matplotlib.pyplot as plt

    try:
        required = [
            SOURCE_DATA_DIR / "10_single_ap_traces.csv",
            SOURCE_DATA_DIR / "01_ground_truth_spike_times.csv",
        ]
        for dataset in DATASETS:
            required.extend(_inference_paths(dataset["cell_type"], dataset["display_snr"]))
        missing = [path for path in required if not path.exists()]
        if missing:
            missing_text = "\n".join(str(path) for path in missing)
            raise FileNotFoundError(f"Missing processed Extended Data Figure 4 data:\n{missing_text}")

        _configure_matplotlib()
        output_dir = args.output_dir.resolve()
        output_dir.mkdir(parents=True, exist_ok=True)
        output_formats = args.formats or ["pdf"]

        figures = {
            "ED4_A_single_ap_overlay": plot_panel_a(),
            "ED4_B_pyramidal_inference": plot_inference_panel("pyramidal"),
            "ED4_C_interneuron_inference": plot_inference_panel("interneuron"),
            "ED4_D_E_single_ap_recovery": plot_panel_d_e(),
            "ED4_full": plot_full_figure(),
        }
        for stem, fig in figures.items():
            for fmt in output_formats:
                out_path = output_dir / f"{stem}.{fmt}"
                fig.savefig(out_path, bbox_inches="tight")
                print(f"Saved {out_path}")

        if args.show:
            plt.show()
    finally:
        plt.close("all")
        _cleanup_tmp_dir()


if __name__ == "__main__":
    main()
