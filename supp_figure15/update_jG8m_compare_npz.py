"""Add or refresh the PGBAR trace in the packaged panel-F NPZ export.

The file ``jG8m_compare_out.npz`` is a compact export of arrays prepared
by the C-SPIKES trialwise trace-panel workflow. This updater preserves those
arrays, derives the PGBAR display trace from its consolidated inference-cache
MAT file, and reads the displayed full-trial correlation from the packaged
trialwise CSV to allow plotting without the full C-SPIKES toolset.
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path

import numpy as np
from scipy import io as sio
from scipy.ndimage import gaussian_filter1d


HERE = Path(__file__).resolve().parent
DEFAULT_NPZ = HERE / "jG8m_compare_out.npz"
DEFAULT_CSV = HERE / "trialwise_correlations_jG8m.csv"

PGBAR_METHOD_KEY = "pgbar@pgbar_janelia_8m"
PGBAR_METHOD = "pgbar"
PGBAR_RUN = "pgbar_janelia_8m"
PGBAR_LABEL = "PGBAR"
PGBAR_COLOR = "#4A4A4A"


def _scalar(value: np.ndarray) -> object:
    return np.asarray(value).reshape(-1)[0].item()


def _segments(times: np.ndarray, sampling_rate: float) -> list[slice]:
    times = np.asarray(times, dtype=float).ravel()
    breaks = np.flatnonzero(
        (np.diff(times) > 4.0 / sampling_rate) | ~np.isfinite(np.diff(times))
    ) + 1
    edges = np.concatenate(([0], breaks, [times.size]))
    return [slice(int(start), int(end)) for start, end in zip(edges[:-1], edges[1:]) if end > start]


def _normalize_0_1(values: np.ndarray) -> np.ndarray:
    values = np.asarray(values, dtype=float).ravel()
    finite = values[np.isfinite(values)]
    if finite.size == 0:
        return np.zeros_like(values)
    low = float(np.min(finite))
    high = float(np.max(finite))
    if high <= low:
        return np.zeros_like(values)
    output = (values - low) / (high - low)
    output[~np.isfinite(output)] = np.nan
    return output


def _pgbar_correlation(
    csv_path: Path,
    *,
    dataset: str,
    smoothing: str,
    corr_sigma_ms: float,
    trial: int,
) -> float:
    with csv_path.open(newline="", encoding="utf-8-sig") as handle:
        matches = [
            row
            for row in csv.DictReader(handle)
            if row["dataset"] == dataset
            and row["smoothing"] == smoothing
            and row["method"] == PGBAR_METHOD
            and row["run"] == PGBAR_RUN
            and int(row["trial"]) == trial
            and np.isclose(float(row["corr_sigma_ms"]), corr_sigma_ms)
        ]
    if len(matches) != 1:
        raise ValueError(
            f"Expected one PGBAR correlation row for {dataset}, trial {trial}, "
            f"sigma {corr_sigma_ms:g} ms; found {len(matches)}."
        )
    return float(matches[0]["correlation"])


def update_npz(npz_path: Path, csv_path: Path, pgbar_mat_path: Path) -> None:
    with np.load(npz_path, allow_pickle=True) as source:
        data = {key: source[key] for key in source.files}

    reference_time = np.asarray(data["time"], dtype=float).ravel()
    dataset = str(_scalar(data["dataset"]))
    smoothing = str(_scalar(data["smoothing"]))
    trial = int(_scalar(data["trial"]))
    display_sigma_ms = float(_scalar(data["display_sigma_ms"]))
    corr_sigma_ms = float(_scalar(data["corr_sigma_ms"]))

    pgbar_data = sio.loadmat(pgbar_mat_path)
    pgbar_time = np.asarray(pgbar_data["time_stamps"], dtype=float).ravel()
    pgbar_probability = np.asarray(pgbar_data["spike_prob"], dtype=float).ravel()
    if pgbar_time.shape != pgbar_probability.shape:
        raise ValueError("PGBAR time_stamps and spike_prob have different lengths.")

    finite_diffs = np.diff(pgbar_time)
    finite_diffs = finite_diffs[np.isfinite(finite_diffs) & (finite_diffs > 0)]
    sampling_rate = 1.0 / float(np.median(finite_diffs))
    trial_segments = _segments(pgbar_time, sampling_rate)
    if trial < 0 or trial >= len(trial_segments):
        raise ValueError(f"Trial {trial} is unavailable in the PGBAR cache.")

    trial_slice = trial_segments[trial]
    trial_time = pgbar_time[trial_slice]
    trial_probability = pgbar_probability[trial_slice]
    if reference_time[0] < trial_time[0] or reference_time[-1] > trial_time[-1]:
        raise ValueError("The packaged trace window is outside the selected PGBAR trial.")

    sigma_samples = display_sigma_ms / 1000.0 * sampling_rate
    smoothed_probability = gaussian_filter1d(trial_probability, sigma=sigma_samples)
    pgbar_trace = np.interp(reference_time, trial_time, smoothed_probability)
    pgbar_trace = _normalize_0_1(pgbar_trace)
    pgbar_corr = _pgbar_correlation(
        csv_path,
        dataset=dataset,
        smoothing=smoothing,
        corr_sigma_ms=corr_sigma_ms,
        trial=trial,
    )

    methods = np.asarray(data["methods"], dtype=str).tolist()
    labels = np.asarray(data["method_labels"], dtype=str).tolist()
    colors = np.asarray(data["method_colors"], dtype=str).tolist()
    runs = np.asarray(data["method_runs"], dtype=str).tolist()
    correlations = np.asarray(data["method_correlations"], dtype=float).tolist()
    traces = [row.copy() for row in np.asarray(data["method_traces"], dtype=float)]

    if PGBAR_METHOD_KEY in methods:
        pgbar_index = methods.index(PGBAR_METHOD_KEY)
        for collection in (methods, labels, colors, runs, correlations, traces):
            collection.pop(pgbar_index)

    methods.append(PGBAR_METHOD_KEY)
    labels.append(PGBAR_LABEL)
    colors.append(PGBAR_COLOR)
    runs.append(PGBAR_RUN)
    correlations.append(pgbar_corr)
    traces.append(pgbar_trace)

    # The original export ordered rows by decreasing full-trial correlation.
    order = np.argsort(-np.asarray(correlations, dtype=float), kind="stable")
    data["methods"] = np.asarray([methods[index] for index in order])
    data["method_labels"] = np.asarray([labels[index] for index in order])
    data["method_colors"] = np.asarray([colors[index] for index in order])
    data["method_runs"] = np.asarray([runs[index] for index in order])
    data["method_correlations"] = np.asarray([correlations[index] for index in order], dtype=float)
    data["method_traces"] = np.stack([traces[index] for index in order])

    np.savez_compressed(npz_path, **data)
    print(
        f"Updated {npz_path} with PGBAR: r={pgbar_corr:.6f}, "
        f"{reference_time.size} samples at {sampling_rate:.6f} Hz."
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--npz", type=Path, default=DEFAULT_NPZ)
    parser.add_argument("--csv", type=Path, default=DEFAULT_CSV)
    parser.add_argument("--pgbar-mat", type=Path, required=True)
    return parser


def main() -> None:
    args = build_parser().parse_args()
    update_npz(args.npz.resolve(), args.csv.resolve(), args.pgbar_mat.resolve())


if __name__ == "__main__":
    main()
