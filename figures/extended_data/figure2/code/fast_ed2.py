"""ED2 panels b-d/f-h from registered CSV plot paths/fit summaries.
No native MAT inputs, fit execution, workbook, or published PDF is read.
This is a numeric-panel proposal; manual panels a/e and final composition are separate.
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
from matplotlib.ticker import NullLocator
plt.rcParams.update({'font.family':'Arial','font.size':7,'axes.titlesize':8,'axes.labelsize':7,'xtick.labelsize':6,'ytick.labelsize':6,'pdf.fonttype':42,'axes.spines.top':False,'axes.spines.right':False,'axes.linewidth':.6})
NAMES=['OGB1','GCaMP6f','jGCaMP7f','jGCaMP8f']
COLORS=[(.4745,.4824,.4941),(.1804,.2235,.5529),(.949,.4196,.1686),(.6196,.0039,.2588)]
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def clean(ax):ax.tick_params(direction='out',length=2,width=.6)

def run(repo,out):
    out.mkdir(parents=True,exist_ok=True);root=repo/'figures/extended_data/figure2/source_data'
    inputs={};outputs=[];checks=[];payload={}
    def read(name):
        p=root/name;inputs[name]={'path':str(p),'sha256':sha(p)};return pd.read_csv(p)
    def save(fig,stem,panel):
        fig.text(.002,.998,panel,fontweight='bold',fontsize=10,va='top')
        for ext in ['pdf','png']:
            p=out/(stem+'.'+ext);fig.savefig(p,bbox_inches='tight',pad_inches=.04,dpi=200);outputs.append({'path':str(p),'sha256':sha(p),'panel':panel})
        plt.close(fig)
    def paths(panel):
        df=read(panel.upper()+'_current_refit_plotted_curves.csv');records=[]
        for (ax,ser),g in df.groupby(['axis_index','series_index'],sort=True):
            g=g.sort_values('source_point_index')
            # Native path NaNs break drawn lines; JSON null preserves those gaps.
            vals=lambda s:[float(v) if np.isfinite(v) else None for v in s]
            records.append({'axis':int(ax),'series':int(ser),'x':vals(g.x),'y':vals(g.y),'points':len(g),'nonfinite_values':int((~np.isfinite(g[['x','y']].to_numpy())).sum())})
        payload[panel]={'series':records,'points_policy':'All registered scientific plot-path points retained; workbook view interpolation is separate.'};return records
    def curve(ax,r,color,style='-',lw=.7):
        ax.plot(r['x'],r['y'],style,color=color,lw=lw,ms=1.8)
    rise=read('1_current_refit_summary.csv');decay=read('2_current_refit_summary.csv')
    coeff=read('DG_saved_fit_coefficients.csv')
    row=rise[(rise.indicator=='GCaMP6f')&(rise.condition_index==4)].iloc[0]
    src=coeff[(coeff.direction_index==1)&(coeff.indicator=='GCaMP6f')&(coeff.calcium_condition_index==4)&(coeff.coefficient=='tau1')]
    checks.append({'name':'ED2d GCaMP6f low-Ca fast tau agrees with saved coefficients','summary_ms':float(row.tau1_ms),'coefficient_ms':float(src.value.iloc[0]*1000),'pass':bool(np.isclose(row.tau1_ms,src.value.iloc[0]*1000,rtol=1e-12))})
    if not checks[-1]['pass']:raise AssertionError(checks[-1])

    rr=paths('b');fig,ax=plt.subplots(figsize=(2.0,2.1),layout='constrained')
    for r,color in zip(rr,[COLORS[3],(.22,.22,.22),(.65,.65,.65)]):curve(ax,r,color)
    r=rise[(rise.indicator=='jGCaMP8f')&(rise.condition_index==5)].iloc[0]
    ax.text(.97,.09,f'Fast: {r.tau1_ms:.1f} ms ({r.fraction1:.0%})\nSlow: {r.tau2_ms:.0f} ms ({1-r.fraction1:.0%})',transform=ax.transAxes,ha='right',va='bottom',fontsize=6)
    ax.set(xlim=(0,500),yscale='log',ylim=(1,.03),yticks=[1,.5,.1,.05],yticklabels=['100','50','10','5'],xlabel='Time (ms)',ylabel='Distance from steady state (%)');clean(ax)
    save(fig,'ED2_b_components','b')

    for panel,rise_mode in [('c',True),('h',False)]:
        rr=paths(panel);fig,axs=plt.subplots(1,4,figsize=(6.4,1.7),layout='constrained')
        for i,ax in enumerate(axs):
            for r in [r for r in rr if r['axis']==i+1]:
                # Native path sequence is observed, fit, observed, fit, ...
                pair=(r['series']-1)//2;factor=[1,.78,.58][pair]
                col=tuple(1-factor*(1-np.array(COLORS[i])))
                curve(ax,r,col if r['series']%2 else (.25,.25,.25),'.' if r['series']%2 else '-',.65)
            ax.set(title=NAMES[i],xlim=((2,10) if i==0 else (2,500)) if rise_mode else ((2,15) if i==0 else (2,600)),yscale='log',ylim=(1,.03 if rise_mode else .006),yticks=[1,.5,.1,.05] if rise_mode else [1,.5,.1,.01],yticklabels=['100','50','10','5'] if rise_mode else ['100','50','10','1'],xlabel='Time (ms)');ax.title.set_color(COLORS[i]);clean(ax)
        axs[0].set_ylabel('Distance from steady state (%)' if rise_mode else 'Normalized fluorescence (%)')
        save(fig,'ED2_'+panel+'_fit_traces',panel)

    # Extract rise/decay tau1/tau2/fraction1 for each indicator, preserving NaN for missing fits.
    def extract(df,indicator):
        g=df[(df.indicator==indicator)&(df.summary_included==1)].sort_values('calcium_uM')
        # Only OGB1 has single exponential as only fit option.
        fast=g.tau2_ms.to_numpy() if indicator=='OGB1' else g.tau1_ms.to_numpy()
        slow=g.tau1_ms.to_numpy() if indicator=='OGB1' else g.tau2_ms.to_numpy()
        fraction=1-g.fraction1.to_numpy() if indicator=='OGB1' else g.fraction1.to_numpy()
        vals=lambda a:[None if np.isnan(v) else float(v) for v in a]
        return {'calcium_uM':g.calcium_uM.tolist(),'fast_tau_ms':vals(fast),'slow_tau_ms':vals(slow),'fast_fraction':fraction.tolist(),'condition_index':g.condition_index.tolist()}
    def taus(ax,d,color):
        x=np.array(d['calcium_uM'])
        for key,marker,tint in [('fast_tau_ms','^',0),('slow_tau_ms','o',.75)]:
            y=np.array([np.nan if v is None else v for v in d[key]]);good=np.isfinite(y)
            col=tuple(np.array(color)+tint*(1-np.array(color)))
            ax.plot(x[good],y[good],marker+'-',color=col,ms=3,lw=.7)
    fig,axs=plt.subplots(2,4,figsize=(6.4,2.8),gridspec_kw={'height_ratios':[2,1]},layout='constrained')
    payload['d']={'indicators':{}}
    for i,name in enumerate(NAMES):
        d=extract(rise,name);payload['d']['indicators'][name]=d;x=np.array(d['calcium_uM']);f=np.array(d['fast_fraction'])
        taus(axs[0,i],d,COLORS[i])
        axs[0,i].set(xscale='log',yscale='log',xlim=(.01,20),ylim=(.7,1000),title=name,yticks=[1,10,100,1000]);axs[0,i].title.set_color(COLORS[i])
        axs[1,i].bar(x,f,width=x*.25,color=COLORS[i]);axs[1,i].bar(x,1-f,bottom=f,width=x*.25,color=COLORS[i],alpha=.35)
        axs[1,i].set(xscale='log',xlim=(.01,20),ylim=(0,1),xlabel='free [Ca$^{2+}$] (μM)',yticks=[0,1],yticklabels=['0','100']);clean(axs[0,i]);clean(axs[1,i])
    axs[0,0].set_ylabel('Time constant (ms)');axs[1,0].set_ylabel('Fast / slow (%)')
    save(fig,'ED2_d_rise_constants','d')

    rr=paths('f');fig,axs=plt.subplots(1,4,figsize=(6.4,1.6),layout='constrained')
    for i,ax in enumerate(axs):
        for r in [r for r in rr if r['axis']==i+1]:curve(ax,r,COLORS[i] if r['series']<3 else tuple(.4+.6*np.array(COLORS[i])))
        ax.set(xlim=(0,25) if i==0 else (0,600),ylim=(-.05,1.1),title=NAMES[i],xlabel='Time (ms)');ax.title.set_color(COLORS[i]);clean(ax)
    axs[0].set_ylabel('Normalized fluorescence');save(fig,'ED2_f_decay_traces','f')

    fig,axs=plt.subplots(2,1,figsize=(2.6,2.8),gridspec_kw={'height_ratios':[2,1]},layout='constrained');payload['g']={'indicators':{}}
    for i,name in enumerate(NAMES):
        d=extract(decay,name);payload['g']['indicators'][name]=d;x=np.array(d['calcium_uM']);f=np.array(d['fast_fraction'])
        taus(axs[0],d,COLORS[i]);axs[0].plot([],[],color=COLORS[i],lw=.7,label=name)
        shift=np.exp((i-1.5)*.13);xx=x*shift
        axs[1].bar(xx,f,width=xx*.1,color=COLORS[i]);axs[1].bar(xx,1-f,bottom=f,width=xx*.1,color=COLORS[i],alpha=.35)
    axs[0].set(yscale='log',xscale='log',xlim=(.009,.067),ylim=(1,2000),ylabel='Time constant (ms)',xticks=[.013,.05],xticklabels=['0.01','0.05']);axs[0].legend(frameon=False,fontsize=5,loc='upper left',bbox_to_anchor=(1.02,1))
    axs[1].set(xscale='log',xlim=(.009,.067),ylim=(0,1),xticks=[.013,.05],xticklabels=['0.01','0.05'],yticks=[0,1],yticklabels=['0','100'],xlabel='Nominal free [Ca$^{2+}$] (μM)',ylabel='Fast / slow (%)')
    for ax in axs:clean(ax);ax.xaxis.set_minor_locator(NullLocator())
    save(fig,'ED2_g_decay_constants','g')
    (out/'plot_data.json').write_text(json.dumps(payload,indent=2,allow_nan=False))
    report={'item':'ED2','mode':'packaged_csv_only','adapter_sha256':sha(__file__),'input_files':inputs,'outputs':outputs,'checks':checks,'coverage':{'dynamic':['b','c','d','f','g','h'],'preserved_manual':['a','e']},'warnings':['ED2d uses the accepted GCaMP6f fast tau of 7.835523ms at 0.105652μM from the saved coefficients and fit summary.','Full registered scientific curve paths retained. Workbook200-point presentation interpolation is separate.','This is a panel renderer; final published page composition is separate.']}
    (out/'adapter_report.json').write_text(json.dumps(report,indent=2));print(json.dumps({'item':'ED2','outputs':len(outputs),'checks':checks}))
if __name__=='__main__':
    default_repo=Path(__file__).resolve().parents[4]
    p=argparse.ArgumentParser();p.add_argument('--repo-root',type=Path,default=default_repo);p.add_argument('--output-root',type=Path);a=p.parse_args()
    repo=a.repo_root.resolve();out=(a.output_root or repo/'build/figures/extended_data/figure2').resolve();run(repo,out)
