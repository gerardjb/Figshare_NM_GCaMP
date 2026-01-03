""" 
    Plots for the distribution of STA and SNA bias and uncertainty for the Janelia8f dataset as detected using
    the methods studied here and shown in supplementary figure 10.
"""

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib
import seaborn as sns
import ptitprince as pt
import os
import argparse

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
    # Create the half-violin (density) plot
    pt.half_violinplot(x=x, y=y, data=data, palette=palette, bw=bw, ax=ax,width=0.95,
                       linewidth=0.1, orient=orient,gridsize=5000,
                       offset=0.1-stripplot_shift,scale="width") #high gridsize because STA plots too coarse without this
    
    # Add and color-code the boxplot
    box = sns.boxplot(
        x=x, y=y, data=data, width=0.12, ax=ax, orient=orient, showcaps=False,
        boxprops={'linewidth':1},
        medianprops={'color': 'white', 'linewidth': 1.5},
        showfliers=False, whiskerprops={'linewidth':1},dodge=True, palette=palette,
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

"""
    Plotting the distribution of bias (STA) and uncertainty (SNA) for the Janelia8f dataset as detected using 
    the methods studied here and shown in figure 4E.
"""

def main():
    # Call the main function to create the plots
    # -----
    # Handle arg inputs
    # -----
    parser = argparse.ArgumentParser(description="Toggle between matched and unmatched plots.")
    parser.add_argument('--matched','-m', action='store_true',
                        help="If set, plot matched distributions; otherwise, use plot unmatched.")
    args = parser.parse_args()

    # -----
    # Configuration Parameters
    # -----

    # File path to the data
    script_dir = os.path.dirname(os.path.abspath(__file__))
    if args.matched:
        # Set the file to read
        file_path_sta = os.path.join(script_dir,'matched_bias_uncert.csv')

        # x axis label, limits, and kde bw
        x_label = 'matched'
        xlims = [[-0.05, 0.05],[-0.0005, 0.03]]
        bws = [0.05,0.1]
    else:
        # Set the file to read
        file_path_sta = os.path.join(script_dir,'unmatched_bias_uncert.csv')

        # x axis label and limits, and kde bw
        x_label = 'unmatched'
        xlims = [[-0.05, 0.05],[-0.001, 0.1]]
        bws = [0.005,0.01]


    # Methods to include in the plots. Set to None to include all.
    selected_methods = ['CASCADE', 'Biophys_{ML}',
    'Biophys_{SMC}', 'ENS^2', 'MLspike'] #

    # Types to include in the plots. Set to None to include all.
    selected_types = []  # was for exc or inh, but not used in this version

    # Axis properties
    conversion_factor = 1000 # for ms
    sta_x_limits = (xlims[0][0]*conversion_factor, xlims[0][1]*conversion_factor) # for bias
    sna_x_limits = (xlims[1][0]*conversion_factor, xlims[1][1]*conversion_factor)  # for uncertainty
    
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

    # Filter by selected methods and cell type if specified
    if selected_methods:
        df_sta = df_sta[df_sta['method'].isin(selected_methods)]
    # Cell types
    if selected_types:
        df_sta = df_sta[df_sta['type'].isin(selected_types)]

    # Map and order the methods by dictionary
    method_aliases = {
        'CASCADE': r'$\mathbf{CASCADE}$',
        'Biophys_{ML}': r'$\mathbf{Biophys}_{\mathbf{ML}}$',
        'Biophys_{SMC}': r'$\mathbf{Biophys}_{\mathbf{SMC}}$',
        'ENS^2': r'$\mathbf{ENS}^{\mathbf{2}}$',
        'MLspike': r'$\mathbf{MLspike}$'
    }
    method_colors = {
        r'$\mathbf{CASCADE}$': '#F3AE14',
        r'$\mathbf{Biophys}_{\mathbf{SMC}}$': '#009E73',
        r'$\mathbf{Biophys}_{\mathbf{ML}}$': '#007755',
        r'$\mathbf{ENS}^{\mathbf{2}}$': '#A6780C',
        r'$\mathbf{MLspike}$': '#0072B2' 
    }
    df_sta['method'] = df_sta['method'].map(method_aliases)
    desired_order = [r'$\mathbf{Biophys}_{\mathbf{SMC}}$',
                    r'$\mathbf{MLspike}$',
                    r'$\mathbf{Biophys}_{\mathbf{ML}}$',
                    r'$\mathbf{CASCADE}$',
                    r'$\mathbf{ENS}^{\mathbf{2}}$']
    df_sta['method'] = pd.Categorical(df_sta['method'], categories=desired_order, ordered=True)

    # -----
    # Creating the Plots
    # -----

    # Create a figure with two subplots (bias and uncertainty)
    fig, axes = plt.subplots(1, 2, figsize=(4, 3.4), sharey=True)

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
    axes[1].set_xticks([0,sta_x_limits[1]/2,sta_x_limits[1]])

    # ----
    # Plot for SNA
    # ----

    # Create raincloud plot for SNA
    df_sta['uncertainty'] = df_sta['uncertainty']*conversion_factor# scale to percentage
    create_raincloud(axes[1], df_sta, x='uncertainty', y='method', orient='h', palette=method_colors,bw=bws[1],color_mapping=method_colors)

    # Customize the SNA plot
    axes[1].set_xlabel('Uncertainty,\n '+x_label+' (ms)',ha='center',fontsize=10)
    axes[1].set_ylabel('')
    axes[1].set_xlim(sna_x_limits)
    axes[1].set_xticks([0,sna_x_limits[1]/2,sna_x_limits[1]])

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

    # add in a 0 indicator line for both plots
    axes[0].axvline(x=0, color='black', linestyle='--', linewidth=1)
    axes[1].axvline(x=0, color='black', linestyle='--', linewidth=1)

    plt.show()

if __name__ == "__main__":
    main()