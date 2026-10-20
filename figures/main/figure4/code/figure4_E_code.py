""" 
    Plots for the distribution of STA and SNA bias and uncertainty for the Janelia8f dataset as detected using
    the methods studied here and shown in figure 4E.
"""
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib
import seaborn as sns
import ptitprince as pt
import os
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

def main():
    # Call the main function to create the plots

    # -----
    # Configuration Parameters
    # -----

    # File path to the data
    input_dir = figure_dir("figure4", __file__)
    source_data_dir = input_dir.parent / "source_data"
    file_path_sta = source_data_dir / "01_Matched_spike_bias.csv"
    file_path_sna = source_data_dir / "02_Epoch_precision_recall.csv"

    # x axis label, limits, and kde bw
    x_label = 'matched'
    xlims = [[-0.05, 0.05],[-0.0005, 0.03]]
    bws = [0.05,0.1]

    # Methods to include in the plots. Set to None to include all.
    selected_methods = ['CASCADE', 'Biophys_{ML}',
    'Biophys_{SMC}', 'ENS^2', 'MLspike', 'PGBAR'] #

    # Types to include in the plots. Set to None to include all.
    selected_types = []  # was for exc or inh, but not used in this version

    # Axis properties
    conversion_factor = 1000 # for ms
    sta_x_limits = (xlims[0][0]*conversion_factor, xlims[0][1]*conversion_factor) # for bias
    performance_x_limits = (0, 100) # for precision and recall
    
    # Plot aesthetics/typeogrpahy
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

    # -----
    # Data Loading and Filtering
    # -----

    # Load the data
    df_sta = pd.read_csv(file_path_sta)
    df_sna = pd.read_csv(file_path_sna)

    # Filter by selected methods and cell type if specified
    if selected_methods:
        df_sta = df_sta[df_sta['method'].isin(selected_methods)]
        df_sna = df_sna[df_sna['method'].isin(selected_methods)]
    # Cell types
    if selected_types:
        df_sta = df_sta[df_sta['type'].isin(selected_types)]
        df_sna = df_sna[df_sna['type'].isin(selected_types)]

    # Map and order the methods by dictionary
    method_aliases = {
        'CASCADE': r'$\mathbf{CASCADE}$',
        'Biophys_{ML}': r'$\mathbf{Biophys}_{\mathbf{ML}}$',
        'Biophys_{SMC}': r'$\mathbf{Biophys}_{\mathbf{SMC}}$',
        'ENS^2': r'$\mathbf{ENS}^{\mathbf{2}}$',
        'MLspike': r'$\mathbf{MLspike}$',
        'PGBAR': r'$\mathbf{PGBAR}$'
    }
    method_colors = {
        r'$\mathbf{CASCADE}$': '#F3AE14',
        r'$\mathbf{Biophys}_{\mathbf{SMC}}$': '#009E73',
        r'$\mathbf{Biophys}_{\mathbf{ML}}$': '#007755',
        r'$\mathbf{ENS}^{\mathbf{2}}$': '#A6780C',
        r'$\mathbf{MLspike}$': '#0072B2',
        r'$\mathbf{PGBAR}$': '#4A4A4A'
    }
    df_sta['method'] = df_sta['method'].map(method_aliases)
    df_sna['method'] = df_sna['method'].map(method_aliases)
    desired_order = [r'$\mathbf{Biophys}_{\mathbf{SMC}}$',
                    r'$\mathbf{PGBAR}$',
                    r'$\mathbf{MLspike}$',
                    r'$\mathbf{Biophys}_{\mathbf{ML}}$',
                    r'$\mathbf{CASCADE}$',
                    r'$\mathbf{ENS}^{\mathbf{2}}$']
    df_sta['method'] = pd.Categorical(df_sta['method'], categories=desired_order, ordered=True)
    df_sna['method'] = pd.Categorical(df_sna['method'], categories=desired_order, ordered=True)

    # -----
    # Creating the Plots
    # -----

    # Create a figure with bias, precision, and recall subplots
    fig, axes = plt.subplots(1, 3, figsize=(6, 3.4), sharey=True)

    # ----
    # Plot for STA
    # ----

    # Create raincloud plot for STA
    df_sta['bias'] = df_sta['bias']*conversion_factor
    create_raincloud(axes[0], df_sta, x='bias', y='method', orient='h', palette=method_colors,bw=bws[0],color_mapping=method_colors)

    # Plot labels
    axes[0].set_xlabel('Bias,\n '+x_label+' (ms)',ha='center',fontsize=10)
    axes[0].set_xlim(sta_x_limits)
    axes[0].yaxis.label.set_fontweight('bold')

    # ----
    # Plot for precision
    # ----

    df_sna['precision'] = df_sna['precision']*100 # scale to percentage
    create_raincloud(axes[1], df_sna, x='precision', y='method', orient='h', palette=method_colors,bw=0.15,color_mapping=method_colors)

    axes[1].set_xlabel('Precision',ha='center',fontsize=10)
    axes[1].set_ylabel('')
    axes[1].set_xlim(performance_x_limits)
    axes[1].set_xticks([0, 50, 100])

    # ----
    # Plot for recall
    # ----

    df_sna['sna_like'] = df_sna['sna_like']*100 + 100 # scale to percentage
    create_raincloud(axes[2], df_sna, x='sna_like', y='method', orient='h', palette=method_colors,bw=0.15,color_mapping=method_colors)

    axes[2].set_xlabel('Recall (Ground \ntruth detection rate)',ha='center',fontsize=10)
    axes[2].set_ylabel('')
    axes[2].set_xlim(performance_x_limits)
    axes[2].set_xticks([0, 50, 100])

    # ----
    # Final figure adjustments
    # ----

    # Iterate through the y-axis tick labels on axes[0] for coloring method names
    for label in axes[0].get_yticklabels():
        method = label.get_text()
        color = method_colors.get(method, '#000000')  # Default to black if method not found
        label.set_color(color)
        label.set_rotation(0)  # Ensure labels are horizontal
    axes[0].set_ylabel('') 

    # Handling the spacing and positioning of plot elements
    plt.tight_layout()
    current_ymin, current_ymax = axes[0].get_ylim()
    delta_y = current_ymax - current_ymin
    translation_percentage = 0.02
    translation_amount = delta_y * translation_percentage
    new_ymin = current_ymin + translation_amount
    new_ymax = current_ymax + translation_amount
    for ax in axes:
        # adjust vertical plot edges
        ax.set_ylim(new_ymin, new_ymax)

    # add in a 0 indicator line for all plots
    for ax in axes:
        ax.axvline(x=0, color='black', linestyle='--', linewidth=1)

    output_dir = figure_output_dir("figure4", __file__)
    fig.savefig(output_dir / "figure4_E_F_G.png",dpi=300,bbox_inches="tight")
    fig.savefig(output_dir / "figure4_E_F_G.pdf",bbox_inches="tight")
    plt.show()

if __name__ == "__main__":
    main()
