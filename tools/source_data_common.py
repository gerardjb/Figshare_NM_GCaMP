"""Shared registry helpers for source-data generation."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path, PurePosixPath

from publication_config import ITEM_BY_SOURCE_DATA, REPO_ROOT


REGISTRY_PATH = REPO_ROOT / "shared" / "source_data" / "SourceData_manifest.json"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_registry() -> list[dict[str, object]]:
    return json.loads(REGISTRY_PATH.read_text(encoding="utf-8"))


def local_csv_path(dataset: dict[str, object]) -> Path:
    csv_path = PurePosixPath(str(dataset["csv"]))
    source_item = csv_path.parts[0]
    item = ITEM_BY_SOURCE_DATA[source_item]
    return REPO_ROOT / str(item["path"]) / "source_data" / Path(*csv_path.parts[1:])
