"""ED1 numeric panels entirely from registered CSVs.

No ODS, MAT, refit, baseline PDF or workbook is read. Original header selection,
pairing, sample SD, and the legacy normalization formulas are preserved explicitly.
This renders panel assets; final published page composition remains a separate step.
"""
from __future__ import annotations
import argparse, hashlib, json, os, re, tempfile
from pathlib import Path
import numpy as np
import pandas as pd

HERE=Path(__file__).resolve().parent
os.environ.setdefault('MPLCONFIGDIR',str(Path(tempfile.gettempdir())/'figshare_mplconfig'))
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

COLORS={'G6f':(0.187839,0.224475,0.554070),'jG7f':(0.950881,0.417288,0.163470),'jG8f':(0.621302,0.106126,0.267048)}
DARK={'G6f':(0.077546,0.085389,0.213703),'jG7f':(0.380667,0.170428,0.068055),'jG8f':(0.224445,0.062821,0.114427)}
NAMES={'G6f':'GCaMP6f','jG7f':'jGCaMP7f','jG8f':'jGCaMP8f'}
BUFFERS=['KMOPS','Int0Mg','Int0.5Mg','Int1Mg','Int1.5Mg','Int2Mg']
CONSTS=list(NAMES)
plt.rcParams.update({'font.family':'Arial','font.size':7,'axes.titlesize':8,'axes.labelsize':7,'xtick.labelsize':6,'ytick.labelsize':6,'pdf.fonttype':42,'axes.spines.top':False,'axes.spines.right':False,'axes.linewidth':.7})

def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def header(h,file_index):
    # Exact ephemeral first-file typo repair in native MATLAB. Never edit CSV.
    return re.sub(r'Int(0\.5|1\.5|0|1|2)_',lambda m:'Int'+m[1]+'Mg_',h) if file_index==1 else h
def sd(a):return float(np.std(a,ddof=1)) if len(a)>1 else 0.
def clean(ax):ax.tick_params(direction='out',length=2,width=.6)
def letter(fig,label):fig.text(.005,.99,label,fontweight='bold',fontsize=10,va='top')

class Inputs:
    def __init__(self,repo):self.root=repo/'figures/extended_data/figure1/source_data';self.paths={}
    def read(self,name):
        p=self.root/name;self.paths[name]={'path':str(p),'sha256':sha(p)};return pd.read_csv(p)

def derive(inputs):
    specs=[];counts=[];checks=[]
    for i,sname,cname in [(1,'03_Corrected_spectra_file1.csv','04_Integrated_counts_file1.csv'),(2,'06_Corrected_spectra_file2.csv','07_Integrated_counts_file2.csv')]:
        s=inputs.read(sname);c=inputs.read(cname)
        for t in [s,c]:
            t['file_index']=i;t['selection_header']=[header(str(h),i) for h in t.original_header]
        sub=s[(s.wavelength>=500)&(s.wavelength<=550)]
        sums=sub.groupby('source_column_index',sort=False).background_subtracted_counts.sum()
        expected=c.set_index('source_column_index').summed_counts_500_550nm
        delta=(sums-expected).abs();checks.append({'file_index':i,'integrated_counts_recheck_max_abs':float(delta.max()),'columns':len(delta),'pass':bool(np.allclose(sums.loc[expected.index],expected,rtol=1e-12,atol=1e-7))})
        specs.append(s);counts.append(c)
    spec=pd.concat(specs,ignore_index=True);cnt=pd.concat(counts,ignore_index=True)
    def selected(table,const,buffer,temp,calcium):
        h=table.selection_header
        mask=h.str.contains(const,regex=False)&h.str.contains(buffer,regex=False)&h.str.contains(calcium,regex=False)
        mask &= h.str.contains('37C',regex=False) if temp==37 else ~h.str.contains('37C',regex=False)
        return table[mask].sort_values(['file_index','source_column_index'],kind='stable')
    rf={};apo={};sat={};members=[]
    for const in CONSTS:
        for buffer in BUFFERS:
            for temp in [22,37]:
                a=selected(cnt,const,buffer,temp,'0mMCa').summed_counts_500_550nm.to_numpy()
                z=selected(cnt,const,buffer,temp,'1.7mMCa').summed_counts_500_550nm.to_numpy()
                if not len(a) or not len(z):raise ValueError(f'Missing exact legacy selection: {const}/{buffer}/{temp}')
                ratio=z/a # MATLAB row-vector elementwise broadcast semantics.
                rf[const,buffer,temp]=ratio;apo[const,buffer,temp]=a;sat[const,buffer,temp]=z
                members.append({'indicator':const,'buffer':buffer,'temperature_C':temp,'apo_columns':len(a),'sat_columns':len(z),'rf_values':ratio.tolist()})
    effects={};ratios_d=[]
    for const in CONSTS:
        temperature=np.concatenate([rf[const,b,37]/np.mean(rf[const,b,22]) for b in BUFFERS])
        ionic=np.array([np.mean(rf[const,'Int0Mg',t])/np.mean(rf[const,'KMOPS',t]) for t in [22,37]])
        # Keep original KMOPS denominator, even though legacy visual label says noMg.
        magnesium=np.array([np.mean(rf[const,b,t])/np.mean(rf[const,'KMOPS',t]) for b in BUFFERS[2:] for t in [22,37]])
        effects[const]={'temperature':temperature,'ionic':ionic,'magnesium':magnesium}
        val=rf[const,'Int1Mg',37]
        if len(val)!=1:raise ValueError('Panel d native scatter expects one37C ratio per indicator')
        ratios_d.append(float(val[0]))
    return spec,selected,apo,sat,effects,ratios_d,members,checks

def run(repo,out):
    out.mkdir(parents=True,exist_ok=True);inputs=Inputs(repo)
    spec,select,apo,sat,effects,ratios_d,members,checks=derive(inputs)
    if not all(c['pass'] for c in checks):raise AssertionError(checks)
    outputs=[];plot_data={}
    def save(fig,stem,panel):
        letter(fig,panel)
        for ext in ['pdf','png']:
            p=out/(stem+'.'+ext);fig.savefig(p,bbox_inches='tight',pad_inches=.04,dpi=200);outputs.append({'path':str(p),'sha256':sha(p),'panel':panel})
        plt.close(fig)
    fig,axs=plt.subplots(3,2,figsize=(2.9,4.1),sharex=True,sharey=True,layout='constrained')
    ymax=0.
    for i,const in enumerate(CONSTS):
        for j,buffer in enumerate(['KMOPS','Int2Mg']):
            ax=axs[i,j]
            for calcium,style in [('0mMCa','--'),('1.7mMCa','-')]:
                s=select(spec,const,buffer,22,calcium)
                g=s.groupby('wavelength',sort=True).background_subtracted_counts.mean()
                ymax=max(ymax,float(s.background_subtracted_counts.max())/1e5)
                ax.plot(g.index,g.to_numpy()/1e5,style,color=COLORS[const],lw=.9)
                plot_data[f'a/{const}/{buffer}/{calcium}']={'wavelength_nm':g.index.tolist(),'mean_counts':g.tolist()}
            if i==0:ax.set_title('KMOPS' if j==0 else 'Internal +\n2 mM Mg$^{2+}$')
            if j==0:ax.set_ylabel(NAMES[const],color=COLORS[const])
            clean(ax)
    for ax in axs.flat:ax.set_ylim(0,ymax*1.03);ax.set_yticks([0,2,4])
    for ax in axs[-1]:ax.set_xlabel('Wavelength (nm)')
    fig.supylabel('Counts ($10^5$ photons)',fontsize=8)
    save(fig,'ED1_a_spectra','a')

    fig,axs=plt.subplots(1,2,figsize=(4.1,1.65),layout='constrained')
    for index,(values,title,limit) in enumerate([(apo,'0 μM Ca$^{2+}$',3e5),(sat,'Saturating Ca$^{2+}$',4e6)]):
        for ci,const in enumerate(CONSTS):
            vals=[values[const,b,22] for b in BUFFERS[1:]]
            y=[float(np.mean(a)) for a in vals];e=[sd(a) for a in vals];x=np.arange(5)*.5
            axs[index].errorbar(x+(ci-1)*.025,np.array(y)/1e5,np.array(e)/1e5,color=COLORS[const],marker='.',lw=.8,capsize=0,label=NAMES[const])
            plot_data[f'b/{const}/{title}']={'Mg_mM':x.tolist(),'mean_counts':y,'SD_counts':e}
        axs[index].set(title=title,xlabel='[Mg$^{2+}$] (mM)',ylim=(0,limit/1e5));clean(axs[index])
    axs[0].set_ylabel('Counts ($10^5$ photons)');axs[0].legend(fontsize=5,frameon=False)
    save(fig,'ED1_b_counts','b')

    fig,axs=plt.subplots(1,3,figsize=(4.4,1.55),layout='constrained')
    for j,(key,title,labels) in enumerate([('temperature','Temperature',['22°C','37°C']),('ionic','Ionic strength',['KMOPS','Internal']),('magnesium','Mg$^{2+}$',['no Mg$^{2+}$','1 mM Mg$^{2+}$'])]):
        for ci,const in enumerate(CONSTS):
            vals=effects[const][key];mean=float(np.mean(vals));err=sd(vals);x=np.array([0.,1.])+(ci-1)*.05
            axs[j].plot(x,[1,mean],'.-',color=COLORS[const],lw=.8)
            axs[j].errorbar(x[1],mean,yerr=err,color=COLORS[const],lw=.8,capsize=0)
            plot_data[f'c/{const}/{key}']={'normalized_values':vals.tolist(),'mean':mean,'SD':err}
        axs[j].set(title=title,xticks=[0,1],xticklabels=labels,xlim=(-.25,1.25),ylim=(0,1.05));clean(axs[j])
    axs[0].set_ylabel('Dynamic range\n(normalized)')
    save(fig,'ED1_c_normalized','c')

    fig,ax=plt.subplots(figsize=(1.2,3.0),layout='constrained')
    ax.scatter(np.arange(3),ratios_d,c=[COLORS[c] for c in CONSTS],s=12)
    ax.set(xticks=np.arange(3),xticklabels=CONSTS,ylim=(0,20),ylabel='$R_f$',title='37°C, [Mg$^{2+}$] 1 mM');clean(ax)
    plot_data['d']={'indicator':CONSTS,'dynamic_range':ratios_d};save(fig,'ED1_d_dynamic_range','d')

    fig,axs=plt.subplots(1,3,figsize=(5.0,1.8),layout='constrained')
    for ax,const in zip(axs,CONSTS):
        for file_index,condition,color in [(('15' if const=='G6f' else '09' if const=='jG7f' else '16'),'K',DARK[const]),(('12' if const=='G6f' else '13' if const=='jG7f' else '14'),'Iplus',COLORS[const])]:
            s=inputs.read(f'{file_index}_F_{const}_{condition}.csv')
            good=s.retained_by_fraction_filter.astype(str).str.lower().eq('true')&s.condition_selected_in_code.astype(str).str.lower().eq('true')
            ss=s[good]
            ax.plot(ss.calcium,ss.half_rise,'.-',color=color,lw=.8,label='no Mg$^{2+}$' if condition=='K' else 'Mg$^{2+}$')
            plot_data[f'f/{const}/{condition}']={'calcium_uM':ss.calcium.tolist(),'half_rise_ms':ss.half_rise.tolist(),'selected_source_rows':ss.source_row_index.tolist()}
        ax.set(xscale='log',yscale='log',xlim=(.04,50),ylim=(1,2000),xticks=[.1,1,10],xticklabels=['0.1','1','10'],yticks=[1,10,100,1000],yticklabels=['1','10','100','1000'],title=NAMES[const],xlabel='free [Ca$^{2+}$] (μM)')
        ax.title.set_color(COLORS[const]);ax.legend(fontsize=5,frameon=False);clean(ax)
    axs[0].set_ylabel('Half rise time (ms)');save(fig,'ED1_f_half_rise','f')
    (out/'plot_data.json').write_text(json.dumps(plot_data,indent=2,allow_nan=False))
    report={'item':'ED1','mode':'packaged_csv_only','adapter_sha256':sha(__file__),'input_files':inputs.paths,'outputs':outputs,'checks':checks,'selection_groups':members,'derived_d_values':ratios_d,'coverage':{'dynamic':['a','b','c','d','f'],'preserved_manual':['e']},'warnings':['Panel c keeps native KMOPS denominators; it does not resolve historical label/normalization question.','500-550nm integrated counts are used exactly as registered; no490nm reinterpretation.','This is a panel renderer; final published page composition is separate.']}
    (out/'adapter_report.json').write_text(json.dumps(report,indent=2))
    print(json.dumps({'item':'ED1','d_values':ratios_d,'checks':checks,'outputs':len(outputs)},indent=2))

if __name__=='__main__':
    default_repo=Path(__file__).resolve().parents[4]
    p=argparse.ArgumentParser();p.add_argument('--repo-root',type=Path,default=default_repo);p.add_argument('--output-root',type=Path);a=p.parse_args()
    repo=a.repo_root.resolve();out=(a.output_root or repo/'build/figures/extended_data/figure1').resolve();run(repo,out)
