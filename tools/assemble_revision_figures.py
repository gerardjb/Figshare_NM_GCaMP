"""Assemble Figure 4 and Extended Data Figures 5 and 9 as vector PDFs.

The MATLAB and Matplotlib panels are exported as PDFs and placed directly into
exact-size publication pages with XeLaTeX. No panel is rasterized in the final
PDF. A PNG preview is rendered from each assembled vector PDF for convenient
inspection. Outputs and intermediate panels are written below ``build/`` and
are ignored by Git. Temporary MATLAB preferences and LaTeX build files are
created outside that tree and removed automatically.
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT_DIR = REPO_ROOT / "build" / "revision_assembly"

PAGE_SIZES_INCHES: dict[str, tuple[float, float]] = {
    "figure4": (6.5, 8.26),
    "ED5": (6.5, 8.01),
    "ED9": (6.32, 8.37),
}


@dataclass(frozen=True)
class Placement:
    source: str
    box: tuple[float, float, float, float]


@dataclass(frozen=True)
class PanelLabel:
    text: str
    x: float
    y: float
    anchor: str = "north west"


# Boxes use fractions of each final portrait figure:
# (left, top, right, bottom).
LAYOUTS: dict[str, tuple[Placement, ...]] = {
    "figure4": (
        Placement("figure4_A", (0.030, 0.005, 0.950, 0.195)),
        Placement("figure4_B_C", (0.030, 0.215, 0.965, 0.635)),
        Placement("figure4_D", (0.030, 0.675, 0.390, 0.990)),
        Placement("figure4_E_F_G", (0.410, 0.675, 0.990, 0.990)),
    ),
    "ED5": (
        Placement("ED5_A_B", (0.030, 0.035, 0.985, 0.470)),
        Placement("ED5_C_to_F", (0.030, 0.500, 0.985, 0.990)),
    ),
    "ED9": (
        Placement("ED9_A_B_C", (0.020, 0.025, 0.985, 0.365)),
        Placement("ED9_D_E", (0.020, 0.385, 0.985, 0.615)),
        Placement("ED9_F", (0.020, 0.655, 0.490, 0.995)),
        Placement("ED9_G", (0.500, 0.665, 0.985, 0.845)),
    ),
}


PANEL_LABELS: dict[str, tuple[PanelLabel, ...]] = {
    "figure4": (
        PanelLabel("A", 0.020, 0.000),
        PanelLabel("B", 0.020, 0.195),
        PanelLabel("C", 0.500, 0.195),
        PanelLabel("D", 0.020, 0.645),
        # The three letters follow the internal columns of the combined E-G
        # panel: just after the method labels, then precision, then recall.
        PanelLabel("E", 0.505, 0.645),
        PanelLabel("F", 0.674, 0.645),
        PanelLabel("G", 0.838, 0.645),
    ),
    "ED5": (
        PanelLabel("A", 0.015, 0.010),
        PanelLabel("B", 0.505, 0.010),
        PanelLabel("C", 0.015, 0.490),
        # D-F form a left-hand column with C. Their bottom edges align with
        # the y=1 tick/top of the precision, recall, and F1 axes.
        PanelLabel("D", 0.015, 0.6879, "south west"),
        PanelLabel("E", 0.015, 0.7898, "south west"),
        PanelLabel("F", 0.015, 0.8918, "south west"),
    ),
    "ED9": (
        PanelLabel("A", 0.010, 0.005),
        PanelLabel("B", 0.335, 0.005),
        PanelLabel("C", 0.665, 0.005),
        PanelLabel("D", 0.010, 0.370),
        PanelLabel("E", 0.500, 0.370),
        PanelLabel("F", 0.010, 0.635),
        PanelLabel("G", 0.490, 0.635),
    ),
}


def run_checked(command: list[str], *, cwd: Path, env: dict[str, str] | None = None) -> None:
    print("+", subprocess.list2cmdline(command), flush=True)
    subprocess.run(command, cwd=cwd, env=env, check=True)


def matlab_string(path: Path) -> str:
    return path.resolve().as_posix().replace("'", "''")


def render_matlab_panels(panel_dir: Path, matlab_command: str) -> None:
    panel_dir.mkdir(parents=True, exist_ok=True)
    matlab_env = os.environ.copy()
    stats_path = (
        REPO_ROOT / "figures" / "main" / "figure4" / "inputs"
        / "figure4_D_lme_stats.mat"
    )
    stats_backup = panel_dir / "_figure4_D_lme_stats_backup.mat"
    if stats_path.exists():
        shutil.copy2(stats_path, stats_backup)

    exports = [
        (
            "figure4B_C_code",
            panel_dir / "figure4_B_C.pdf",
            "figure4B_C_code",
            "",
        ),
        (
            "figure4_D_code",
            panel_dir / "figure4_D.pdf",
            "figure4_D_code",
            (
                "set(gcf,'Units','inches','Position',[1,1,4.8,4],"
                "'PaperUnits','inches','PaperSize',[4.8,4],"
                "'PaperPosition',[0,0,4.8,4]);"
                "tlo=findall(gcf,'Type','tiledlayout');"
                "tlo.OuterPosition=[0,0,0.78,1]"
            ),
        ),
        (
            "ED5_A_B_csv_code",
            panel_dir / "ED5_A_B.pdf",
            "ED5_A_B_csv_code",
            "",
        ),
        (
            "ED5_C_to_F_code",
            panel_dir / "ED5_C_to_F.pdf",
            "ED5_C_to_F_code",
            "",
        ),
        (
            "ED9_A_B_C_csv_code",
            panel_dir / "ED9_A_B_C.pdf",
            "h=ED9_A_B_C_csv_code",
            "",
        ),
        (
            "ED9_D_E_code",
            panel_dir / "ED9_D_E.pdf",
            "ED9_D_E_code",
            "",
        ),
    ]

    statements = [
        f"cd('{matlab_string(REPO_ROOT)}')",
        "addpath(pwd,'-begin')",
        "addpath(genpath(fullfile(pwd,'shared','matlab')),'-begin')",
        "addpath(fullfile(pwd,'figures','main','figure4','code'),'-begin')",
        "addpath(fullfile(pwd,'figures','extended_data','figure5','code'),'-begin')",
        "addpath(fullfile(pwd,'figures','extended_data','figure9','code'),'-begin')",
        "set(groot,'defaultFigureVisible','off')",
    ]
    for _, output_path, call, pre_export in exports:
        statements.extend(
            [
                call,
                pre_export,
                "drawnow",
                (
                    f"exportgraphics(gcf,'{matlab_string(output_path)}',"
                    "'ContentType','vector','BackgroundColor','white')"
                ),
                "close all force",
            ]
        )
    statements.append("disp('Finished MATLAB panel exports.')")

    try:
        with tempfile.TemporaryDirectory(prefix="figshare_matlab_pref_") as pref_dir:
            matlab_env["MATLAB_PREFDIR"] = pref_dir
            run_checked(
                [matlab_command, "-batch", ";".join(statements)],
                cwd=REPO_ROOT,
                env=matlab_env,
            )
    finally:
        # figure4_D_code refreshes this tracked statistics file. Rendering a
        # layout should not create an unrelated binary diff.
        if stats_backup.exists():
            shutil.copy2(stats_backup, stats_path)
            stats_backup.unlink()


def render_python_panels(panel_dir: Path, python_executable: str) -> None:
    panel_dir.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env["MPLBACKEND"] = "Agg"
    env["PYTHONPATH"] = os.pathsep.join(
        [str(REPO_ROOT / "shared" / "python"), env.get("PYTHONPATH", "")]
    ).rstrip(os.pathsep)

    figure4_output = panel_dir / "figure4_E_F_G.pdf"
    figure4_wrapper = (
        "import runpy;"
        "import matplotlib.pyplot as plt;"
        f"runpy.run_path({str(REPO_ROOT / 'figures' / 'main' / 'figure4' / 'code' / 'figure4_E_code.py')!r},"
        "run_name='__main__');"
        f"plt.gcf().savefig({str(figure4_output)!r},format='pdf',"
        "bbox_inches='tight',facecolor='white')"
    )
    run_checked(
        [python_executable, "-c", figure4_wrapper],
        cwd=REPO_ROOT,
        env=env,
    )

    run_checked(
        [
            python_executable,
            str(REPO_ROOT / "figures" / "extended_data" / "figure9" / "code" / "ED9_F_G_code.py"),
            "--output-dir",
            str(panel_dir),
            "--format",
            "pdf",
        ],
        cwd=REPO_ROOT,
        env=env,
    )

    generated_names = {
        "ED9_F_trace_jG8m_compare.pdf": "ED9_F.pdf",
        "ED9_G_corr_vs_sigma_jG8m.pdf": "ED9_G.pdf",
    }
    for generated_name, assembly_name in generated_names.items():
        generated_path = panel_dir / generated_name
        assembly_path = panel_dir / assembly_name
        if not generated_path.exists():
            raise FileNotFoundError(f"Expected Python panel was not created: {generated_path}")
        generated_path.replace(assembly_path)


def build_panel_sources(panel_dir: Path) -> dict[str, Path]:
    return {
        "figure4_A": REPO_ROOT / "figures" / "main" / "figure4" / "inputs" / "Fig4_schematic.pdf",
        "figure4_B_C": panel_dir / "figure4_B_C.pdf",
        "figure4_D": panel_dir / "figure4_D.pdf",
        "figure4_E_F_G": panel_dir / "figure4_E_F_G.pdf",
        "ED5_A_B": panel_dir / "ED5_A_B.pdf",
        "ED5_C_to_F": panel_dir / "ED5_C_to_F.pdf",
        "ED9_A_B_C": panel_dir / "ED9_A_B_C.pdf",
        "ED9_D_E": panel_dir / "ED9_D_E.pdf",
        "ED9_F": panel_dir / "ED9_F.pdf",
        "ED9_G": panel_dir / "ED9_G.pdf",
    }


def latex_path(path: Path) -> str:
    return rf"\detokenize{{{path.resolve().as_posix()}}}"


def placement_tex(
    placement: Placement,
    source_path: Path,
    page_width: float,
    page_height: float,
) -> str:
    left, top, right, bottom = placement.box
    width = (right - left) * page_width
    height = (bottom - top) * page_height
    center_x = (left + right) * page_width / 2
    center_y = (top + bottom) * page_height / 2
    coordinate = (
        rf"([xshift={center_x:.6f}in,yshift=-{center_y:.6f}in]"
        "current page.north west)"
    )
    if not source_path.exists():
        raise FileNotFoundError(f"Missing panel source: {source_path}")
    return (
        rf"\node[anchor=center,inner sep=0pt] at {coordinate} "
        rf"{{\includegraphics[width={width:.6f}in,height={height:.6f}in,"
        rf"keepaspectratio]{{{latex_path(source_path)}}}}};"
    )


def page_tex(page_name: str, sources: dict[str, Path], font: str = "Arial") -> str:
    if not font or any(character in font for character in "{}\\\n\r"):
        raise ValueError("Font must be a font-family name without TeX commands.")
    page_width, page_height = PAGE_SIZES_INCHES[page_name]
    body: list[str] = []
    for placement in LAYOUTS[page_name]:
        source = sources[placement.source]
        body.append(placement_tex(placement, source, page_width, page_height))
    for label in PANEL_LABELS[page_name]:
        x = label.x * page_width
        y = label.y * page_height
        body.append(
            (
                rf"\node[anchor={label.anchor},inner sep=0pt,font="
                rf"\sffamily\fontsize{{16pt}}{{16pt}}\selectfont] at "
                rf"([xshift={x:.6f}in,yshift=-{y:.6f}in]current page.north west) "
                rf"{{{label.text}}};"
            )
        )
    body_text = "\n".join(body)
    return rf"""\documentclass{{article}}
\usepackage[paperwidth={page_width:.6f}in,paperheight={page_height:.6f}in,margin=0in]{{geometry}}
\usepackage{{graphicx}}
\usepackage{{tikz}}
\usepackage{{fontspec}}
\setsansfont{{{font}}}
\pagestyle{{empty}}
\setlength{{\parindent}}{{0pt}}
\begin{{document}}
\mbox{{}}
\begin{{tikzpicture}}[remember picture,overlay]
{body_text}
\end{{tikzpicture}}
\end{{document}}
"""


def assemble_pages(
    output_dir: Path,
    sources: dict[str, Path],
    *,
    dpi: int,
    xelatex_command: str,
    pdftoppm_command: str,
    font: str = "Arial",
) -> None:
    page_names = ("figure4", "ED5", "ED9")
    for page_name in page_names:
        pdf_path = output_dir / f"{page_name}_assembled.pdf"
        with tempfile.TemporaryDirectory(prefix=f"figshare_{page_name}_latex_") as build:
            build_dir = Path(build)
            tex_path = build_dir / f"{page_name}_assembled.tex"
            built_pdf = build_dir / f"{page_name}_assembled.pdf"
            tex_path.write_text(page_tex(page_name, sources, font=font), encoding="utf-8")
            latex_command = [
                xelatex_command,
                "-interaction=nonstopmode",
                "-halt-on-error",
                f"-output-directory={build_dir}",
                str(tex_path),
            ]
            # TikZ's current-page anchors are resolved from the first pass.
            run_checked(latex_command, cwd=REPO_ROOT)
            run_checked(latex_command, cwd=REPO_ROOT)
            if not built_pdf.exists():
                raise FileNotFoundError(f"XeLaTeX did not create {built_pdf}")
            shutil.copy2(built_pdf, pdf_path)

        png_stem = output_dir / f"{page_name}_assembled"
        run_checked(
            [
                pdftoppm_command,
                "-png",
                "-singlefile",
                "-r",
                str(dpi),
                str(pdf_path),
                str(png_stem),
            ],
            cwd=REPO_ROOT,
        )
        print(f"Wrote {pdf_path}")
        print(f"Wrote {png_stem.with_suffix('.png')}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Regenerate and assemble Figure 4, Supplementary Figure 10, and "
            "Supplementary Figure 15 at their submitted dimensions."
        )
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help="Ignored output directory for intermediate panels and assembled figures.",
    )
    parser.add_argument("--dpi", type=int, default=300, help="Assembly resolution.")
    parser.add_argument(
        "--skip-panel-render",
        action="store_true",
        help="Reuse panel PDFs already present in OUTPUT_DIR/panels.",
    )
    parser.add_argument(
        "--skip-matlab-render",
        action="store_true",
        help="Reuse MATLAB panel PDFs but refresh the Python panels.",
    )
    parser.add_argument(
        "--skip-python-render",
        action="store_true",
        help="Reuse Python panel PDFs but refresh the MATLAB panels.",
    )
    parser.add_argument("--matlab", default="matlab", help="MATLAB executable.")
    parser.add_argument(
        "--python",
        default=sys.executable,
        help="Python executable containing the plotting dependencies.",
    )
    parser.add_argument("--xelatex", default="xelatex", help="XeLaTeX executable.")
    parser.add_argument("--pdftoppm", default="pdftoppm", help="pdftoppm executable.")
    parser.add_argument("--font", default="Arial", help="Installed XeLaTeX font family; use DejaVu Sans on Linux when Arial is unavailable.")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    output_dir = args.output_dir.expanduser().resolve()
    panel_dir = output_dir / "panels"

    if args.dpi <= 0:
        raise ValueError("--dpi must be positive.")

    output_dir.mkdir(parents=True, exist_ok=True)
    if not args.skip_panel_render and not args.skip_matlab_render:
        render_matlab_panels(panel_dir, args.matlab)
    if not args.skip_panel_render and not args.skip_python_render:
        render_python_panels(panel_dir, args.python)

    sources = build_panel_sources(panel_dir)
    assemble_pages(
        output_dir,
        sources,
        dpi=args.dpi,
        xelatex_command=args.xelatex,
        pdftoppm_command=args.pdftoppm,
        font=args.font,
    )


if __name__ == "__main__":
    main()
