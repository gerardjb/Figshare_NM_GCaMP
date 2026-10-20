function [out,second] = figure2CsvInputs(kind,sourceDataDir)
% Read-only CSV support for fast Figure2 plots to avoid fitting/extraction.
names=["OGB1","GCaMP6f","jGCaMP7f","jGCaMP8f"]; second=[];
if strcmp(kind,'early_hill_summary')
    files={'09_GH_OGB1_samples.csv','11_GH_GCaMP6f_samples.csv', ...
        '13_GH_jGCaMP7f_samples.csv','15_GH_jGCaMP8f_samples.csv'};
    out=zeros(1,4);second=out;
    for i=1:4
        T=readtable(fullfile(sourceDataDir,files{i}),'TextType','string');
        T=T(T.sampling_phase=="early",:);
        calcium=unique(T.calcium,'stable');
        Y=arrayfun(@(x) mean(T.normalized_fluorescence(abs(T.calcium-x)<1e-8)),calcium);
        Y(Y>0.999)=0.99;
        p=polyfit(log10(calcium/1000),log10(Y./(1-Y)),2);der=polyder(p);
        out(i)=polyval(der,0.1);
        second(i)=(polyval(der,0.4)-polyval(der,-0.2))/2;
    end
    return
end
numbers=[8,10,12,14];if strcmp(kind,'decay'),numbers=[16,17,18,19];end
out=repmat(struct('const',"",'time',[],'traces',[],'calcium',[],'logSelectPts',[],'preTime',[],'preTrace',[]),1,4);
if strcmp(kind,'decay'),baseline=readtable(fullfile(sourceDataDir,'D_saved_prestep_baselines.csv'),'TextType','string');end
for i=1:4
    file=sprintf('%02d_CD_%s_%s.csv',numbers(i),kind,names(i));
    q=readtable(fullfile(sourceDataDir,file));columns=unique(q.calcium_column_index,'stable');
    nr=nnz(q.calcium_column_index==columns(1));tt=zeros(nr,numel(columns));yy=tt;ca=zeros(1,numel(columns));
    for j=1:numel(columns)
        qq=q(q.calcium_column_index==columns(j),:);
        tt(:,j)=qq.time/1000;yy(:,j)=qq.normalized_fluorescence;ca(j)=qq.calcium(1);
    end
    out(i).const=names(i);out(i).time=tt;out(i).traces=yy;
    out(i).calcium=ca;out(i).logSelectPts=(1:nr)';
    if strcmp(kind,'decay')
        qq=baseline(baseline.indicator==names(i),:);
        out(i).preTime=qq.time_ms/1000;out(i).preTrace=qq.normalized_fluorescence;
    end
end
end
