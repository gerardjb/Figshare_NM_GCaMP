# Precise calcium-to-spike inference using biophysical generative models

This Figshare repository is in support of **"Precise calcium-to-spike inference using biophysical generative models"** from Broussard et al, 2026 *Nature Methods*. It contains the data CSVs, MATLAB plotting functions, Python plotting scripts, shared utilities, and table-generation inputs used to reproduce the manuscript figures, supplementary figures, and tables.

The layout is `figures/main`, `figures/extended_data`, `figures/supplementary`, and `tables`. Figure entry points read the matching `source_data` directories; past version raw inputs remain available to allow direct comparison to *bioRxiv*-associated release tags, but are not required by the *Nature Methods* publication build. Original PDFs as they appear in the published article are in `reference_figures/published` and are identified by SHA-256 in `reference_figures/published_manifest.json`.

## Environment and paths

The figure reproduction version of record was tested with MATLAB R2023b Update 6. MATLAB scripts use functions from the Curve Fitting, Optimization, Signal Processing, Statistics and Machine Learning, and System Identification toolboxes. The plotting runtime was Python 3.12.13. `requirements-publication.txt` provides the Python packages for plotting and source-data workbook generation in one environment.

From the repository root on Windows:

```powershell
py -3.12 -m venv .venv-publication
.\.venv-publication\Scripts\Activate.ps1
python -m pip install -r requirements-publication.txt
python -m pip install -e . --no-deps
```

On Linux:

```bash
python3.12 -m venv .venv-publication
source .venv-publication/bin/activate
python -m pip install -r requirements-publication.txt
python -m pip install -e . --no-deps
```

Conda works equivalently after activating the target environment. On offline or restricted HPC nodes, install `setuptools<82` and `wheel` first, then use `python -m pip install -e . --no-deps --no-build-isolation`. Python entry points resolve data and output paths back to this project checkout. If launching from an unusual working directory, set `GCAMP_FIGSHARE_ROOT` or `FIGSHARE_PROJECT_DIR` to the repository root.

Windows table builds use PowerShell 5.1 or newer; Linux table builds use the Python table renderer and do not require PowerShell. Both require a TeX distribution with `pdflatex`, `booktabs`, `xcolor`, `array`, and `geometry`. MATLAB must be licensed and installed with the toolboxes and operating-system dependencies listed above. The build uses MATLAB `-batch` and Matplotlib's `Agg` backend without opening figure windows.

## Reproduce figures and source data

With the Python environment activated and MATLAB on `PATH`, run from the repository root:

```bash
python tools/build.py all
```

This regenerates the figure panels, tables, and source-data workbooks. Outputs are written beneath `build/`, which is excluded from Git:

- `build/figures/` contains generated panels, including vector PDFs and editable MATLAB FIG files where applicable.
- `build/tables/` contains generated table CSV, TeX, and PDF files.
- `build/source_data/` contains the 21 source-data workbooks, rebuilt from the figure-linked CSVs using the supplied workbooks as formatting templates. Continuous curves use at most 200 time points; exact event times are preserved. Full-resolution data remain in the CSVs.
- `build/logs/` and `build/figure_build.json` show which scripts ran and where their outputs were written. A failed script or missing output stops the build with an error.

To generate only selected outputs:

```bash
python tools/build.py figures --item ED8
python tools/build.py workbooks --item Figure1
python tools/build.py all --item SupplementaryTable1
```

`--item` may be repeated. Publication IDs follow the directory list below: `Figure1`–`Figure4`, `ED1`–`ED9`, `SupplementaryFigure1`–`SupplementaryFigure4`, `SupplementaryNote1`–`SupplementaryNote2`, `Table1`, and `SupplementaryTable1`–`SupplementaryTable3`. Supplementary Figure 2 is static artwork, and Table 1 has no separate source-data workbook. To use a MATLAB installation outside `PATH`, add `--matlab /path/to/MATLAB/R2023b/bin/matlab` (quote paths containing spaces).

The supplied CSVs feed both the plots and the workbooks. The optional PPR extraction command reproduces the Figure 1h and Figure 2i CSVs from their common original MATLAB input:

```bash
python tools/build.py extract
```

It writes to `build/extracted_source_data/`. Other panels use the supplied CSVs or the analysis entry points in their figure directories. Dataset descriptions, units, missing-value conventions, and the interpolation rule are documented in `shared/source_data/README_SourceData.txt`.

For direct MATLAB use, add the checkout to the path, then run a figure script from the repository root or its figure directory:

```matlab
repoRoot = 'C:\path\to\Figshare';
addpath(genpath(repoRoot));
```

### Assemble complete figure pages

The page assembler combines regenerated panels into complete vector pages for Figure 4, Extended Data Figure 5, and Extended Data Figure 9:

```bash
python tools/assemble_revision_figures.py
```

It additionally requires `xelatex` and Poppler's `pdftoppm`. Outputs go to `build/revision_assembly/`. Other figures are generated as panel assets for placement in a page layout; `reference_figures/published/` supplies the complete reference pages and static artwork.

Arial is used in the reference artwork. MATLAB and Matplotlib may substitute another font if it is absent, which can change font metrics and layout. For the page assembler, select an installed alternative explicitly with `--font "DejaVu Sans"`, or install Arial under its applicable licence.

## Publication-facing contents

- `figures/main/figure1` through `figures/main/figure4` contain the four main-figure code, source data, and item manifests.
- `figures/extended_data/figure1` through `figures/extended_data/figure9` contain Extended Data Figures 1-9.
- `figures/supplementary/figure1` through `figures/supplementary/figure4` contain Supplementary Figures 1-4. 
- `figures/supplementary/note1` and `figures/supplementary/note2` contain the two Supplementary Notes.
- `tables/main/table1` contains Table 1; `tables/supplementary/table1` through `tables/supplementary/table3` contain Supplementary Tables 1-3. Their table entry points write CSV, TeX, and PDF artifacts beneath `build/tables`, not the source tree.
- Some figure scripts can either use the supplied CSV intermediates or rerun fitting and other longer analyses.

### Mapping *bioRxiv* to *Nature Methods* figure layout

The supplementary figures in the final *bioRxiv*-associated Figshare deposit were reordered to comply with *Nature Methods* policies:
- `supp_figure8`, `supp_figure10`, `supp_figure11`, `supp_figure13`, `supp_figure14`, and `supp_figure15` became `figures/extended_data/figure4`-`figure9`
- `supp_figure2`, `supp_figure9`, and `supp_figure12` became `figures/supplementary/figure1`, `figure3`, and `figure4`
- `supp_figure1` and `supp_figure5` were incorporated as figures in `figures/supplementary/note1` and `note2`
- `Table1`-`Table4` became `tables/main/table1` plus `tables/supplementary/table1`-`table3`. The complete mapping is encoded in `tools/publication_config.py`.

## Python entry points

After `pip install -e .`, available console scripts include:

```powershell
run_figure3_F_G_code
run_figure4_E_code
run_ED4_code
run_supp_figure12_A_B_code
run_ED7_code
run_ED8_C_D_code
run_ED9_F_G_code
```

The supplementary Python scripts accept `--output-dir`, `--format`, and `--show` where applicable. Temporary Matplotlib/cache directories created by these scripts are cleaned at the end of each run.

## Shared data and utilities

`shared/source_data` contains registered common source-data inputs. `shared/matlab` contains the publication MATLAB helpers, including `AccessFitFiles_Janelia.m`, `GCaMPalias.m`, path resolution, and output-writing utilities. `shared/python/SharedUtilities` contains the Python helpers and installed console-script entry points.
