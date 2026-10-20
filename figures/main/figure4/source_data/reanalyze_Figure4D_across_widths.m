function results = reanalyze_Figure4D_across_widths(inputFile,outputFolder)
% Reproduce equal-width-average Figure 4d method comparisons.
% Requires MATLAB Statistics and Machine Learning Toolbox.
% inputFile: supplied D_epoch_correlations_all_widths.csv or original
% correlation_tbl_jG8f.mat (variable tbl). outputFolder: results destination.
% Original observations are not modified. This analysis uses the original
% model specification and adds explicit width-averaged contrasts and Holm
% adjustment across eight biophysical-vs-baseline comparisons per cell class.
if nargin<2;outputFolder=pwd;end
if ~isfolder(outputFolder);mkdir(outputFolder);end
[~,~,ext]=fileparts(inputFile);
if strcmpi(ext,'.mat');S=load(inputFile,'tbl');T=S.tbl;
else;T=readtable(inputFile,'TextType','string','VariableNamingRule','preserve');end
T=T(string(T.smoothing)=="raw" & ismember(string(T.cell_type),["exc","inh"]),:);
cells=regexprep(string(T.Cell),"^jGCaMP8f_","");epochs=string(T.Epoch);
ip=string(T.cell_type)=="inh" & string(T.Method)=="PGBAR";
epochs(ip&T.Epoch==3)="1.1";epochs(ip&T.Epoch==4)="2.1";
T.SubjectID=cells+"_"+epochs;T.Z=atanh(T.Correlation);
refs=["Biophys_SMC","Biophys_ML"];cmps=["CASCADE","ENS^2","MLspike","PGBAR"];
rows=struct([]);omni=struct([]);k=0;
for ct=["exc","inh"]
 U=T(string(T.cell_type)==ct,:);U.Method=categorical(U.Method);U.Width=categorical(U.Width);U.SubjectID=categorical(U.SubjectID);
 % Match original default alphabetical reference coding. Reordering the
 % method reference changes coefficient parameterization, not fitted means.
 categoriesM=string(categories(U.Method));U.Method=reordercats(U.Method,cellstr([refs(1);categoriesM(categoriesM~=refs(1))]));
 M=fitlme(U,'Z ~ Method*Width + (1|SubjectID)','DummyVarCoding','reference');
 names=string(M.CoefficientNames);beta=fixedEffects(M);V=M.CoefficientCovariance;nw=numel(categories(U.Width));
 levels=string(categories(U.Method));Hjoint=zeros(numel(levels)-1,numel(names));
 for i=2:numel(levels);Hjoint(i-1,:)=methodAverage(names,levels(i),nw);end
 [p,F,df1,df2]=coefTest(M,Hjoint);nextOmni=struct('cell_type',ct,'F',F,'df1',df1,'df2',df2,'p_raw',p,'p_display',pDisplay(p),'test','joint equal-width-averaged method contrasts');
 if isempty(omni);omni=nextOmni;else;omni(end+1)=nextOmni;end
 for ir=1:numel(refs)
  for ic=1:numel(cmps)
   % Positive estimate favors the biophysical method.
   H=methodAverage(names,refs(ir),nw)-methodAverage(names,cmps(ic),nw);
   [p,F,df1,df2]=coefTest(M,H);est=H*beta;se=sqrt(H*V*H');ci=est+[-1,1]*tinv(.975,df2)*se;
   R=U(string(U.Method)==refs(ir),{'SubjectID','Width','Z'});R.Properties.VariableNames{'Z'}='ReferenceZ';
   C=U(string(U.Method)==cmps(ic),{'SubjectID','Width','Z'});C.Properties.VariableNames{'Z'}='ComparisonZ';
   J=innerjoin(R,C,'Keys',{'SubjectID','Width'});J=J(isfinite(J.ReferenceZ)&isfinite(J.ComparisonZ),:);
   assert(height(unique(J(:,{'SubjectID','Width'}),'rows'))==height(J),'Duplicate epoch/width pairs');
   g=findgroups(J.SubjectID);d=splitapply(@mean,J.ReferenceZ-J.ComparisonZ,g);
   k=k+1;nextRow=struct('cell_type',ct,'reference',refs(ir),'comparison',cmps(ic),'estimate_reference_minus_comparison',est,'se',se,'ci95_lower',ci(1),'ci95_upper',ci(2),'F',F,'df1',df1,'df2',df2,'p_raw',p,'cohens_dz',mean(d)/std(d,0),'n_epochs',numel(d));
   if isempty(rows);rows=nextRow;else;rows(end+1)=nextRow;end
  end
 end
end
results=struct2table(rows);results.p_holm=nan(height(results),1);results.p_display=strings(height(results),1);
for ct=["exc","inh"]
 ix=find(results.cell_type==ct);[p,ord]=sort(results.p_raw(ix));adj=min(1,cummax((numel(p):-1:1)'.*p));results.p_holm(ix(ord))=adj;
end
for i=1:height(results);results.p_display(i)=pDisplay(results.p_holm(i));end
results.ci_scope=repmat("pointwise 95% Fisher-Z difference",height(results),1);
results.effect_size_type=repmat("paired Cohen dz of epoch mean differences across widths",height(results),1);
writetable(results,fullfile(outputFolder,'Figure4D_across_widths_reanalysis.csv'));
writetable(struct2table(omni),fullfile(outputFolder,'Figure4D_across_widths_omnibus.csv'));
% coefTest may numerically underflow extremely small P to zero. Such values
% must be reported as <0.001, not P=0. Intervals above are pointwise,
% not simultaneous.
end

function H=methodAverage(names,method,nw)
H=zeros(1,numel(names));term="Method_"+method;H(names==term)=1;
interaction=startsWith(names,term+":Width_")|(startsWith(names,"Width_")&endsWith(names,":"+term));H(interaction)=1/nw;
end

function s=pDisplay(p)
if p<1e-100;s="<0.001";else;s=string(sprintf('%.12g',p));end
end
