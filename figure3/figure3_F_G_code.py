#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Plots of spike inference on toy data with biophysical or linear model as in the
indicated figure
"""

# Import required libraries
import matplotlib.pyplot as plt
import os
import scipy.io as sio
import numpy as np

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

def main():
    #Getting the file information
    # Get the directory where the script is located
    script_dir = os.path.dirname(os.path.abspath(__file__))
    data_stub = [ "test_exc.mat","test_inh.mat"]
    sim_stub = ["traj_samples_default_janelia_sample_excitatory.dat","traj_samples_default_janelia_sample_inhibitory2.dat"]
    pgbar_stub = ["traj_samples_experiment4_exc_AR2.dat","traj_samples_inhibitory_AR2.dat"]



    #Load and process the inferences
    recalc = True
    if recalc:
        #initialize lists
        times = [];dffs = [];binary_spikes_list = [];spike_times_list=[]
        trajs = [];spks = [];S_samples = []
        trajs_ar = [];spks_ar = []; S_samples_ar = []
        avg_trajs = [];std_trajs = [];avg_spks = []
        avg_trajs_ar = [];std_trajs_ar = [];avg_spks_ar = []

        # sample spike latent state trajectory to show
        S_2_start = 210
        S_2_end = 300
        draws_to_show = 6
        selected_draws = np.arange(S_2_start, S_2_end, draws_to_show)

        for i in np.arange(len(data_stub)):
            #Get data
            data_file = os.path.join(script_dir,data_stub[i])
            time,data_dff,spike_times = open_Janelia_1(data_file)
            times.append(time[0,:])
            dffs.append(data_dff[0,:])
            spike_times_list.append(spike_times)
            binary_spikes_list.append(spike_times_2_binary(spike_times,times[i]))
        
            # Getting the PGAS and PGBAR output
            pgas_file = os.path.join(script_dir,sim_stub[i])
            index, B, S, C, Y = unroll_dat_files(pgas_file)
            pgbar_file = os.path.join(script_dir,pgbar_stub[i])
            index_ar, B_ar, S_ar, C_ar, Y_ar = unroll_dat_files(pgbar_file)
            
            # Now reshaping for mean trajectories
            trajs.append((B + C).reshape((-1, np.sum(index == 0))).T)
            avg_trajs.append(np.mean(trajs[i][:, -100:], axis=1))
            std_trajs.append(np.std(trajs[i][:, -100:], axis=1))
            S_samples.append([S[index==draw].T for draw in selected_draws])
            #S_samples.append(S[index == S_2_show].T)
            spks.append(S.reshape((-1, np.sum(index == 0))).T)
            avg_spks.append(np.mean(spks[i][:, -100:], axis=1))
            # AR ones
            trajs_ar.append((B_ar + C_ar).reshape((-1, np.sum(index_ar == 0))).T)
            avg_trajs_ar.append(np.mean(trajs_ar[i][:, -100:], axis=1))
            std_trajs_ar.append(np.std(trajs_ar[i][:, -100:], axis=1))
            S_samples_ar.append([S_ar[index_ar==draw].T for draw in selected_draws])
            #S_samples_ar.append(S_ar[index_ar == S_2_show].T)
            spks_ar.append(S_ar.reshape((-1, np.sum(index_ar == 0))).T)
            avg_spks_ar.append(np.mean(spks_ar[i][:, -100:], axis=1))

    #Plots
    #For saving
    save_names = ['main_fig3_panelsI-J.pdf','main_fig3_panelsK-L.pdf']

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
        #plt.savefig(save_names[i],format='pdf',dpi=300)

        plt.show(block=False)

    # Ensure all figures are displayed
    plt.show()

if __name__ == "__main__":
    main()