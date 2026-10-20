"""Path helpers for figure scripts installed from this repository."""

from __future__ import annotations

import json
import os
from pathlib import Path
from urllib.parse import urlparse
from urllib.request import url2pathname

try:
    from importlib import metadata as importlib_metadata
except ImportError:  # pragma: no cover - Python < 3.8 fallback.
    import importlib_metadata  # type: ignore


DISTRIBUTION_NAME = "gcamp_reproducible_plotting"
PROJECT_ENV_VARS = ("GCAMP_FIGSHARE_ROOT", "FIGSHARE_PROJECT_DIR")
PROJECT_MARKERS = ("pyproject.toml", "figures", "shared")

FIGURE_PATHS = {
    "figure1": ("main", "figure1"),
    "figure2": ("main", "figure2"),
    "figure3": ("main", "figure3"),
    "figure4": ("main", "figure4"),
    "supp_figure1": ("supplementary", "note1"),
    "supp_figure2": ("supplementary", "figure1"),
    "supp_figure3": ("extended_data", "figure1"),
    "supp_figure4": ("extended_data", "figure2"),
    "supp_figure5": ("supplementary", "note2"),
    "supp_figure6": ("extended_data", "figure3"),
    "supp_figure8": ("extended_data", "figure4"),
    "supp_figure9": ("supplementary", "figure3"),
    "supp_figure10": ("extended_data", "figure5"),
    "supp_figure11": ("extended_data", "figure6"),
    "supp_figure12": ("supplementary", "figure4"),
    "supp_figure13": ("extended_data", "figure7"),
    "supp_figure14": ("extended_data", "figure8"),
    "supp_figure15": ("extended_data", "figure9"),
}


def project_root(start: str | os.PathLike[str] | None = None) -> Path:
    """Return the checked-out project directory used for data and outputs."""
    for env_name in PROJECT_ENV_VARS:
        env_value = os.environ.get(env_name)
        if env_value:
            candidate = Path(env_value).expanduser().resolve()
            if _looks_like_project_root(candidate):
                return candidate

    search_starts = [Path.cwd()]
    if start is not None:
        search_starts.append(Path(start))
    search_starts.append(Path(__file__))

    for search_start in search_starts:
        found = _find_project_root(search_start)
        if found is not None:
            return found

    installed_root = _project_root_from_direct_url()
    if installed_root is not None:
        return installed_root

    return Path(__file__).resolve().parents[1]


def figure_dir(name: str, module_file: str | os.PathLike[str] | None = None) -> Path:
    """Return the item input directory for a legacy or final figure name."""
    root = project_root(module_file)
    parts = FIGURE_PATHS.get(name, tuple(name.replace("\\", "/").split("/")))
    candidate = root / "figures" / Path(*parts) / "inputs"
    if candidate.exists():
        return candidate
    if module_file is not None:
        code_dir = Path(module_file).resolve().parent
        sibling_inputs = code_dir.parent / "inputs"
        if sibling_inputs.exists():
            return sibling_inputs
    return candidate


def figure_output_dir(
    name: str, module_file: str | os.PathLike[str] | None = None
) -> Path:
    """Return and create the canonical ``build/figures/<final id>`` directory."""
    parts = FIGURE_PATHS.get(name, tuple(name.replace("\\", "/").split("/")))
    output = project_root(module_file) / "build" / "figures" / Path(*parts)
    output.mkdir(parents=True, exist_ok=True)
    return output


def _find_project_root(start: Path) -> Path | None:
    candidate = start.expanduser().resolve()
    if candidate.is_file():
        candidate = candidate.parent
    for path in (candidate, *candidate.parents):
        if _looks_like_project_root(path):
            return path
    return None


def _looks_like_project_root(path: Path) -> bool:
    return all((path / marker).exists() for marker in PROJECT_MARKERS)


def _project_root_from_direct_url() -> Path | None:
    try:
        dist = importlib_metadata.distribution(DISTRIBUTION_NAME)
        direct_url_text = dist.read_text("direct_url.json")
    except Exception:
        return None
    if not direct_url_text:
        return None
    try:
        direct_url = json.loads(direct_url_text)
    except json.JSONDecodeError:
        return None
    url = direct_url.get("url", "")
    if not url.startswith("file:"):
        return None
    parsed = urlparse(url)
    candidate = Path(url2pathname(parsed.path)).expanduser().resolve()
    if candidate.is_file():
        candidate = candidate.parent
    if _looks_like_project_root(candidate):
        return candidate
    return None
