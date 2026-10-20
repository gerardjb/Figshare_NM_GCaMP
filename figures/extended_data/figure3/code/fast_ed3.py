"""ED3 quantitative panels b-e from registered exact plotted CSVs.
No ODE integration, native MAT data, fitting, workbook, or published PDF is read.
Manual panel a and final-page assembly must be preserved separately.
"""
from __future__ import annotations
import argparse, hashlib, json, os, tempfile
from pathlib import Path
import numpy as np
import pandas as pd
HERE=Path(__file__).resolve().parent
os.environ.setdefault('MPLCONFIGDIR',str(Path(tempfile.gettempdir())/'figshare_mplconfig'))
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
plt.rcParams.update({'font.family':'Arial','font.size':7,'axes.titlesize':8,'axes.labelsize':7,'xtick.labelsize':6,'ytick.labelsize':6,'pdf.fonttype':42,'axes.spines.top':False,'axes.spines.right':False,'axes.linewidth':.6})
NAMES=['GCaMP6f','jGCaMP7f','jGCaMP8f']
COLORS=[(.0588,.1098,.4745),(.8,.3725,.0353),(.6196,.0039,.2588)]
MODEL=(0,.6196,.451)
STATECOLORS=[(.7569,.7333,.4314),(.3373,.7059,.9137),(.502,.502,.502)]
STATES=['fast_fluorescent_occupancy','slow_fluorescent_occupancy','slow_nonfluorescent_occupancy']
LABELS=['Fast fluorescent','Slow fluorescent','Slow nonfluorescent']
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def clean(ax):ax.tick_params(direction='out',length=2,width=.6)
def run(repo,out):
    out.mkdir(parents=True,exist_ok=True);root=repo/'figures/extended_data/figure3/source_data';inputs={};outputs=[];payload={};checks=[]
    def read(name):
        p=root/name;inputs[name]={'path':str(p),'sha256':sha(p)};return pd.read_csv(p)
    def save(fig,stem,panel):
        fig.text(.002,.998,panel,fontweight='bold',fontsize=10,va='top')
        for ext in ['pdf','png']:
            p=out/(stem+'.'+ext);fig.savefig(p,bbox_inches='tight',pad_inches=.04,dpi=200);outputs.append({'path':str(p),'sha256':sha(p),'panel':panel})
        plt.close(fig)
    def numeric_payload(df):return {k:[float(v) if np.isfinite(v) else None for v in df[k]] for k in df}
    for direction,panel in [('rise','b'),('decay','c')]:
        fig,axs=plt.subplots(4,3,figsize=(5.8,5.4),gridspec_kw={'height_ratios':[1.7,1,1,1]},layout='constrained',sharex='col')
        for i,name in enumerate(NAMES):
            d=read(f'ED3_{name}_{direction}_stoppedflow_states.csv');payload[f'{panel}/{name}']=numeric_payload(d)
            axs[0,i].plot(d.time_ms,d.observed_normalized_fluorescence,color=COLORS[i],lw=.7)
            axs[0,i].plot(d.time_ms,d.model_normalized_fluorescence,color=MODEL,lw=.7)
            axs[0,i].set_title(name,color=COLORS[i]);axs[0,i].set_ylim(0,max(d.observed_normalized_fluorescence.max(),d.model_normalized_fluorescence.max())*1.05)
            for j,col in enumerate(STATES):
                axs[j+1,i].plot(d.time_ms,d[col],color=STATECOLORS[j],lw=.7)
                axs[j+1,i].set_ylim(0,1 if direction=='decay' or j==2 else [.6,.9,.6][i])
            axs[-1,i].set_xlabel('Time (ms)')
            for ax in axs[:,i]:ax.set_xlim(0,400);ax.set_xticks([0,200,400]);clean(ax)
            finite=bool(np.isfinite(d.to_numpy()).all());checks.append({'name':f'{direction}/{name} finite registered values','pass':finite,'rows':len(d)})
            # The exported occupancy values already encode model definitions; do not infer states from F.
        axs[0,0].set_ylabel('Normalized fluorescence')
        for j,label in enumerate(LABELS):axs[j+1,0].set_ylabel(label+'\noccupancy')
        axs[0,0].legend(handles=[Line2D([],[],color=COLORS[0],lw=.8,label='Observed'),Line2D([],[],color=MODEL,lw=.8,label='Model')],frameon=False,fontsize=5,loc='upper left')
        save(fig,'ED3_'+panel+'_'+direction+'_states',panel)
    fig,axs=plt.subplots(5,3,figsize=(5.6,4.5),layout='constrained',sharex='col')
    for i,name in enumerate(NAMES):
        d=read(f'ED3_{name}_bouton_traces.csv');ev=read(f'ED3_{name}_bouton_stimulus_events.csv');payload[f'd/{name}']=numeric_payload(d);payload[f'd/{name}/events']=numeric_payload(ev)
        upper=max(d.observed_DeltaF_F.max(),d.model_DeltaF_F.max())+.05
        for j,protocol in enumerate([1,2,3,4,5]):
            ax=axs[j,i];dd=d[d.protocol_index==protocol].sort_values('time_ms');ee=ev[ev.protocol_index==protocol]
            ax.plot(dd.time_ms,dd.observed_DeltaF_F,color=COLORS[i],lw=.7);ax.plot(dd.time_ms,dd.model_DeltaF_F,color=MODEL,lw=.7)
            ax.vlines(ee.spike_time_ms,-.015,.015,color='black',lw=.7)
            ax.set(xlim=(-50,300),ylim=(-.03,upper));ax.axis('off')
            if j==0:
                ax.set_title(name,color=COLORS[i]);height=[.5,.7,.2][i]
                ax.plot([180,280],[upper*.86,upper*.86],color='black',lw=.7);ax.plot([280,280],[upper*.86-height,upper*.86],color='black',lw=.7)
                ax.text(230,upper*.86,'100 ms',ha='center',va='bottom',fontsize=5)
                ax.text(283,upper*.86-height/2,str(height)+' ΔF/F',fontsize=5,va='center')
            if i==0:ax.text(-.05,.5,f'{1 if j==0 else [0,10,20,50,100][j]} ms' if j else '1 AP',transform=ax.transAxes,rotation=90,ha='right',va='center',fontsize=6)
        checks.append({'name':f'{name} bouton exact stimulus events','pass':ev.spike_time_ms.tolist()==[0,0,10,0,20,0,50,0,100],'event_count':len(ev)})
    save(fig,'ED3_d_bouton_traces','d')
    fig,axs=plt.subplots(3,3,figsize=(5.6,3.3),layout='constrained',sharex='col')
    for i,name in enumerate(NAMES):
        d=read(f'ED3_{name}_bouton_states.csv');payload[f'e/{name}']=numeric_payload(d)
        shared_max=max(d[STATES[0]].max(),d[STATES[1]].max())
        for j,col in enumerate(STATES):
            ax=axs[j,i]
            for protocol,g in d.groupby('protocol_index',sort=True):
                g=g.sort_values('time_ms');ax.plot(g.time_ms,g[col],color=STATECOLORS[j],lw=.7)
            ax.set_xlim(-50,300);ax.set_ylim(0,1 if j==2 else shared_max);ax.set_xticks([0,150,300]);clean(ax)
            if j==0:ax.set_title(name,color=COLORS[i])
            if j==2:ax.set_xlabel('Time (ms)')
        checks.append({'name':f'{name} state protocol coverage','pass':sorted(d.protocol_index.unique().tolist())==[1,2,3,4,5]})
    for j,label in enumerate(LABELS):axs[j,0].set_ylabel(label+'\noccupancy')
    save(fig,'ED3_e_bouton_states','e')
    if not all(c['pass'] for c in checks):raise AssertionError(checks)
    (out/'plot_data.json').write_text(json.dumps(payload,indent=2,allow_nan=False))
    report={'item':'ED3','mode':'packaged_csv_only','adapter_sha256':sha(__file__),'input_files':inputs,'outputs':outputs,'checks':checks,'coverage':{'dynamic':['b','c','d','e'],'preserved_manual':['a']},'warnings':['ED3b uses the accepted saved observed jGCaMP8f trace as packaged; no additional affine display transformation is applied.','No fitted states or curves were altered.','Full scientific plot-path resolution is retained; <=200-point workbook views are separate.','State-axis auto-limits use plotted CSV maxima; final assembly preserves published axis and scale-bar geometry.','This is a panel renderer; final published page composition is separate.']}
    (out/'adapter_report.json').write_text(json.dumps(report,indent=2));print(json.dumps({'item':'ED3','outputs':len(outputs),'checks':checks}))
if __name__=='__main__':
    default_repo=Path(__file__).resolve().parents[4]
    p=argparse.ArgumentParser();p.add_argument('--repo-root',type=Path,default=default_repo);p.add_argument('--output-root',type=Path);a=p.parse_args()
    repo=a.repo_root.resolve();out=(a.output_root or repo/'build/figures/extended_data/figure3').resolve();run(repo,out)
