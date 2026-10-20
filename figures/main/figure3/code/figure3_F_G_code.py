#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Plots of spike inference on toy data with biophysical or linear model as in the
indicated figure
"""

# Import required libraries
import matplotlib.pyplot as plt
import os
import sys
from pathlib import Path
import csv
import numpy as np

try:
    from SharedUtilities.project_paths import figure_dir, figure_output_dir
except ImportError:
    sys.path.insert(0, str(Path(__file__).resolve().parents[4] / "shared" / "python"))
    from SharedUtilities.project_paths import figure_dir, figure_output_dir  # type: ignore

"""
Functions used for working with PGAS output
"""
# Method for converting spike times to a binary vector as required by Giovanni's implementation of the PGAS algorithm
def spike_times_2_binary(spike_times,time_stamps):
    # initialize the binary vector
    binary_vector = np.zeros(len(time_stamps), dtype=int)

    # get event times within the time_stamps ends
    good_spike_times = spike_times[(spike_times >= time_stamps[0]) & (spike_times <= time_stamps[-1])]
    
    # Find the nearest element in 'a' that is less than the elements in 'b'
    for event_time in good_spike_times:
        # Find indices where 'a' is less than 'event_time'
        valid_indices = np.where(time_stamps < event_time)[0]
        if valid_indices.size > 0:
            nearest_index = valid_indices[-1]  # Taking the last valid index
            binary_vector[nearest_index] += 1

    return binary_vector

# For opening the janelia datasets
def open_Janelia_1(j_path):
    import scipy.io as sio  # Legacy helper only; CSV plotting does not import SciPy.
    all_data = sio.loadmat(j_path)
    dff = all_data['dff']
    time_stamps = all_data['time_stamps']
    spike_times = all_data['ap_times'] 

    return time_stamps, dff, spike_times

# For unrolling the PGAS and PGBAR output files
def unroll_dat_files(dat_file):
    '''
    PGAS contain the following output variables:
    -B = basline drift, brownian
    -S = discretized spike number per time bin
    -C = "calcium" value - really more akin to a DFF-like metric
    -Y = original data (not included in PGBAR output)
    '''
    

    data = np.genfromtxt(dat_file, delimiter=',', skip_header=1)
    #Dealing out data
    index = data[:,0]
    B = data[:,2]
    S = data[:,3]
    C = data[:,4]
    
    #Note that files produced by PGBAR (rather than the more general PGAS) lack Y - for now not including it
    try:
        Y = data[:,5]
    except:
        Y = np.nan
    
    return index,B,S,C,Y

"""
 Plotting the linear and biophysical model inference outputs
"""

def _csv_records(path):
    with Path(path).open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def load_canonical_simulation(source_dir, panel):
    """Load existing plotted values; no inference or trajectory recomputation.

    Keep the original 3100-point, two-segment vector layout. Exact event times
    and the original one/two-bin display shifts remain in the plotting code.
    """
    source_dir = Path(source_dir)
    prefixes = {"F": ("17_F_simulation.csv", "18_F_ground_truth_spikes.csv"),
                "G": ("19_G_simulation.csv", "20_G_ground_truth_spikes.csv")}
    raw_path, gt_path = prefixes[panel]
    raw = sorted(_csv_records(source_dir / raw_path), key=lambda r: int(r["source_row_index"]))
    n = 3100
    assert [int(r["source_row_index"]) for r in raw] == list(range(1, n + 1))
    result = {"time": np.array([float(r["time"]) for r in raw]),
              "fluorescence": np.array([float(r["column_1"]) for r in raw]),
              "ground_truth": np.array([[float(r["ground_truth_spike_time"])
                    for r in _csv_records(source_dir / gt_path)]])}
    selected_draws = [210, 216, 222, 228, 234, 240]
    for method in ("BiophysSMC", "LinearSMC"):
        mean = sorted(_csv_records(source_dir / f"{panel}_{method}_posterior_mean.csv"),
                      key=lambda r: int(r["native_sample_index"]))
        assert [int(r["native_sample_index"]) for r in mean] == list(range(1, n + 1))
        assert np.array_equal(np.array([float(r["native_time_s"]) for r in mean]), result["time"])
        result[method + "_mean"] = np.array([float(r["mean_spike_count"]) for r in mean])
        samples = np.zeros((len(selected_draws), n))
        seen = set()
        for row in _csv_records(source_dir / f"{panel}_{method}_selected_posterior_spikes.csv"):
            draw, index = int(row["draw_id"]), int(row["native_sample_index"]) - 1
            assert draw in selected_draws and 0 <= index < n
            assert (draw, index) not in seen, "Duplicate selected posterior spike entry"
            seen.add((draw, index))
            samples[selected_draws.index(draw), index] = float(row["stored_spike_count"])
        result[method + "_samples"] = samples
    return result


def main():
    #Getting the file information
    # Get the directory where the script is located
    script_dir = figure_dir("figure3", __file__)
    output_dir = figure_output_dir("figure3", __file__)
    source_dir = Path(__file__).resolve().parent.parent / "source_data"
    data_stub = ["F", "G"]
    times, dffs, spike_times_list = [], [], []
    avg_spks, avg_spks_ar, S_samples, S_samples_ar = [], [], [], []
    draws_to_show = 6
    for panel in data_stub:
        loaded = load_canonical_simulation(source_dir, panel)
        times.append(loaded["time"])
        dffs.append(loaded["fluorescence"])
        spike_times_list.append(loaded["ground_truth"])
        avg_spks.append(loaded["BiophysSMC_mean"])
        avg_spks_ar.append(loaded["LinearSMC_mean"])
        S_samples.append(loaded["BiophysSMC_samples"])
        S_samples_ar.append(loaded["LinearSMC_samples"])

    #Plots
    #For saving
    save_names = [
        "figure3_F_excitatory_simulation",
        "figure3_G_inhibitory_simulation",
    ]

    #Stuff for labels
    x_len = 0.2# in s
    y_len = 0.5# in DF/F
    sel_win = [slice(0,1550),slice(980,1200)]
    plt.rcParams['font.family'] = 'Arial'  # Use a standard font
    plt.rcParams['pdf.fonttype'] = 42       # Embed fonts as TrueType
    plt.rcParams['ps.fonttype'] = 42

    # Colors and titles for the plots
    dat_cols = [(0,0,0),(0.6,0.6,0.6)];spk_cols = [(0,0,0,0.7),'#009E73'];spk_ar_cols = [(0,0,0,0.7),'#CC79A7'];
    titles = ["Excitatory cell-like simulation","Inhibitory cell-like simulation"]

    # Number of posterior samples to show
    num_trials_to_show = 10

    #Init and make
    # Looping over file sets
    for i in np.arange(len(data_stub)):
        # Subplot number to hold raw, biophys, and linear model spike estimates
        fig, axes = plt.subplots(3,len(data_stub), figsize=(3.9, 2.8))

        # Reshape data for plotting
        data_re = dffs[i].reshape((2,1550)).T
        avg_spks_re = avg_spks[i].reshape((2,1550)).T
        #S_samples[i][S_samples[i]>1] = 1
        #S_samples_re = S_samples[i].reshape((2,1550)).T
        S_samples_re = [np.where(s_draw >= 1)[0] for s_draw in S_samples[i]]
        avg_spks_ar_re = avg_spks_ar[i].reshape((2,1550)).T
        #S_samples_ar[i][S_samples_ar[i]>1] = 1
        #S_samples_ar_re = S_samples_ar[i].reshape((2,1550)).T
        S_samples_ar_re = [np.where(s_draw >= 1)[0] for s_draw in S_samples_ar[i]]
        # And get the time step
        dt = times[i][1] - times[i][0]

        # Looping over areas showing up in each l/r panel
        for win_idx, win_slice in enumerate(sel_win):
            # Select out only spikes on plotted interval
            good_spks = (spike_times_list[i][0]-times[i][1551]-0.05>times[i][win_slice.start]) &\
                (spike_times_list[i][0]-times[i][1551]-0.05<times[i][win_slice.stop])
            
            # Plotting subplots as dff [0], spike estimates from biophys [1], and spike estimates from linear model [2]
            # Looping over columns referencing single or multi-spike simulation segment
            for col_idx in np.flipud(range(2)):
                
                # Place raw dff in top panels
                axes[0,win_idx].plot(times[i][win_slice],data_re[win_slice,col_idx],color=dat_cols[col_idx],lw=0.8)
                axes[0,win_idx].set_ylim([-0.1,1.9])# same for both cell types [i]

                # Place biophys into middle panels
                #axes[win].plot(times[i][sel_win[win]]-dt,S_samples_re[sel_win[win],col_idx]-1.1,color=spk_cols[col_idx],lw=0.2) # For individual samples as plots instead of rasters
                axes[2,win_idx].plot(times[i][win_slice]-2*dt,avg_spks_re[win_slice,col_idx],color=spk_cols[col_idx],lw=0.8)
                # SMC posterior draw spikes
                for trial_idx in range(draws_to_show):
                    # get list of spike indices based on simulation segment
                    if col_idx==0:# 1 spike
                        spk_idxs = S_samples_re[trial_idx][S_samples_re[trial_idx]<1550]
                    else: # many spikes
                        spk_idxs = S_samples_re[trial_idx][S_samples_re[trial_idx]>=1550]-1550
                        
                    # plot spikes
                    spk_idxs = spk_idxs[(spk_idxs>=win_slice.start) & (spk_idxs<win_slice.stop)]
                    axes[1,win_idx].scatter(
                        times[i][spk_idxs]-2*dt,
                        np.full(spk_idxs.shape, + trial_idx*0.2),
                        marker='.',               # Down-pointing triangle
                        color=spk_cols[col_idx],  # Color based on column index
                        s=1 # Size of the markers (adjust as needed)
                    )

                # Place linear model into bottom panels
                #axes[win].plot(times[i][sel_win[win]]-dt,S_samples_ar_re[sel_win[win],col_idx]-2.2,color=spk_ar_cols[col_idx],lw=0.2)
                axes[2,win_idx].plot(times[i][win_slice]-dt,avg_spks_ar_re[win_slice,col_idx]-1,color=spk_ar_cols[col_idx],lw=0.8)

                # Linear posterior draw spikes
                for trial_idx in range(draws_to_show):
                    # get list of spike indices based on simulation segment
                    if col_idx==0:# 1 spike
                        spk_idxs = S_samples_ar_re[trial_idx][S_samples_ar_re[trial_idx]<1550]
                    else: # many spikes
                        spk_idxs = S_samples_ar_re[trial_idx][S_samples_ar_re[trial_idx]>=1550]-1550

                    # plot spikes
                    spk_idxs = spk_idxs[(spk_idxs>=win_slice.start) & (spk_idxs<win_slice.stop)]
                    axes[1,win_idx].scatter(
                        times[i][spk_idxs]-dt,
                        np.full(spk_idxs.shape, - trial_idx*0.2 - 0.3),
                        marker='.',               # Down-pointing triangle
                        color=spk_ar_cols[col_idx],  # Color based on column index
                        s=1 # Size of the markers (adjust as needed)
                    )

                # Plot gt spikes
                if col_idx==0 and win_idx!=1:
                    for row_idx in np.arange(3):
                        axes[row_idx,win_idx].axvline(0,ls='--',color=dat_cols[col_idx],alpha=0.8,linewidth=0.4)
                elif col_idx==1:
                    for row_idx in np.arange(3):
                        for spike in spike_times_list[i][0][good_spks]-times[i][1551]-0.05:
                            axes[row_idx,win_idx].axvline(spike,ls='--',color=dat_cols[col_idx],alpha=0.8,linewidth=0.4)

            # Add labels for method to the rightmost panels
            if win_idx==1:
                axes[2,win_idx].text(axes[1,win_idx].get_xlim()[-1],0.3,'Biophys$_\\mathrm{SMC}$',ha='right',color=spk_cols[1])
                axes[2,win_idx].text(axes[2,win_idx].get_xlim()[-1],-0.7,'Linear$_\\mathrm{SMC}$',ha='right',color=spk_ar_cols[1])
        
            #Labels and axes stuff
            for i_ax, row_ax in enumerate(axes):
                for j_ax, ax in enumerate(row_ax):
                    ax.set_xticks([])
                    ax.set_yticks([])
                    for spine in ax.spines.values():
                        spine.set_visible(False)


        # Scale bars in the first panel
        # Start from the upper right corner
        # How far from left to begin, how far down, where to start
        perc_left = 0.08*np.diff(axes[0,0].get_xlim())[0]; perc_down = 0.07*np.diff(axes[0,0].get_ylim())[0]
        start_pt = np.array([axes[0,0].get_xlim()[1]-perc_left,axes[0,0].get_ylim()[1]-perc_down])
        # Adjustments for the lower scale bars
        y_push = 1.1

        # Plot scale bars, add text
        axes[0,0].plot((start_pt[0]-x_len,start_pt[0]),(start_pt[1],start_pt[1]),color='k')
        axes[0,0].plot((start_pt[0],start_pt[0]),(start_pt[1],start_pt[1]-y_len),color='k')
        axes[0,0].text(start_pt[0]-x_len/2,start_pt[1]+0.03,f"{int(x_len*1000)} ms",ha='center',va='bottom',fontsize=10)
        axes[0,0].text(start_pt[0]+0.03,start_pt[1]-y_len/2-0.02,f"{y_len} $\\Delta$F/F",ha='left',va='center',fontsize=10)
        # Horizontal scale bar for the upper right panel as time
        #axes[0,1].plot((start_pt[0]-x_len,start_pt[0]),(start_pt[1],start_pt[1]),color='k')
        # vertical scale bar for the left, bottom panel as spike/bin
        axes[2,0].plot((start_pt[0],start_pt[0]),(start_pt[1]-y_push,start_pt[1]-y_len-y_push),color='k')
        axes[2,0].text(start_pt[0]+0.04,start_pt[1]-y_len/2-0.02-y_push,f"{y_len} spikes",ha='left',va='center',fontsize=10)
        # scale bar for comparing time in left to right panels
        axes[2,0].plot((times[0][win_slice.start],times[0][win_slice.stop]),(axes[2,0].get_ylim()[0]-0.06,axes[2,0].get_ylim()[0]-0.06),color='k',linewidth=2)
        
        # Add y axis labels to the leftmost panels
        axes[0,0].set_ylabel("Fluorescence",fontsize=8)
        axes[1,0].set_ylabel("Posterior\nsamples",fontsize=8)
        axes[2,0].set_ylabel("Avergage\nspike count",fontsize=8)

        plt.tight_layout()
        fig.suptitle(titles[i], fontsize=12)
        plt.subplots_adjust(top=0.85)
        output_stem = save_names[i]
        fig.savefig(output_dir / f"{output_stem}.png",dpi=300,bbox_inches="tight")
        fig.savefig(output_dir / f"{output_stem}.pdf",bbox_inches="tight")

        plt.show(block=False)

    # Ensure all figures are displayed
    plt.show()

if __name__ == "__main__":
    main()
