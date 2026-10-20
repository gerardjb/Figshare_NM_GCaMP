function results=reanalyze_ED9G_across_widths(inputFile,outputFolder)
% Equal-weight contrasts across seven Gaussian filter widths for ED9g.
% Requires MATLAB Statistics and Machine Learning Toolbox. Original input
% correlations are retained. Inference uses Satterthwaite denominator DF,
% Holm correction over eight biophysical-vs-comparator contrasts, and paired
% Cohen dz of epoch-level Fisher-Z differences averaged across the widths.
% Run with no arguments beside the supplied 02_Epoch_correlations.csv, or
% pass its path and a writable output directory explicitly.
if nargin<1,inputFile=fullfile(fileparts(mfilename('fullpath')),'02_Epoch_correlations.csv');end
if nargin<2,outputFolder=pwd;end
if ~isfolder(outputFolder),mkdir(outputFolder);end
T=readtable(inputFile,'TextType','string','VariableNamingRule','preserve');
runKeys=["pgasraw","ens2_jG8m_sweep2_best_k2_r9_s2p0_d0p45_sb19000",...
 "cascadein_nodisc_ens2","cascade_updated_model","matlab_mlspike_jG8m2","pgbar_janelia_8m"];
rawMethods=["pgas","ens2","ens2","cascade","mlspike","pgbar"];
labels=["Biophys_SMC","Biophys_ML","ENS2","CASCADE","MLspike","PGBAR"];
widths=[10 20 30 40 50 75 100];selected=false(height(T),1);mapped=strings(height(T),1);
for k=1:numel(labels)
 q=string(T.run)==runKeys(k)&string(T.method)==rawMethods(k)&string(T.smoothing)=="raw";
 selected=selected|q;mapped(q)=labels(k);
end
U=T(selected&ismember(T.corr_sigma_ms,widths),:);mapped=mapped(selected&ismember(T.corr_sigma_ms,widths));
assert(all(isfinite(U.correlation)&abs(U.correlation)<1),'Invalid Fisher-Z input');
U.Method=categorical(mapped,labels);U.Width=categorical(U.corr_sigma_ms,widths);
U.SubjectID=categorical(string(U.dataset)+"_"+string(U.trial));U.Z=atanh(U.correlation);
assert(height(unique(U(:,{'SubjectID','Method','Width'}),'rows'))==height(U),'Duplicate observations');
assert(height(U)==numel(categories(U.SubjectID))*numel(labels)*numel(widths),'Incomplete method-by-width grid');
M=fitlme(U,'Z ~ Method*Width + (1|SubjectID)','DummyVarCoding','reference');
names=string(M.CoefficientNames);beta=fixedEffects(M);V=M.CoefficientCovariance;
levels=string(categories(U.Method));nw=numel(widths);Hmeans=zeros(numel(levels),numel(names));
for j=1:numel(levels),Hmeans(j,:)=methodAverage(names,levels(j),nw);end
% Independently evaluate all six-by-seven prediction rows; shared intercept
% and width terms cancel in differences. Verify against the compact formula.
grid=repmat(U(1,:),numel(levels)*nw,1);pos=0;Hgrid=zeros(size(Hmeans));
for j=1:numel(levels)
 for k=1:nw
  pos=pos+1;grid.Method(pos)=categorical(levels(j),labels);grid.Width(pos)=categorical(widths(k),widths);
 end
end
pred=predict(M,grid,'Conditional',false);modelMeans=reshape(pred,nw,[])';modelMeans=mean(modelMeans,2);
relativeMeans=(Hmeans-Hmeans(1,:))*beta;assert(max(abs(relativeMeans-(modelMeans-modelMeans(1))))<1e-10);
Hjoint=Hmeans(2:end,:)-Hmeans(1,:);
[p,F,df1,df2]=coefTest(M,Hjoint,zeros(size(Hjoint,1),1),'DFMethod','satterthwaite');
[pr,~,~,dfr]=coefTest(M,Hjoint);
lp=logFtail(F,df1,df2);omni=table(F,df1,df2,p,lp,scientificP(lp),pr,dfr,'VariableNames',{'F','df1','df2','p_raw','p_raw_log10','p_raw_scientific','residual_p_sensitivity','residual_df2_sensitivity'});
refs=["Biophys_SMC","Biophys_ML"];cmps=["CASCADE","ENS2","MLspike","PGBAR"];rows=struct([]);n=0;epochs=table;
for ir=1:numel(refs)
 for ic=1:numel(cmps)
  ri=find(levels==refs(ir));ci=find(levels==cmps(ic));H=Hmeans(ri,:)-Hmeans(ci,:);
  [p,F,df1,df2]=coefTest(M,H,0,'DFMethod','satterthwaite');[pr,~,~,dfr]=coefTest(M,H);
  est=H*beta;se=sqrt(H*V*H');ci95=est+[-1 1]*tinv(.975,df2)*se;
  R=U(string(U.Method)==refs(ir),{'SubjectID','Width','Z'});R.Properties.VariableNames{'Z'}='ReferenceZ';
  C=U(string(U.Method)==cmps(ic),{'SubjectID','Width','Z'});C.Properties.VariableNames{'Z'}='ComparisonZ';
  J=innerjoin(R,C,'Keys',{'SubjectID','Width'});g=findgroups(J.SubjectID);
  [d,subject]=splitapply(@(x,id)deal(mean(x),id(1)),J.ReferenceZ-J.ComparisonZ,J.SubjectID,g);
  assert(max(abs(mean(d)-est))<1e-10,'Raw paired-average and model contrast disagree');
  next=table(repmat(refs(ir),numel(d),1),repmat(cmps(ic),numel(d),1),subject,d,'VariableNames',{'reference','comparison','SubjectID','epoch_mean_FisherZ_difference'});epochs=[epochs;next];
  n=n+1;nextRow=struct('reference',refs(ir),'comparison',cmps(ic),'estimate_reference_minus_comparison',est,'se',se,'ci95_lower',ci95(1),'ci95_upper',ci95(2),'F',F,'df1',df1,'df2',df2,'p_raw',p,'p_raw_log10',logFtail(F,df1,df2),'cohens_dz',mean(d)/std(d,0),'n_epochs',numel(d),'n_cells',numel(unique(U.dataset)),'residual_p_sensitivity',pr,'residual_df2_sensitivity',dfr);
  if isempty(rows),rows=nextRow;else,rows(end+1)=nextRow;end
 end
end
results=struct2table(rows);[sorted,order]=sort(results.p_raw_log10);adj=min(0,cummax(log10((height(results):-1:1)')+sorted));results.p_holm_log10=nan(height(results),1);results.p_holm_log10(order)=adj;results.p_holm=10.^results.p_holm_log10;
results.p_raw_scientific=strings(height(results),1);results.p_holm_scientific=strings(height(results),1);
for i=1:height(results),results.p_raw_scientific(i)=scientificP(results.p_raw_log10(i));results.p_holm_scientific(i)=scientificP(results.p_holm_log10(i));end
results.p_display=strings(height(results),1);for i=1:height(results),results.p_display(i)=pDisplay(results.p_holm(i));end
results.ci_scope=repmat("pointwise 95% Fisher-Z difference; not multiplicity-adjusted",height(results),1);
results.effect_size_type=repmat("paired Cohen dz of epoch mean Fisher-Z differences across seven widths",height(results),1);
writetable(results,fullfile(outputFolder,'ED9G_across_widths_reanalysis.csv'));
writetable(omni,fullfile(outputFolder,'ED9G_across_widths_omnibus.csv'));
writetable(epochs,fullfile(outputFolder,'ED9G_epoch_mean_paired_differences.csv'));
writetable(table(levels,modelMeans,'VariableNames',{'method','model_mean_FisherZ_across_widths'}),fullfile(outputFolder,'ED9G_model_marginal_means.csv'));
audit=struct('n_rows',height(U),'n_methods',numel(levels),'n_widths',nw,'widths_ms',widths,'n_epochs',numel(categories(U.SubjectID)),'n_cells',numel(unique(U.dataset)),'formula','Z ~ Method*Width + (1|SubjectID)','DFMethod','satterthwaite','family','eight biophysical-versus-comparator contrasts','multiplicity','Holm','independent_prediction_grid_maximum_error',max(abs(relativeMeans-(modelMeans-modelMeans(1)))),'raw_epoch_pair_mean_matches_model_contrasts',true,'input_correlations_modified',false);
fid=fopen(fullfile(outputFolder,'ED9G_analysis_audit.json'),'w');fprintf(fid,'%s',jsonencode(audit,PrettyPrint=true));fclose(fid);
save(fullfile(outputFolder,'ED9G_model.mat'),'M','Hjoint','Hmeans','names','U');
disp(omni);disp(results);
end

function H=methodAverage(names,method,nw)
H=zeros(1,numel(names));term="Method_"+method;H(names==term)=1;
interaction=startsWith(names,term+":Width_")|(startsWith(names,"Width_")&endsWith(names,":"+term));H(interaction)=1/nw;
end
function s=pDisplay(p)
if p<1e-100,s="<0.001";else,s=string(sprintf('%.12g',p));end
end
function lp=logFtail(F,d1,d2)
% Regularized incomplete beta in log space avoids F-tail underflow. The
% continued fraction uses the standard modified Lentz beta expansion.
x=d2/(d2+d1*F);a=d2/2;b=d1/2;
if x>=(a+1)/(a+b+2),lp=log10(fcdbeta(x,a,b));return;end
tiny=1e-300;qab=a+b;qap=a+1;qam=a-1;c=1;d=1-qab*x/qap;if abs(d)<tiny,d=tiny;end;d=1/d;h=d;
for m=1:20000
 m2=2*m;aa=m*(b-m)*x/((qam+m2)*(a+m2));d=1+aa*d;if abs(d)<tiny,d=tiny;end;c=1+aa/c;if abs(c)<tiny,c=tiny;end;d=1/d;h=h*d*c;
 aa=-(a+m)*(qab+m)*x/((a+m2)*(qap+m2));d=1+aa*d;if abs(d)<tiny,d=tiny;end;c=1+aa/c;if abs(c)<tiny,c=tiny;end;d=1/d;delta=d*c;h=h*delta;if abs(delta-1)<3e-14,break;end
end
lp=(a*log(x)+b*log1p(-x)-betaln(a,b)+log(h/a))/log(10);
end
function p=fcdbeta(x,a,b),p=betainc(x,a,b);end
function s=scientificP(lp)
e=floor(lp);s=string(sprintf('%.12ge%+d',10^(lp-e),e));
end
