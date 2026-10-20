""" 
    Plots for the distribution of STA and SNA bias and uncertainty for the Janelia8f dataset as detected using
    the methods studied here and shown in supplementary figure 12.
"""

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib
import seaborn as sns
import ptitprince as pt
import os
import argparse
import sys
from pathlib import Path

try:
    from SharedUtilities.project_paths import figure_dir, figure_output_dir
except ImportError:
    sys.path.insert(0, str(Path(__file__).resolve().parents[4] / "shared" / "python"))
    from SharedUtilities.project_paths import figure_dir, figure_output_dir  # type: ignore

# Suppress FutureWarnings related to the 'observed' parameter in Seaborn - groan
import warnings
warnings.filterwarnings(
    "ignore",
    category=FutureWarning,
    message=".*observed.*"
)

# -----
# Functions used in plotting
# -----
# Function to Create Raincloud Plot
def create_raincloud(ax, data, x, y, orient='h', palette='Set2',bw=0.1,color_mapping=None,stripplot_shift=0.15):
    """
    Creates a raincloud plot using ptitprince.
    
    Parameters:
    - ax: Matplotlib Axes object.
    - data: DataFrame containing the data.
    - x: Column name for the numerical variable.
    - y: Column name for the categorical variable.
    - orient: Orientation of the plot ('h' for horizontal, 'v' for vertical).
    - palette: Color palette for the plot.
    - bw: bandwidth of the KDE for the half_violoin plot
    - color_mapping: Dictionary mapping categories to hex colors for boxplot and stripplot.
    - stripplot_shift: Float value to shift the stripplot along the x-axis.
    """
    palette = _ordered_palette(data, y, palette)

    # Create the half-violin (density) plot
    pt.half_violinplot(x=x, y=y, data=data, palette=palette, bw=bw, ax=ax,width=0.95,
                       linewidth=0.1, orient=orient,gridsize=5000,
                       offset=0.1-stripplot_shift,scale="width") #high gridsize because STA plots too coarse without this
    
    # Seaborn 0.13+ requires an explicit hue when a palette is supplied.
    # Keep the legacy call compatible with the Seaborn 0.11 environment branch.
    boxplot_kwargs = {'palette': palette}
    seaborn_version = tuple(int(part) for part in sns.__version__.split('.')[:2])
    if seaborn_version >= (0, 13):
        boxplot_kwargs.update(hue=y, legend=False)

    # Add and color-code the boxplot
    box = sns.boxplot(
        x=x, y=y, data=data, width=0.12, ax=ax, orient=orient, showcaps=False,
        boxprops={'linewidth':1},
        medianprops={'color': 'white', 'linewidth': 1.5},
        showfliers=False, whiskerprops={'linewidth':1}, dodge=False,
        **boxplot_kwargs,
    )
    if color_mapping:
        for patch, method_label in zip(box.artists, box.get_yticklabels()):
            method = method_label.get_text()
            color = color_mapping.get(method, '#000000')  # Default to black if not found
            print('color is: '+ str(color))
            patch.set_edgecolor(color)

    # Shift the boxplot along axis specified by orient
    boxplot_shift = stripplot_shift if orient == 'h' else 0
    for patch in box.patches:
        # Adjust patches
        path = patch.get_path()
        vertices = path.vertices
        vertices[:, 1] += boxplot_shift  # Shift y-coordinates
        path.vertices = vertices
    for line in box.lines:
        # Adjust lines
        line_data = line.get_ydata()
        #line_data += boxplot_shift  # Shift y-coordinates
        line.set_ydata(line_data + boxplot_shift)
    for coll in box.collections:
        # Adjust collections
        offsets = coll.get_offsets()
        offsets[:, 1] += boxplot_shift
        coll.set_offsets(offsets)


def _ordered_palette(data, category_col, palette):
    if not isinstance(palette, dict):
        return palette
    categories = data[category_col]
    if hasattr(categories, "cat"):
        # Retain every declared category so palette length stays aligned with
        # the categorical axis even when a panel has no observations for one.
        order = list(categories.cat.categories)
    else:
        order = list(pd.unique(categories.dropna()))
    missing_colors = [category for category in order if category not in palette]
    if missing_colors:
        raise ValueError(f"Missing colors for categories: {missing_colors}")
    return [palette[category] for category in order]

"""
    Plotting the distribution of bias (STA) and uncertainty (SNA) for the Janelia8f dataset as detected using 
    the methods studied here and shown in figure 4E.
"""

METHOD_ALIASES = {
    'CASCADE': r'$\mathbf{CASCADE}$',
    'Biophys_{ML}': r'$\mathbf{Biophys}_{\mathbf{ML}}$',
    'Biophys_{SMC}': r'$\mathbf{Biophys}_{\mathbf{SMC}}$',
    'ENS^2': r'$\mathbf{ENS}^{\mathbf{2}}$',
    'MLspike': r'$\mathbf{MLspike}$',
    'PGBAR': r'$\mathbf{PGBAR}$',
}

METHOD_COLORS = {
    r'$\mathbf{CASCADE}$': '#F3AE14',
    r'$\mathbf{Biophys}_{\mathbf{SMC}}$': '#009E73',
    r'$\mathbf{Biophys}_{\mathbf{ML}}$': '#007755',
    r'$\mathbf{ENS}^{\mathbf{2}}$': '#A6780C',
    r'$\mathbf{MLspike}$': '#0072B2',
    r'$\mathbf{PGBAR}$': '#4A4A4A',
}

METHOD_ORDER = [
    r'$\mathbf{Biophys}_{\mathbf{SMC}}$',
    r'$\mathbf{PGBAR}$',
    r'$\mathbf{MLspike}$',
    r'$\mathbf{Biophys}_{\mathbf{ML}}$',
    r'$\mathbf{CASCADE}$',
    r'$\mathbf{ENS}^{\mathbf{2}}$',
]

SELECTED_METHODS = list(METHOD_ALIASES)


def _configure_plot_style():
    sns.set(style="whitegrid")
    plt.rcParams['font.family'] = 'Arial'
    plt.rcParams['font.sans-serif'] = ['Arial']
    # Trying to harmonize output embedding to Affinity profile
    plt.rcParams['pdf.fonttype'] = 42
    plt.rcParams['ps.fonttype'] = 42
    # Optional: Disable LaTeX rendering if not essential
    plt.rcParams['text.usetex'] = False
    # Configure mathtext to use Arial
    plt.rcParams['mathtext.fontset'] = 'custom'
    plt.rcParams['mathtext.rm'] = 'Arial'
    plt.rcParams['mathtext.it'] = 'Arial:italic'
    plt.rcParams['mathtext.bf'] = 'Arial:bold'


def _load_distribution(script_dir, mode):
    if mode == 'matched':
        filename = '01_SF4_existing_matched_bias_uncer.csv'
        x_limits = ((-50, 50), (-0.5, 30))
        bandwidths = (0.05, 0.1)
    elif mode == 'unmatched':
        filename = '02_SF4_existing_unmatched_bias_unc.csv'
        x_limits = ((-50, 50), (-1, 100))
        bandwidths = (0.005, 0.01)
    else:
        raise ValueError(f"Unknown Supplementary Figure 12 mode: {mode}")

    source_data_dir = Path(__file__).resolve().parents[1] / 'source_data'
    data = pd.read_csv(source_data_dir / filename).rename(
        columns={'bias_s': 'bias', 'uncertainty_s': 'uncertainty'}
    )
    data = data[data['method'].isin(SELECTED_METHODS)].copy()
    data['method'] = data['method'].map(METHOD_ALIASES)
    data['method'] = pd.Categorical(
        data['method'], categories=METHOD_ORDER, ordered=True
    )
    return data, x_limits, bandwidths


def _plot_distribution_pair(axes, data, mode, x_limits, bandwidths):
    data = data.copy()
    data['bias'] *= 1000
    data['uncertainty'] *= 1000

    create_raincloud(
        axes[0], data, x='bias', y='method', orient='h',
        palette=METHOD_COLORS, bw=bandwidths[0],
        color_mapping=METHOD_COLORS,
    )
    axes[0].set_xlabel(f'Bias,\n{mode} (ms)', ha='center', fontsize=10)
    axes[0].set_xlim(x_limits[0])
    axes[0].set_xticks([-50, 0, 50])
    axes[0].yaxis.label.set_fontweight('bold')

    create_raincloud(
        axes[1], data, x='uncertainty', y='method', orient='h',
        palette=METHOD_COLORS, bw=bandwidths[1],
        color_mapping=METHOD_COLORS,
    )
    axes[1].set_xlabel(
        f'Uncertainty,\n{mode} (ms)', ha='center', fontsize=10
    )
    axes[1].set_ylabel('')
    axes[1].set_xlim(x_limits[1])
    axes[1].set_xticks([0, x_limits[1][1] / 2, x_limits[1][1]])
    axes[1].tick_params(axis='y', labelleft=False)

    for label in axes[0].get_yticklabels():
        method = label.get_text()
        color = METHOD_COLORS.get(method, '#000000')
        label.set_color(color)
        label.set_rotation(0)
    axes[0].set_ylabel('')

    current_ymin, current_ymax = axes[0].get_ylim()
    translation_amount = (current_ymax - current_ymin) * 0.02
    new_ymin = current_ymin + translation_amount
    new_ymax = current_ymax + translation_amount
    for ax in axes:
        ax.set_ylim(new_ymin, new_ymax)
        ax.axvline(x=0, color='black', linestyle='--', linewidth=1)


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Plot matched (A) and unmatched (B) bias/uncertainty."
    )
    panel_group = parser.add_mutually_exclusive_group()
    panel_group.add_argument(
        '--matched', '-m', action='store_true',
        help="Render only the matched distributions.",
    )
    panel_group.add_argument(
        '--unmatched', '-u', action='store_true',
        help="Render only the unmatched distributions.",
    )
    args = parser.parse_args(argv)

    script_dir = figure_dir("supp_figure12", __file__)
    _configure_plot_style()

    if args.matched or args.unmatched:
        mode = 'matched' if args.matched else 'unmatched'
        fig, axes = plt.subplots(1, 2, figsize=(4, 3.4), sharey=True)
        data, x_limits, bandwidths = _load_distribution(script_dir, mode)
        _plot_distribution_pair(axes, data, mode, x_limits, bandwidths)
        fig.tight_layout()
    else:
        # Keep the two within-panel axes compact while reserving enough room
        # for the repeated method labels at the left of both A and B.
        fig = plt.figure(figsize=(8.2, 3.4))
        axes_a = [
            fig.add_axes([0.15, 0.18, 0.14, 0.75]),
            fig.add_axes([0.33, 0.18, 0.14, 0.75]),
        ]
        axes_b = [
            fig.add_axes([0.65, 0.18, 0.14, 0.75]),
            fig.add_axes([0.83, 0.18, 0.14, 0.75]),
        ]
        for axes, mode in ((axes_a, 'matched'), (axes_b, 'unmatched')):
            data, x_limits, bandwidths = _load_distribution(script_dir, mode)
            _plot_distribution_pair(
                axes, data, mode, x_limits, bandwidths
            )

        fig.text(
            0.015, 0.985, 'A', ha='left', va='top',
            family='Arial', fontsize=16, fontweight='normal',
        )
        fig.text(
            0.515, 0.985, 'B', ha='left', va='top',
            family='Arial', fontsize=16, fontweight='normal',
        )

    output_dir = figure_output_dir("supp_figure12", __file__)
    if args.matched:
        output_stem = "suppfigure12_A_matched"
    elif args.unmatched:
        output_stem = "suppfigure12_B_unmatched"
    else:
        output_stem = "suppfigure12_A_B"
    fig.savefig(output_dir / f"{output_stem}.png",dpi=300,bbox_inches="tight")
    fig.savefig(output_dir / f"{output_stem}.pdf",bbox_inches="tight")
    plt.show()

if __name__ == "__main__":
    main()
