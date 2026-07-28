from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Optional, Sequence

os.environ.setdefault("MKL_THREADING_LAYER", "SEQ")
os.environ.setdefault("MKL_NUM_THREADS", "1")
os.environ.setdefault("OMP_NUM_THREADS", "1")
os.environ.setdefault("OPENBLAS_NUM_THREADS", "1")
os.environ.setdefault("NUMEXPR_NUM_THREADS", "1")

import numpy as np
import pandas as pd
import scipy.io as sio


Pathish = str | Path | os.PathLike[str]

DEFAULT_COLORS: dict[str, str] = {
    "pgas": "#009E73",
    "pgas@base": "#009E73",
    "biophys_smc": "#009E73",
    "biophys_ml": "#007755",
    "ens2": "#A6780C",
    "ens2_published": "#A6780C",
    "cascade": "#F3AE14",
    "cascade_published": "#F3AE14",
    "mlspike": "#0072B2",
    "mlspike_matlab_reference": "#0072B2",
    "pgbar": "#4A4A4A",
}

DEFAULT_LABELS: dict[str, str] = {
    "pgas": r"Biophys$_{SMC}$",
    "pgas@base": r"Biophys$_{SMC}$",
    "biophys_smc": r"Biophys$_{SMC}$",
    "biophys_ml": r"Biophys$_{ML}$",
    "ens2": r"ENS$^2$",
    "ens2_published": r"ENS$^2$",
    "cascade": "CASCADE",
    "cascade_published": "CASCADE",
    "mlspike": "MLspike",
    "mlspike_matlab_reference": "MLspike",
    "pgbar": "PGBAR",
}


@dataclass(frozen=True)
class SeriesSpec:
    key: str
    method: Optional[str] = None
    run: Optional[str] = None


def ensure_matplotlib_cache_dir(cache_dir: Optional[Pathish] = None) -> Path:
    """Point Matplotlib at a local writable cache directory."""
    candidates = [Path(cache_dir)] if cache_dir is not None else [Path.cwd() / "tmp" / "mpl_cache"]
    for cand in candidates:
        cand = cand.expanduser().resolve()
        cand.mkdir(parents=True, exist_ok=True)
        os.environ.setdefault("MPLCONFIGDIR", str(cand))
        os.environ.setdefault("XDG_CACHE_HOME", str(cand))
        return cand
    return Path.cwd()


def _to_path(path: Pathish) -> Path:
    return Path(path).expanduser().resolve()


def read_trialwise_csv(path: Pathish) -> pd.DataFrame:
    df = pd.read_csv(_to_path(path))
    required = {"dataset", "smoothing", "method", "run", "corr_sigma_ms", "trial", "correlation"}
    missing = required.difference(df.columns)
    if missing:
        raise ValueError(f"{path} is missing required columns: {sorted(missing)}")
    if "series_key" not in df.columns:
        df["series_key"] = df["method"].astype(str)
    return df


def _parse_series_specs(items: Optional[Sequence[str]], df: pd.DataFrame) -> list[SeriesSpec]:
    if items is None:
        if "notebook_series_spec" in df.columns:
            raw = [x for x in df["notebook_series_spec"].dropna().astype(str).unique() if x]
            if raw:
                return _parse_series_specs(raw, df)
        keys = [x for x in df["series_key"].dropna().astype(str).unique() if x]
        return [SeriesSpec(key=k) for k in keys]

    specs: list[SeriesSpec] = []
    for item in items:
        token = str(item).strip()
        if not token:
            continue
        if "=" in token:
            key, rhs = token.split("=", 1)
            key = key.strip()
        else:
            key, rhs = token, token
        if "@" in rhs:
            method, run = rhs.split("@", 1)
            method = method.strip()
            run = run.strip()
        else:
            method, run = rhs.strip(), None
        specs.append(SeriesSpec(key=key.strip(), method=method or None, run=run or None))
    return specs


def _series_mask(df: pd.DataFrame, spec: SeriesSpec) -> pd.Series:
    if spec.method is not None:
        mask = df["method"].astype(str).eq(spec.method)
        if spec.run:
            mask &= df["run"].astype(str).eq(spec.run)
        return mask
    return df["series_key"].astype(str).eq(spec.key)


def _series_label(df: pd.DataFrame, spec: SeriesSpec, labels: Mapping[str, str]) -> str:
    if spec.key in labels:
        return labels[spec.key]
    mask = _series_mask(df, spec)
    if mask.any() and "display_method" in df.columns:
        display = df.loc[mask, "display_method"].dropna().astype(str)
        if not display.empty:
            txt = display.iloc[0]
            txt = txt.replace("BiophysSMC", r"Biophys$_{SMC}$")
            txt = txt.replace("BiophysML", r"Biophys$_{ML}$")
            txt = txt.replace("Published ENS2", r"ENS$^2$")
            txt = txt.replace("Published CASCADE", "CASCADE")
            txt = txt.replace("MLspike MATLAB reference", "MLspike")
            return txt
    method = spec.method or spec.key
    return labels.get(method, method)


def _series_color(spec: SeriesSpec, colors: Mapping[str, str]) -> str:
    return colors.get(spec.key, colors.get(spec.method or "", "#333333"))


def _series_linestyle(spec: SeriesSpec, linestyles: Mapping[str, str]) -> str:
    return linestyles.get(spec.key, linestyles.get(spec.method or "", "-"))


def _finite(values: Sequence[float]) -> np.ndarray:
    arr = np.asarray(values, dtype=float).ravel()
    return arr[np.isfinite(arr)]


def _mean_sem(values: Sequence[float]) -> tuple[float, float, int]:
    arr = _finite(values)
    n = int(arr.size)
    if n == 0:
        return np.nan, np.nan, 0
    if n == 1:
        return float(arr[0]), 0.0, 1
    return float(np.mean(arr)), float(np.std(arr, ddof=1) / np.sqrt(n)), n


def _normalize_0_1(values: Sequence[float]) -> np.ndarray:
    arr = np.asarray(values, dtype=float)
    finite = arr[np.isfinite(arr)]
    if finite.size == 0:
        return np.zeros_like(arr, dtype=float)
    lo = float(np.min(finite))
    hi = float(np.max(finite))
    if hi <= lo:
        return np.zeros_like(arr, dtype=float)
    return (arr - lo) / (hi - lo)


def _place_right_labels(
    ax: Any,
    fig: Any,
    *,
    x: float,
    y_positions: Sequence[float],
    labels: Sequence[str],
    colors: Sequence[str],
    min_sep: float,
    fontsize: float = 12,
    sort_by_y: bool = True,
    transform: Any = None,
    pad_px: float = 2.0,
    bbox_expand_y: float = 1.08,
) -> None:
    ys = [float(y) for y in y_positions]
    if sort_by_y:
        order = np.argsort([-y if np.isfinite(y) else np.inf for y in ys]).tolist()
    else:
        order = list(range(len(ys)))

    ordered_ys = [ys[index] for index in order]
    ordered_labels = [labels[index] for index in order]
    ordered_colors = [colors[index] for index in order]
    for index in range(1, len(ordered_ys)):
        if not np.isfinite(ordered_ys[index - 1]) or not np.isfinite(ordered_ys[index]):
            continue
        if ordered_ys[index - 1] - ordered_ys[index] < min_sep:
            ordered_ys[index] = ordered_ys[index - 1] - min_sep

    if transform is None:
        transform = ax.transData

    texts = []
    for y, label, color in zip(ordered_ys, ordered_labels, ordered_colors):
        if not np.isfinite(y):
            continue
        texts.append(
            ax.text(
                x,
                y,
                label,
                color=color,
                fontsize=fontsize,
                fontweight="bold",
                ha="left",
                va="center",
                clip_on=False,
                transform=transform,
            )
        )

    fig.canvas.draw()
    renderer = fig.canvas.get_renderer()
    pad_px = max(0.0, float(pad_px))
    bbox_expand_y = max(1.0, float(bbox_expand_y))
    previous_bbox = None
    for text in texts:
        bbox = text.get_window_extent(renderer=renderer).expanded(1.0, bbox_expand_y)
        while previous_bbox is not None and bbox.overlaps(previous_bbox):
            shift_px = float(bbox.y1 - previous_bbox.y0 + pad_px)
            x_display, y_display = transform.transform(text.get_position())
            _, new_y = transform.inverted().transform((x_display, y_display - shift_px))
            text.set_position((x, float(new_y)))
            fig.canvas.draw()
            bbox = text.get_window_extent(renderer=renderer).expanded(1.0, bbox_expand_y)
        previous_bbox = bbox

    axes_bbox = ax.get_window_extent(renderer=renderer)
    if texts:
        bboxes = [text.get_window_extent(renderer=renderer) for text in texts]
        top = max(bbox.y1 for bbox in bboxes)
        bottom = min(bbox.y0 for bbox in bboxes)
        shift_up = 0.0
        if top > axes_bbox.y1:
            shift_up = axes_bbox.y1 - top
        if bottom + shift_up < axes_bbox.y0:
            shift_up = axes_bbox.y0 - bottom
        if shift_up:
            for text in texts:
                x_display, y_display = transform.transform(text.get_position())
                _, new_y = transform.inverted().transform((x_display, y_display + shift_up))
                text.set_position((x, float(new_y)))

    fig.canvas.draw_idle()


def _filter_trialwise(
    df: pd.DataFrame,
    *,
    smoothings: Optional[Sequence[str]] = None,
    datasets: Optional[Sequence[str]] = None,
    runs: Optional[Sequence[str]] = None,
    corr_sigma_ms: Optional[float] = None,
) -> pd.DataFrame:
    out = df.copy()
    if smoothings is not None:
        out = out[out["smoothing"].astype(str).isin([str(x) for x in smoothings])]
    if datasets is not None:
        out = out[out["dataset"].astype(str).isin([str(x) for x in datasets])]
    if runs is not None:
        out = out[out["run"].astype(str).isin([str(x) for x in runs])]
    if corr_sigma_ms is not None:
        out = out[np.isclose(out["corr_sigma_ms"].astype(float), float(corr_sigma_ms), atol=1e-6)]
    return out


def plot_corr_vs_sigma(
    *,
    csv_path: Pathish,
    out_path: Optional[Pathish] = None,
    smoothings: Optional[Sequence[str]] = None,
    datasets: Optional[Sequence[str]] = None,
    runs: Optional[Sequence[str]] = None,
    methods: Optional[Sequence[str]] = None,
    reduce: str = "dataset",
    title: Optional[str] = None,
    ylabel: str = "Pearson correlation",
    xlim: tuple[float, float] = (0.0, 110.0),
    ylim: tuple[float, float] = (0.6, 1.0),
    figsize: tuple[float, float] = (5.0, 2.5),
    dpi: int = 200,
    match_c_spikes_axes: bool = False,
    right_label_x_offset_frac: float = 0.08,
    right_label_xlim_frac: float = 0.22,
    right_label_pad_px: float = 4.0,
    right_label_bbox_expand_y: float = 1.10,
    grid_x_step_ms: float = 20.0,
    grid_y_step_corr: float = 0.1,
    grid_color: str = "#808080",
    grid_alpha: float = 0.3,
    grid_linewidth: float = 1.0,
    axis_linewidth: float = 1.0,
    ax: Any = None,
    colors: Optional[Mapping[str, str]] = None,
    labels: Optional[Mapping[str, str]] = None,
    linestyles: Optional[Mapping[str, str]] = None,
) -> tuple[Any, Any]:
    """Plot mean +/- SEM trialwise correlation against Gaussian filter width."""
    if reduce not in {"dataset", "trial"}:
        raise ValueError("reduce must be 'dataset' or 'trial'")

    ensure_matplotlib_cache_dir()
    import matplotlib.pyplot as plt
    from matplotlib.ticker import MultipleLocator

    df = _filter_trialwise(read_trialwise_csv(csv_path), smoothings=smoothings, datasets=datasets, runs=runs)
    if df.empty:
        raise ValueError("No rows matched the requested filters.")

    specs = _parse_series_specs(methods, df)
    colors_map = {**DEFAULT_COLORS, **dict(colors or {})}
    labels_map = {**DEFAULT_LABELS, **dict(labels or {})}
    linestyles_map = dict(linestyles or {})

    if ax is None:
        fig, ax = plt.subplots(figsize=figsize, dpi=dpi)
    else:
        fig = ax.figure
    if match_c_spikes_axes:
        plt.rcParams.update({"font.size": 12})
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    if match_c_spikes_axes:
        ax.spines["left"].set_linewidth(float(axis_linewidth))
        ax.spines["bottom"].set_linewidth(float(axis_linewidth))
        ax.tick_params(axis="both", which="both", width=float(axis_linewidth))

    label_rows: list[tuple[str, str, float]] = []
    for spec in specs:
        sub = df[_series_mask(df, spec)].copy()
        if sub.empty:
            continue
        if reduce == "dataset":
            sub = (
                sub.groupby(["series_key", "corr_sigma_ms", "dataset", "run", "smoothing"], as_index=False)[
                    "correlation"
                ]
                .mean()
                .copy()
            )
        x_vals: list[float] = []
        y_vals: list[float] = []
        y_errs: list[float] = []
        for sigma, g in sub.groupby("corr_sigma_ms"):
            mean, sem, n = _mean_sem(g["correlation"])
            if n:
                x_vals.append(float(sigma))
                y_vals.append(mean)
                y_errs.append(sem)
        if not x_vals:
            continue
        order = np.argsort(x_vals)
        x = np.asarray(x_vals)[order]
        y = np.asarray(y_vals)[order]
        err = np.asarray(y_errs)[order]
        color = _series_color(spec, colors_map)
        label = _series_label(df, spec, labels_map)
        line_width = 2.5 if match_c_spikes_axes else 2.0
        ax.plot(x, y, color=color, linewidth=line_width, linestyle=_series_linestyle(spec, linestyles_map))
        ax.fill_between(x, y - err, y + err, color=color, alpha=0.18, linewidth=0)
        label_rows.append((label, color, float(y[-1])))

    ax.set_xlabel("Filter Width (ms)")
    ax.set_ylabel(ylabel)
    ax.set_xlim(*xlim)
    ax.set_ylim(*ylim)
    if title:
        ax.set_title(title)
    if match_c_spikes_axes:
        ax.xaxis.set_major_locator(MultipleLocator(float(grid_x_step_ms)))
        ax.yaxis.set_major_locator(MultipleLocator(float(grid_y_step_corr)))
        ax.grid(
            True,
            which="major",
            color=str(grid_color),
            alpha=float(grid_alpha),
            linewidth=float(grid_linewidth),
        )
        ax.tick_params(which="major", length=6)
    else:
        ax.grid(True, color="#808080", alpha=0.25, linewidth=1)

    if label_rows:
        y_min, y_max = ax.get_ylim()
        if match_c_spikes_axes:
            ranked_rows = sorted(
                label_rows,
                key=lambda row: (-(row[2] if np.isfinite(row[2]) else -1e9), row[0]),
            )
            _place_right_labels(
                ax,
                fig,
                x=1.0 + float(right_label_x_offset_frac),
                y_positions=[row[2] for row in ranked_rows],
                labels=[row[0] for row in ranked_rows],
                colors=[row[1] for row in ranked_rows],
                min_sep=0.09 * (y_max - y_min),
                fontsize=14,
                sort_by_y=False,
                transform=ax.get_yaxis_transform(),
                pad_px=float(right_label_pad_px),
                bbox_expand_y=float(right_label_bbox_expand_y),
            )
        else:
            x_min, x_max = ax.get_xlim()
            _place_right_labels(
                ax,
                fig,
                x=x_max + 0.03 * (x_max - x_min),
                y_positions=[row[2] for row in label_rows],
                labels=[row[0] for row in label_rows],
                colors=[row[1] for row in label_rows],
                min_sep=0.08 * (y_max - y_min),
                fontsize=11,
            )
            ax.set_xlim(x_min, x_max + 0.22 * (x_max - x_min))

    if match_c_spikes_axes:
        rect_right = 1.0 - float(right_label_xlim_frac)
        if not np.isfinite(rect_right) or rect_right <= 0.2:
            rect_right = 1.0
        fig.tight_layout(rect=(0.0, 0.0, rect_right, 1.0))
    else:
        fig.tight_layout()
    if out_path is not None:
        out_path = _to_path(out_path)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        fig.savefig(out_path)
    return fig, ax


def _sort_smoothing_labels(labels: Sequence[str]) -> list[str]:
    def key(label: str) -> tuple[int, float, str]:
        text = str(label)
        if text.lower() == "raw":
            return (0, 0.0, text)
        if text.lower().endswith("hz"):
            try:
                return (1, -float(text[:-2]), text)
            except ValueError:
                pass
        return (2, 0.0, text)

    return sorted({str(x) for x in labels if str(x)}, key=key)


def plot_raincloud_by_downsample(
    *,
    csv_path: Pathish,
    out_path: Optional[Pathish] = None,
    corr_sigma_ms: float = 30.0,
    methods: Optional[Sequence[str]] = None,
    smoothings: Optional[Sequence[str]] = None,
    datasets: Optional[Sequence[str]] = None,
    runs: Optional[Sequence[str]] = None,
    reduce: str = "trial",
    title: Optional[str] = None,
    ylim: tuple[float, float] = (0.0, 1.0),
    figsize: tuple[float, float] = (7.2, 4.2),
    dpi: int = 200,
    seed: int = 0,
    ax: Any = None,
    method_label_x_offset_frac: float = -0.05,
    colors: Optional[Mapping[str, str]] = None,
    labels: Optional[Mapping[str, str]] = None,
) -> tuple[Any, Any]:
    """Plot trialwise correlation distributions grouped by downsample rate."""
    if reduce not in {"dataset", "trial"}:
        raise ValueError("reduce must be 'dataset' or 'trial'")

    ensure_matplotlib_cache_dir()
    import matplotlib.pyplot as plt

    df = read_trialwise_csv(csv_path)
    if smoothings is None:
        smoothings = _sort_smoothing_labels(df["smoothing"].dropna().astype(str).unique())
    df = _filter_trialwise(
        df,
        smoothings=smoothings,
        datasets=datasets,
        runs=runs,
        corr_sigma_ms=float(corr_sigma_ms),
    )
    if df.empty:
        raise ValueError("No rows matched the requested filters.")

    specs = _parse_series_specs(methods, df)
    colors_map = {**DEFAULT_COLORS, **dict(colors or {})}
    labels_map = {**DEFAULT_LABELS, **dict(labels or {})}

    if ax is None:
        fig, ax = plt.subplots(figsize=figsize, dpi=dpi)
    else:
        fig = ax.figure

    rng = np.random.default_rng(seed)
    x_centers = np.arange(len(smoothings), dtype=float) * 1.25
    n_series = max(1, len(specs))
    offsets = np.array([0.0]) if n_series == 1 else (np.arange(n_series) - (n_series - 1) / 2) * (0.8 / n_series)
    violin_width = min(0.7 * 0.8 / n_series, 0.35)
    box_width = 0.35 * violin_width

    label_rows: list[tuple[str, str, float]] = []
    for s_idx, smoothing in enumerate(smoothings):
        for m_idx, spec in enumerate(specs):
            sub = df[_series_mask(df, spec) & df["smoothing"].astype(str).eq(str(smoothing))].copy()
            if sub.empty:
                continue
            if reduce == "dataset":
                vals = (
                    sub.groupby(["dataset", "run", "smoothing"], as_index=False)["correlation"]
                    .mean()["correlation"]
                    .to_numpy(dtype=float)
                )
            else:
                vals = sub["correlation"].to_numpy(dtype=float)
            vals = _finite(vals)
            if vals.size == 0:
                continue
            pos = float(x_centers[s_idx] + offsets[m_idx])
            color = _series_color(spec, colors_map)
            vio = ax.violinplot([vals], positions=[pos], widths=violin_width, showextrema=False)
            for body in vio.get("bodies", []):
                body.set_facecolor(color)
                body.set_edgecolor(color)
                body.set_alpha(0.18)
            bp = ax.boxplot([vals], positions=[pos], widths=box_width, patch_artist=True, showfliers=False, whis=(5, 95))
            for patch in bp.get("boxes", []):
                patch.set_facecolor("none")
                patch.set_edgecolor("#000000")
                patch.set_linewidth(1.2)
            for key, lw in (("medians", 1.4), ("whiskers", 1.0), ("caps", 1.0)):
                for line in bp.get(key, []):
                    line.set_color("#000000")
                    line.set_linewidth(lw)
            jitter = rng.normal(0, 0.10 * violin_width, size=vals.size)
            ax.scatter(np.full(vals.shape, pos) + jitter, vals, s=10, color=color, alpha=0.30, linewidths=0)

    for spec in specs:
        vals_all = _finite(df[_series_mask(df, spec)]["correlation"].to_numpy(dtype=float))
        if vals_all.size:
            label_rows.append((_series_label(df, spec, labels_map), _series_color(spec, colors_map), float(np.median(vals_all))))

    ax.set_xticks(x_centers)
    ax.set_xticklabels([str(x) for x in smoothings])
    ax.set_xlabel("Downsample rate")
    ax.set_ylabel("Pearson correlation")
    ax.set_ylim(*ylim)
    ax.grid(True, axis="y", color="#808080", alpha=0.20, linewidth=1)
    if title:
        ax.set_title(title)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)

    if label_rows:
        x_min = float(x_centers[0] - 0.75)
        x_right = float(x_centers[-1] + 0.75)
        right_x = x_right + method_label_x_offset_frac * max(1.0, x_right - x_min)
        ax.set_xlim(x_min, x_right + 1.4)
        _place_right_labels(
            ax,
            fig,
            x=right_x,
            y_positions=np.linspace(
                ylim[1] - 0.09 * (ylim[1] - ylim[0]),
                ylim[0] + 0.58 * (ylim[1] - ylim[0]),
                len(label_rows),
            ),
            labels=[r[0] for r in label_rows],
            colors=[r[1] for r in label_rows],
            min_sep=0.08 * (ylim[1] - ylim[0]),
            fontsize=12,
            sort_by_y=False,
        )

    fig.tight_layout()
    if out_path is not None:
        out_path = _to_path(out_path)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        fig.savefig(out_path)
    return fig, ax


def load_trace_panel_data(path: Pathish) -> dict[str, Any]:
    """Load exported trace-panel arrays from .npz or .mat."""
    path = _to_path(path)
    if path.suffix.lower() == ".npz":
        with np.load(path, allow_pickle=True) as data:
            return {k: data[k].tolist() if data[k].dtype == object else data[k] for k in data.files}
    if path.suffix.lower() == ".mat":
        raw = sio.loadmat(path, squeeze_me=True, struct_as_record=False)
        return {k: v for k, v in raw.items() if not k.startswith("__")}
    raise ValueError(f"Unsupported trace panel data file: {path}")


def _as_string_list(values: Any) -> list[str]:
    arr = np.asarray(values, dtype=object).ravel()
    return [str(x.item() if hasattr(x, "item") else x) for x in arr]


def _as_scalar(values: Any, default: Any = None) -> Any:
    arr = np.asarray(values, dtype=object).ravel()
    if arr.size == 0:
        return default
    value = arr[0]
    return value.item() if hasattr(value, "item") else value


def plot_trace_panel(
    trace_data: Mapping[str, Any] | Pathish,
    *,
    ax: Any = None,
    title: Optional[str] = None,
    show_panel_labels: bool = True,
    show_method_labels: bool = True,
    show_scalebar: bool = True,
    scalebar_time_s: float = 0.6,
    scalebar_dff: float = 0.5,
    ymax: Optional[float] = None,
    figsize: tuple[float, float] = (3.4, 5.2),
    dpi: int = 250,
    fluorescence_linewidth: float = 1.1,
    ground_truth_linewidth: float = 1.2,
    method_linewidth: float = 1.3,
) -> tuple[Any, Any, dict[str, Any]]:
    """Render a trace panel from exported arrays, with no c-spikes cache dependency.

    Required fields are time, fluorescence, ground_truth, and method_traces.
    Optional fields are method_keys, method_labels, method_colors,
    method_linestyles, method_correlations, spike_times, and title.
    """
    ensure_matplotlib_cache_dir()
    import matplotlib.pyplot as plt

    if isinstance(trace_data, (str, Path, os.PathLike)):
        data = load_trace_panel_data(trace_data)
    else:
        data = dict(trace_data)

    time = np.asarray(data["time"], dtype=float).ravel()
    fluorescence = np.asarray(data.get("fluorescence_plot", data["fluorescence"]), dtype=float).ravel()
    ground_truth = np.asarray(data["ground_truth"], dtype=float).ravel()
    method_traces = np.asarray(data["method_traces"], dtype=float)
    if method_traces.ndim != 2:
        raise ValueError("method_traces must be a 2D array with shape n_methods x n_time.")
    if method_traces.shape[0] != len(np.ravel(method_traces[:, 0])):
        raise ValueError("method_traces must have methods along axis 0.")
    if method_traces.shape[1] != time.size and method_traces.shape[0] == time.size:
        method_traces = method_traces.T
    if method_traces.shape[1] != time.size:
        raise ValueError("method_traces length does not match time.")

    method_keys = _as_string_list(
        data.get("method_keys", data.get("methods", [f"method_{i+1}" for i in range(method_traces.shape[0])]))
    )
    method_labels = _as_string_list(data.get("method_labels", [DEFAULT_LABELS.get(k, k) for k in method_keys]))
    method_colors = _as_string_list(data.get("method_colors", [DEFAULT_COLORS.get(k, "#333333") for k in method_keys]))
    method_linestyles = _as_string_list(data.get("method_linestyles", ["-" for _ in method_keys]))
    method_corr = np.asarray(data.get("method_correlations", np.full(method_traces.shape[0], np.nan)), dtype=float).ravel()
    spike_times = np.asarray(data.get("spike_times", []), dtype=float).ravel()

    if ax is None:
        fig, ax = plt.subplots(figsize=figsize, dpi=dpi)
    else:
        fig = ax.figure

    ax.clear()
    t0 = float(np.nanmin(time))
    t = time - t0
    xlim = (float(np.nanmin(t)), float(np.nanmax(t)))
    row_step = 1.0
    n_method = method_traces.shape[0]
    y_fluor = (n_method + 1.4) * row_step
    y_gt = n_method * row_step
    y_methods = np.arange(n_method - 1, -1, -1, dtype=float) * row_step

    scalebar_time_s = float(_as_scalar(data.get("scale_bar_time_s", scalebar_time_s), scalebar_time_s))
    scalebar_dff = float(_as_scalar(data.get("scale_bar_dff", scalebar_dff), scalebar_dff))

    fluor = fluorescence - np.nanmedian(fluorescence[: max(3, min(20, fluorescence.size))])
    ax.plot(t, fluor + y_fluor, color="black", linewidth=float(fluorescence_linewidth))
    ax.plot(
        t,
        _normalize_0_1(ground_truth) * 0.7 + y_gt,
        color="black",
        linewidth=float(ground_truth_linewidth),
    )

    for st in spike_times[np.isfinite(spike_times)] - t0:
        if xlim[0] <= st <= xlim[1]:
            ax.axvline(st, color="#808080", alpha=0.22, linestyle=":", linewidth=0.7, zorder=0)

    for i in range(n_method):
        y = _normalize_0_1(method_traces[i]) * 0.85 + y_methods[i]
        color = method_colors[i] if i < len(method_colors) else "#333333"
        linestyle = method_linestyles[i] if i < len(method_linestyles) else "-"
        ax.plot(t, y, color=color, linewidth=float(method_linewidth), linestyle=linestyle)
        if show_method_labels:
            label = method_labels[i] if i < len(method_labels) else method_keys[i]
            ax.text(xlim[0], y_methods[i] + 0.45, label, color=color, fontweight="bold", ha="left", va="center")
        if i < method_corr.size and np.isfinite(method_corr[i]):
            ax.text(xlim[1], y_methods[i] + 0.45, f"r = {method_corr[i]:.2f}", color=color, fontweight="bold", ha="right", va="center")

    if show_panel_labels:
        ax.text(xlim[0], y_fluor + 0.35, "Fluorescence", fontweight="bold", ha="left", va="center")
        ax.text(xlim[0], y_gt + 0.35, "Ground truth", fontweight="bold", ha="left", va="center")

    if show_scalebar:
        dx = xlim[1] - xlim[0]
        x1 = xlim[1] - 0.10 * dx
        x0 = x1 - scalebar_time_s
        y1 = y_fluor + 0.80
        y0 = y1 - scalebar_dff
        ax.plot([x0, x1], [y1, y1], color="black", linewidth=1.7)
        ax.plot([x1, x1], [y0, y1], color="black", linewidth=1.7)
        ax.text((x0 + x1) / 2, y1 + 0.08, f"{scalebar_time_s:g} s", ha="center", va="bottom")
        ax.text(x1 + 0.02 * dx, (y0 + y1) / 2, f"{scalebar_dff:g} \u0394F/F", ha="left", va="center")

    ax.set_xlim(*xlim)
    upper = ymax if ymax is not None else y_fluor + 1.1
    ax.set_ylim(-0.35, upper)
    ax.axis("off")
    if title is None:
        title = str(_as_scalar(data.get("title", data.get("smoothing", "")), ""))
    if title:
        ax.set_title(title, fontweight="bold")

    meta = {"method_keys": method_keys, "method_labels": method_labels, "xlim": xlim}
    fig.tight_layout()
    return fig, ax, meta
