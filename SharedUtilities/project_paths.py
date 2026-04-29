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


DISTRIBUTION_NAME = "figure3_F_G_code"
PROJECT_ENV_VARS = ("GCAMP_FIGSHARE_ROOT", "FIGSHARE_PROJECT_DIR")
PROJECT_MARKERS = ("setup.py", "Shared_data")


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
    """Return a figure directory from the project checkout when available."""
    root = project_root(module_file)
    candidate = root / name
    if candidate.exists():
        return candidate
    if module_file is not None:
        return Path(module_file).resolve().parent
    return candidate


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
