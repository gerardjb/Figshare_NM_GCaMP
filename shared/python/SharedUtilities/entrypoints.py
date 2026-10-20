"""Console entry points that execute plotting scripts from the checkout."""

from __future__ import annotations

import runpy
from pathlib import Path

from .project_paths import project_root


SCRIPT_PATHS = {
    "figure3_f_g": "figures/main/figure3/code/figure3_F_G_code.py",
    "figure4_e": "figures/main/figure4/code/figure4_E_code.py",
    "ED4": "figures/extended_data/figure4/code/ED4_code.py",
    "supp_figure12": "figures/supplementary/figure4/code/suppfigure12_A_B_code.py",
    "ED7": "figures/extended_data/figure7/code/ED7_code.py",
    "ED8": "figures/extended_data/figure8/code/ED8_C_D_code.py",
    "ED9": "figures/extended_data/figure9/code/ED9_F_G_code.py",
}


def _run(name: str) -> None:
    script = project_root(__file__) / Path(SCRIPT_PATHS[name])
    runpy.run_path(str(script), run_name="__main__")


def run_figure3_f_g() -> None:
    _run("figure3_f_g")


def run_figure4_e() -> None:
    _run("figure4_e")


def run_ED4() -> None:
    _run("ED4")


def run_supp_figure12() -> None:
    _run("supp_figure12")


def run_ED7() -> None:
    _run("ED7")


def run_ED8() -> None:
    _run("ED8")


def run_ED9() -> None:
    _run("ED9")
