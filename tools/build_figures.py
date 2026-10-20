"""Generate figure panels and tables from the configured plotting scripts."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any

from publication_config import ITEMS, REPO_ROOT


def matlab_quote(path: Path) -> str:
    return str(path).replace("'", "''")


def output_dir(item: dict[str, Any]) -> Path:
    relative = Path(str(item["path"]))
    category = "figures" if relative.parts[0] == "figures" else "tables"
    return REPO_ROOT / "build" / category / Path(*relative.parts[1:])


def command_for(
    entry: dict[str, Any], script: Path,
    python_executable: str, matlab_executable: str,
) -> list[str]:
    if entry["language"] == "python":
        return [python_executable, str(script)]
    if entry["language"] == "matlab":
        matlab_code = ";".join([
            f"cd('{matlab_quote(REPO_ROOT)}')",
            "addpath(genpath(fullfile(pwd,'shared','matlab')),'-begin')",
            f"addpath('{matlab_quote(script.parent)}','-begin')",
            "set(groot,'defaultFigureVisible','off')",
            str(entry["call"]),
            "close all force",
        ])
        return [matlab_executable, "-batch", matlab_code]
    raise ValueError(f"Unsupported language: {entry['language']}")


def file_stamp(path: Path) -> tuple[int, int, int] | None:
    """Distinguish newly written outputs from files left by an earlier build."""
    if not path.is_file():
        return None
    stat = path.stat()
    return stat.st_mtime_ns, stat.st_ctime_ns, stat.st_size


def run_entrypoint(
    item: dict[str, Any], entry: dict[str, Any], *,
    python_executable: str, matlab_executable: str,
) -> dict[str, Any]:
    script = REPO_ROOT / str(item["path"]) / str(entry["script"])
    expected = [
        output_dir(item) / f"{stem}.{extension}"
        for stem in entry["stems"] for extension in entry["required_formats"]
    ]
    before = {path: file_stamp(path) for path in expected}
    relative_script = script.relative_to(REPO_ROOT).as_posix()
    log_path = REPO_ROOT / "build" / "logs" / f"{item['publication_id']}_{script.stem}.log"
    log_path.parent.mkdir(parents=True, exist_ok=True)
    output_dir(item).mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env["MPLBACKEND"] = "Agg"
    env["PYTHONUTF8"] = "1"
    env["PYTHONPATH"] = os.pathsep.join(
        [str(REPO_ROOT / "shared" / "python"), env.get("PYTHONPATH", "")]
    ).rstrip(os.pathsep)
    if entry["language"] == "python":
        cache = REPO_ROOT / "build" / "matplotlib" / script.stem
        cache.mkdir(parents=True, exist_ok=True)
        env["MPLCONFIGDIR"] = str(cache)
    if entry["language"] == "matlab":
        preferences = REPO_ROOT / "build" / "matlab_pref" / script.stem
        preferences.mkdir(parents=True, exist_ok=True)
        env["MATLAB_PREFDIR"] = str(preferences)

    print(f"Generating {item['publication_id']}: {script.name}", flush=True)
    error = None
    returncode = None
    try:
        if not script.is_file():
            raise FileNotFoundError(f"Plotting script is missing: {script}")
        completed = subprocess.run(
            command_for(entry, script, python_executable, matlab_executable),
            cwd=REPO_ROOT, env=env, text=True, encoding="utf-8", errors="replace",
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False,
        )
        returncode = completed.returncode
        output = completed.stdout or ""
        if returncode != 0:
            error = f"Process exited with code {returncode}."
    except (OSError, ValueError) as exc:
        error = str(exc)
        output = f"Could not run plotting script: {exc}\n"
    log_path.write_text(output, encoding="utf-8")

    missing = []
    unchanged = []
    for path in expected:
        after = file_stamp(path)
        if after is None or after[2] == 0:
            missing.append(path.relative_to(REPO_ROOT).as_posix())
        elif after == before[path]:
            unchanged.append(path.relative_to(REPO_ROOT).as_posix())
    if not expected:
        error = error or "No output filenames are configured for this script."
    if missing:
        error = error or "Expected output files are missing or empty."
    if unchanged:
        error = error or "Expected output files were not regenerated."
    result = {
        "script": relative_script,
        "status": "failed" if error else "generated",
        "outputs": [p.relative_to(REPO_ROOT).as_posix() for p in expected],
        "log": log_path.relative_to(REPO_ROOT).as_posix(),
    }
    if error:
        result.update(error=error, returncode=returncode)
        if missing:
            result["missing_outputs"] = missing
        if unchanged:
            result["unchanged_outputs"] = unchanged
        print(f"  Failed: {error} See {result['log']}", file=sys.stderr, flush=True)
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--item", action="append", help="Publication ID; may be repeated.")
    parser.add_argument(
        "--csv-only", action="store_true",
        help="Run only plotting scripts that use the packaged CSV data.",
    )
    parser.add_argument("--python", default=sys.executable)
    parser.add_argument("--matlab", default="matlab")
    parser.add_argument("--report", type=Path, default=REPO_ROOT / "build" / "figure_build.json")
    args = parser.parse_args()
    selected = set(args.item or [])
    unknown = sorted(selected - {str(item["publication_id"]) for item in ITEMS})
    if unknown:
        parser.error(f"Unknown publication IDs: {', '.join(unknown)}")

    reports = []
    failed = False
    for item in ITEMS:
        if selected and item["publication_id"] not in selected:
            continue
        entries = []
        for entry in item["entrypoints"]:
            if args.csv_only and entry["mode"] != "packaged_csv":
                entries.append({"script": entry["script"], "status": "skipped", "reason": "requires original inputs"})
            else:
                entries.append(run_entrypoint(
                    item, entry, python_executable=args.python, matlab_executable=args.matlab,
                ))
        statuses = [entry["status"] for entry in entries]
        if "failed" in statuses:
            status = "failed"
            failed = True
        elif "skipped" in statuses:
            status = "partial" if "generated" in statuses else "skipped"
        else:
            status = "generated" if entries else "artwork_only"
        reports.append({"publication_id": item["publication_id"], "status": status, "entrypoints": entries})

    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps({"items": reports}, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({row["publication_id"]: row["status"] for row in reports}, indent=2))
    if failed:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
