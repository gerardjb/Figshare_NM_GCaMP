function suppfigure_5_code(mode)
%%%
% Plots of sample clusters used to select GCaMP model parameters as in the
% indicated figure
%%%

% The reviewed publication uses the fixed saved heatmap order and CSV traces.
% Explicit "original" mode retains the historical analysis for research use.
if nargin < 1 || ~strcmpi(string(mode),"original")
    renderNote2CanonicalCsv;
    return
end

% Close any open plots
close all

% Collect data files
d = fullfile(fileparts(mfilename("fullpath")),'..','inputs');
addpath(d);
sfDataFile = projectFile('shared','inputs','stoppedFlowTraces.mat');
boutonDataFile = projectFile('shared','inputs','gDbase.mat');
summaryFile = fullfile(d,'ParallelizedSummary.mat');

% Get summary from all fits
load(summaryFile);
requiredSummaryVars = {'t_all','bouton_params_all','PoisG_params_all'};
for iReq = 1:numel(requiredSummaryVars)
    if ~exist(requiredSummaryVars{iReq},'var')
        error('suppfigure_5_code:missingSummaryVariable',...
            'ParallelizedSummary.mat is missing %s. Rebuild the appended summary inputs before running.',...
            requiredSummaryVars{iReq});
    end
end
tPoisG = tPoisG(:);
stubs = stubs(:);
t_all = t_all(:);
nFits = numel(stubs);
output_params_all = asFitRows(output_params_all,nFits,'output_params_all');
bouton_params_all = asFitRows(bouton_params_all,nFits,'bouton_params_all');
PoisG_params_all = asFitRows(PoisG_params_all,nFits,'PoisG_params_all');
resnorm_all = asFitColumn(resnorm_all,nFits,'resnorm_all');
resnormB_all = asFitColumn(resnormB_all,nFits,'resnormB_all');
resnorm1_2_10_all = asFitColumn(resnorm1_2_10_all,nFits,'resnorm1_2_10_all');
resnormPoisG_all = asFitColumn(resnormPoisG_all,nFits,'resnormPoisG_all');
poistRise = asFitColumn(poistRise,nFits,'poistRise');
if numel(t_all) ~= nFits
    error('suppfigure_5_code:summaryShapeMismatch',...
        't_all has %d entries but stubs has %d entries.',numel(t_all),nFits);
end

%Get rid of inf values for resnorm vectors
resnormB_all(~isfinite(resnormB_all)) = nan;
resnorm1_2_10_all(~isfinite(resnorm1_2_10_all)) = nan;
resnormPoisG_all(~isfinite(resnormPoisG_all)) = nan;
%For nan handling on z scoring
zscore_nan = @(x) (x - nanmean(x))/nanstd(x);

% Initializations for stability
%Set rng to default to get consistent results in the k-means clustering
rng default

%Making name for output .mat file
const = strtok(analysis_path,'_');
paramList = {'K-aN','k-offN','H-N',...
    'K-aC','k-offC','H-C',...
    'k-onPN','k-offPN','k-onPC','k-offPC',...
    'k-onPN2','k-offPN2','k-onPC2','k-offPC2'};%,'alpha'};
xticks = 1:(length(paramList)+4);
xlabels = [paramList,'SF','PP','1-2-10','Pois'];


%% Getting z-scores for all params figure
z = zscore([output_params_all]);zB = zscore_nan(resnormB_all);
z1_2_10 = zscore_nan(resnorm1_2_10_all);zPoisG = zscore_nan(resnormPoisG_all);
zpoistRise = zscore_nan(poistRise);
zminus = [z(:,1:end-1),zscore_nan(resnorm_all),...
    zB,z1_2_10,...
    zPoisG];
[~,sortIdx] = sort(resnorm_all);


%% kMeans clustering figs
%kMeans clustering of the data
clust2plot = [1,5,9];
bbs = {};
nClusters = 9;
kID = kmeans(z,nClusters);

%Sorting by residuals then clusters
all_res = [resnorm_all,resnormB_all,resnorm1_2_10_all,resnormPoisG_all];
all_mins = repmat(min(all_res,[],1).*[1,1,1,4],size(all_res,1),1);
normed_all_res = all_res./all_mins;

[sortkID,firstSort] = sortrows([sum(normed_all_res,2),kID],[1,2]);%resnormPoisG_all
%Resort clusters by lowest residual score in each
sortkID(:,3) = zeros(size(sortkID,1),1);
clustScores = arrayfun(@(i) min(sortkID(sortkID(:,2)==i,1)),1:nClusters);
[~,sort_clustScores] = sort(clustScores);
for i =1:nClusters
    sortkID(sortkID(:,2)==sort_clustScores(i),3)=i;
end
[sortkID,sortCluster] = sortrows(sortkID(:,[1,3]),[2,1]);
sortCluster = firstSort(sortCluster);
sortkID = sortkID(:,2);

% Limit the number of rows for each cluster to 20
limitedSortCluster = [];short_kID = [];
for i = 1:nClusters
    clusterIndices = find(sortkID == i);
    if length(clusterIndices) > 20
        clusterIndices = clusterIndices(1:20);
        short_kID = [i*ones(length(clusterIndices),1);short_kID];
    end
    limitedSortCluster = [limitedSortCluster; clusterIndices];
end
short_kID = flipud(short_kID);

% Adjust the sortCluster array for length if desired
short_clusters = true;
if short_clusters
    shortCluster = sortCluster(limitedSortCluster);
else
    shortCluster = sortCluster;
    short_kID = sortkID;
end

%Making the plot
sizer = [7.5,3.5];
fClust = figure;%hold on;
set(fClust,'Paperunits','inches',...
    'Papersize',sizer,...
    'Paperposition',[0,0,sizer],...
    'Units','inches',...
    'Position',[1,1,sizer]);

zPlot = zminus;zPlot(isnan(zminus))=100;
imagesc(zPlot(shortCluster,:),[-1,1]);
colormap redblue
c = colorbar;ylabel(c,'Z-score','FontName','arial','FontSize',10);
colormap(c,'redblue');
set(gca,'xtick',xticks,'xticklabels',xlabels,'ytick',[],'FontName','arial','fontsize',10)
%Append rectangles to indicate clusters
cmap = [validatecolor(pickGCaMPcolorsMS('biophys_{MC'));flipud(k2colorCmap([0,0,0],nClusters-1))];%turbo(max(kID));
legHand = [];hold on;
lin_wids = [1.8,repmat(0.8,1,length(kID)-1)];
for i = max(kID):-1:1
    thisCornerY = find(short_kID==i,1,'first')+0.5;
    thisHeight = sum(short_kID==i);
    rectangle('Position',[0.5,thisCornerY,length(paramList),thisHeight-1],'EdgeColor','k','Linewidth',lin_wids(i));
    h = plot(nan,nan,'Linewidth',3,'Color',cmap(i,:));
    legHand = [legHand,h];
    if i==1
        text(0,thisCornerY,['Cluster ',num2str(i)],'HorizontalAlignment','right','VerticalAlignment','top',...
            'fontweight','bold','FontName','arial','FontSize',10);
    else
        tex = text(0,thisCornerY,num2str(i),'HorizontalAlignment','right','VerticalAlignment','top','FontName','arial','FontSize',10);
        if ismember(i,clust2plot)
            set(tex,'fontweight','bold');
        end
    end
end

title('Parameter sets sorted by cluster, residuals','fontsize',12,'FontName','arial')
set(gca,'fontsize',10,'fontname','arial')


%% Doing plots for the best output from each cluster
for iId = 1:nClusters
    if ~ismember(iId,clust2plot)
        continue
    elseif iId==1
        fCol = [validatecolor(pickGCaMPcolorsMS('biophys_{MC')),0.5];
    else
        fCol = [0.5,0.5,0.5,0.6];
    end
    clear til
    %Select the file with minimized bouton res for this cluster
    fitIdx = sortCluster(find(sortkID==iId,1));
    thisFile = getStubName(stubs,fitIdx);
    output_params = real(output_params_all(fitIdx,:));
    bouton_params = real(bouton_params_all(fitIdx,:));
    PoisG_params = real(PoisG_params_all(fitIdx,:));
    t = t_all{fitIdx};
    t = t(:);
    if any(~isfinite([bouton_params,PoisG_params]))
        error('suppfigure_5_code:missingFitParameters',...
            'Selected fit %s has incomplete bouton or Poisson parameters in ParallelizedSummary.mat.',...
            thisFile);
    end
    
    %Set up plot tiles
    sizer = [8,2.6];
    f = figure;hold on;
    set(f,'Paperunits','inches',...
        'Papersize',sizer,...
        'Paperposition',[0,0,sizer],...
        'Units','inches',...
        'Position',[1,1,sizer]);
    sWid = 1;bWid = 1;pWid = 2;p_zoom_Wid = 2;%width of each plot
    height = 2;
    wid = sWid+bWid+pWid+p_zoom_Wid;
    %Placing into the proper position for the outer layout
    til = tiledlayout(f,height,wid,'tilespacing','compact');
    
    %Get, prep, and plot data with fits for SF
    load(sfDataFile,'processedTraces')
    thisConst = nominal({processedTraces{1}.const})==GCaMPalias(const);
    goodFits = {1:9,10:11};
    kinType = {'(on kinetics)','(off kinetics)'};
    normfit = rebuildStoppedFlowFit(processedTraces,thisConst,output_params);
    for i = 1:length(processedTraces)
        Time = processedTraces{i}(thisConst).time(processedTraces{i}(thisConst).logSelectPts,:);
        datasets = processedTraces{i}(thisConst).traces(processedTraces{i}(thisConst).logSelectPts,:);
        thisNormfit = reshape(normfit,[],11);
        thisNormfit = thisNormfit(:,goodFits{i});
        
        %Add SF overlay plot to tile
        nexttile(til,height/2*(wid)*(i-1)+1,[height/2,sWid]);hold on;
        set(gca,'tickdir','out','linewidth',1);
        plot(Time*1000,datasets,...
            'linestyle','-','Color',pickGCaMPcolorsMS(const),'linewidth',1);
        plot(Time*1000,thisNormfit,...
            'color',[fCol],'linewidth',2)
        if i==1
            set(gca,'xticklabels',[])
            title({'Stopped flow'});
        else
            xlabel('Time (ms)')
            set(gca,'XTickLabelRotation',0)
            ylabel('Normalized F')
        end
        
        set(gca,'xlim',[0,400],'xtick',[0,200,400],...
            'ytick',[0,0.5,1],'ylim',[0.0,1],...
            'FontName','arial','FontSize',10)
    end
    
    %Get, prep, and plot data with fits for boutons
    spikes = {[0],[0,0.01],[0,0.02],[0,0.05],[0,0.1]};
    idxs_2_show = [1,2];
    [DFF,time] = prepPPRdata(boutonDataFile,const);
    dff_hat = GCaMPboutonSim6L_2state({bouton_params,spikes,output_params},t);
    maxY = max(DFF(:))+0.05*max(DFF(:));
    DFF = reshape(DFF,[],length(spikes));
    t = reshape(t,[],length(spikes));
    dff_hat = reshape(dff_hat,[],length(spikes));
    gcol = pickGCaMPcolorsMS(const);
    for i = 1:length(idxs_2_show)
        nexttile(til,height/length(idxs_2_show)*(i-1)*(wid)+1+sWid,[height/length(idxs_2_show),bWid]);hold on;
        set(gca,'tickdir','out','linewidth',1);
        plot((t(:,idxs_2_show(i))-spikes{idxs_2_show(i)}(end))*1000,DFF(:,idxs_2_show(i)),'color',gcol);
        h = plot((t(:,idxs_2_show(i))-spikes{idxs_2_show(i)}(end))*1000,dff_hat(:,idxs_2_show(i)),'-','linewidth',2,...
            'color',fCol);
        ax = h.Parent;
        set(ax,'ylim',[-0.05,maxY],'xtick',[0,100,200],'xlim',[-75,250])
        ax.YAxis.Visible = 'off';
        %putStim(spikes{i}*1000,maxY-maxY*0.02,h,gcol);
        arrayfun(@(x) plot([x,x],ylim,'k--','LineWidth',0.7),(spikes{idxs_2_show(i)}-spikes{idxs_2_show(i)}(end))*1000);
        ylims = ax.YLim;span = round((ylims(2)-ylims(1))/3,1);
        xVal = 100;
        %ax.XLim = [-150,150];
        if i==1
            yText = [num2str(span),' ',greek_char('Delta'),'F/F'];
            xText = [num2str(xVal), ' ms'];
            title({'Paired-pulse'});
            makeTSscaleBar(ax,'xFrac',0.43,'xval',xVal,'xtext',xText,...
                'yFrac',1/3,'yVal',span,'yText',yText,'xPush',0.03,...
                'lefty',0,'upsidedown',true);
        else; yText=''; 
        end
        
        if i~=length(idxs_2_show)
            set(ax,'xticklabel',[]);
        end
        if i == length(idxs_2_show)
            %xlabel('time from last stim (ms)');
        end
        set(gca,'FontName','arial','FontSize',10)
        axis off;
    end

    %Add tile for Poisson stim
    [DFF,spikes] = prepPoisGdata(boutonDataFile,const);
    idxs_2_show = 2;
    dff_hatPoisG = GCaMPboutonSim6L_2state({PoisG_params,spikes,output_params},tPoisG);
    
    maxY = max(DFF(:))+0.05*max(DFF(:));
    %DFF = reshape(DFF,[],length(spikes));
    t = tPoisG;
    %t = reshape(t,[],length(spikes));
    maxTIdx = find(islocalmax(tPoisG));
    idxs = [1,maxTIdx,length(t)];
    xzoom = [100,500];% part to emphasize where bad clusters miss


    for i = 1:length(idxs_2_show)
        % Here adding the Poisson tile, note that idxs_2_show allows
        % shoiwng single overlaid if desired, though seems unneccessary
        p_tile = nexttile(til,height/length(idxs_2_show)*(i-1)*(wid)+1+sWid+bWid,[height/length(idxs_2_show),pWid]);hold on;
        set(gca,'tickdir','out','linewidth',1);
        plot(t(idxs(idxs_2_show(i))+1:idxs(idxs_2_show(i)+1))*1000,DFF(idxs(idxs_2_show(i))+1:idxs(idxs_2_show(i)+1)),'color',gcol);
        h = plot(t(idxs(idxs_2_show(i))+1:idxs(idxs_2_show(i)+1))*1000,dff_hatPoisG(idxs(idxs_2_show(i))+1:idxs(idxs_2_show(i)+1)),'-','linewidth',2,...
            'color',fCol);
        ax = h.Parent;
        set(ax,'ylim',[-0.05,maxY],'xlim',[-0.05,1500]);
        ax.YAxis.Visible = 'off';
        arrayfun(@(x) plot([x,x],ylim,'k--','LineWidth',0.7),spikes{idxs_2_show(i)}*1000);
        ylims = ax.YLim;span = round((ylims(2)-ylims(1))/3,1);
        if i==1;yText = [num2str(span),' \DeltaF/F'];
            title('Poisson train');
        else; yText=''; 
        end
        makeTSscaleBar(ax,'xFrac',7/8,'yFrac',2/4,'yVal',0,'yText','',...
            'xval',200,'xtext',[num2str(200),' ms'],...
            'lefty',0,'upsidedown',true)
        if i~=length(idxs_2_show(i))
            %set(ax,'xticklabel',[]);
        end
        if i == length(idxs_2_show(i))
            %xlabel('time from first stim (s)');
        else
            set(gca,'xticklabel',[]);
        end
        set(gca,'fontname','arial','fontsize',10)
        axis off;
        
        %Now adding the zoomed in bit in the next tile
        xVal = 100;
        z_tile = nexttile(til,height/length(idxs_2_show)*(i-1)*(wid)+1+sWid+bWid+pWid,[height/length(idxs_2_show),p_zoom_Wid]);hold on;
        plot(t(idxs(idxs_2_show(i))+1:idxs(idxs_2_show(i)+1))*1000,DFF(idxs(idxs_2_show(i))+1:idxs(idxs_2_show(i)+1)),'color',gcol);
        h = plot(t(idxs(idxs_2_show(i))+1:idxs(idxs_2_show(i)+1))*1000,dff_hatPoisG(idxs(idxs_2_show(i))+1:idxs(idxs_2_show(i)+1)),'-','linewidth',2,...
            'color',fCol);
        ax = h.Parent;
        set(ax,'ylim',[-0.05,maxY]);
        ax.YAxis.Visible = 'off';
        arrayfun(@(x) plot([x,x],ylim,'k--','LineWidth',0.7),spikes{idxs_2_show(i)}*1000);
        set(gca,'ytick',[],'xlim',xzoom)
        makeTSscaleBar(gca,'xFrac',6/7,'yFrac',2/4,'yVal',0.4,'yText',[num2str(0.4),' ',greek_char('Delta'),'F/F'],...
            'xval',xVal,'xtext',[num2str(xVal),' ms'],...
            'lefty',0,'upsidedown',true)
        set(gca,'fontname','arial','fontsize',10)
        axis off
        
        % Add annotation connecting the two plots
        % Points to connect
        x1 = xzoom(1);y1 = -0.05;
        x2 = xzoom(2);y2 = -0.05;
        % Get positions of the axes in normalized figure units
        [xp1, yp1] = point2ax(p_tile,x1,y1);
        [xp2, yp2] = point2ax(p_tile,x2,y2);
        [xz1, yz1] = point2ax(z_tile,x1,y1);
        [xz2, yz2] = point2ax(z_tile,x2,y2);
        % Draw dotted lines connecting the two plots
        pad_y = 0.01;pad_x = 0.002;drop1 = 0.03;drop2 = 0.06;%positioning of plot elements
        % Under zoomed on p
        annotation('line', [xp1, xp2],[yp1-drop1, yp2-drop1],'color','k','LineWidth',3);%zoomed_p area
        annotation('line', [xp1+pad_x, xp1+pad_x],[yp1-pad_y, yp2-drop1],'color','k','LineWidth',3);%zoom_p down
        annotation('line', [xp2-pad_x, xp2-pad_x],[yp2-drop1, yp2-pad_y],'color','k','LineWidth',3);%zoom_p up
        % connecting
        annotation('line', [mean([xp1,xp2]), mean([xp1,xp2])],[yp1-drop1-pad_y, yp1-drop1-drop2],'color','k','LineWidth',1.5,'LineStyle','--');%connect down
        annotation('line', [mean([xp1,xp2]), mean([xz1,xz2])],[yp1-drop1-drop2, yz1-drop1-drop2],'color','k','LineWidth',1.5,'LineStyle','--');%connect across
        annotation('line', [mean([xz1,xz2]), mean([xz1,xz2])],[yz1-drop1-drop2, yp1-drop1-pad_y],'color','k','LineWidth',1.5,'LineStyle','--');%connect up      
        % Under zoomed on z
        annotation('line', [xz1, xz2],[yz1-drop1, yz2-drop1],'color','k','LineWidth',3);%zoomed_z area
        annotation('line', [xz1+pad_x, xz1+pad_x],[yz1-pad_y, yz2-drop1],'color','k','LineWidth',3);%zoom_z down
        annotation('line', [xz2-pad_x, xz2-pad_x],[yz2-drop1, yz2-pad_y],'color','k','LineWidth',3);%zoom_z up
    end
    
    %Finish plot
    if iId==1
        title(til,['Cluster ',num2str(iId),' (Biophysical model)'],...
            'color',fCol,...
            'fontsize',12,'fontweight','bold','fontname','arial');        
    else
        title(til,['Cluster ',num2str(iId)],'fontsize',12,'fontweight','bold','color',cmap(iId,:),'fontname','arial');
    end
    
    
end%iId

saveFigureOutputs("supp_figure5","suppfigure5");
end

%% function block
function X = asFitRows(X,nFits,varName)
    X = real(X);
    if size(X,1) ~= nFits && size(X,2) == nFits
        X = X';
    end
    if size(X,1) ~= nFits
        error('suppfigure_5_code:summaryShapeMismatch',...
            '%s has %d rows but expected %d rows.',varName,size(X,1),nFits);
    end
end

function x = asFitColumn(x,nFits,varName)
    x = real(x(:));
    if numel(x) ~= nFits
        error('suppfigure_5_code:summaryShapeMismatch',...
            '%s has %d entries but expected %d entries.',varName,numel(x),nFits);
    end
end

function thisFile = getStubName(stubs,fitIdx)
    if iscell(stubs)
        thisStub = stubs{fitIdx};
    else
        thisStub = stubs(fitIdx);
    end
    thisFile = thisStub.name;
end

function normfit = rebuildStoppedFlowFit(processedTraces,thisConst,Gparams)
    fitBlocks = cell(1,numel(processedTraces));
    for iTrace = 1:numel(processedTraces)
        traceData = processedTraces{iTrace}(thisConst);
        Time = traceData.time(traceData.logSelectPts,:);
        calcium = traceData.calcium(:)' * 1e-9 * Gparams(end);
        try
            traceType = lower(string(traceData.type));
        catch
            traceType = "";
        end
        isOffKinetics = contains(traceType,"off") || numel(calcium) == 2;
        if isOffKinetics
            caPairs = [repmat(1e-3,1,numel(calcium)); calcium];
        else
            caPairs = [repmat(calcium(1),1,numel(calcium)); calcium];
        end
        fitBlocks{iTrace} = cell2mat(arrayfun(@(iCa) ...
            Fitting_function_eig_WD_simple6(caPairs(:,iCa),Gparams,Time(:,iCa)')', ...
            1:size(Time,2),'UniformOutput',false));
    end
    normfit = [fitBlocks{:}];
end

function [normF,t] = prepPPRdata(fname,const)
    %load data, select relevant construct
    load(fname);
    thisConst = nominal({gData.const})==GCaMPalias(const);
    
    %Isolate selected data
    targs = size(gData(thisConst).PPRtraces.Data{1},2)-1;%idx - 1 as time vector in first column
    offset = gData(thisConst).PPRtraces.tOffset;%time offset for first stim
    ts = cell(1,targs);
    normFs = cell(1,targs);
    
    for i = 1:targs
        %Data to fit
        t = cellfun(@(x) x(:,1)/1000,gData(thisConst).PPRtraces.Data,'UniformOutput',false);%in seconds
        f = cellfun(@(x) x(:,i+1),gData(thisConst).PPRtraces.Data,'UniformOutput',false);
        t = [t{:}]-offset;f = [f{:}];
        %Make single pulse peak response similar
        if nominal(const)==nominal('jG8f')
            normtarg = mean(f(216:222,:),1);
            normF = f.*repmat(nanmean(normtarg)./normtarg,size(f,1),1);
        elseif nominal(const)==nominal('jG7f')
            normF = f.*repmat([1,1,1,1.1,1],size(f,1),1);
        else
            normF = f;
        end
        %Truncating baseline
        normF = normF(t>=-0.1);
        t = t(t>=-0.1);%Simulation start time
        ts{i} = t;
        normFs{i} = normF;
        
    end
    
    targBouton = 5;
    t = reshape(ts{targBouton},[],1);
    normF = normFs{targBouton};
    
end


function [normF,spikes] = prepPoisGdata(fname,const)
    load(fname)
    constIdx = nominal({gData.const})==GCaMPalias(const);
    
    %Set up data to plot
    normF = mean(gData(constIdx).PoisGiov2(2).data_poisson(:,2:end),2);%2:end for all trials
    spikes = gData(constIdx).PoisGiov2(2).stimtimes_poisson/1000;%convert to seconds
    t = gData(constIdx).PoisGiov2(2).data_poisson(:,1)-spikes(1);
    spikes = spikes - spikes(1);
    
    spike_single = gData(constIdx).PoisGiov2(2).stimtimes_single/1000;
    single = mean(gData(constIdx).PoisGiov2(2).data_single(:,2:end),2);
    t_single = gData(constIdx).PoisGiov2(2).data_single(:,1)-spike_single;
    spike_single = 0;
    
    
    %truncate baselines at 20 ms and concatenate
    normF = normF(t>=-0.02);
    single = single(t_single>=-0.02);
    t = t(t>=-0.02);
    t_single = t_single(t_single>=-0.02);
    normF = [single;normF];
    t = [t_single;t];
    spikes = {spike_single,spikes};

end

function [xn, yn] = point2ax(ax, xData, yData)
% Function to convert data coordinates to normalized figure units
    % Get axes position in normalized units
    axPos = ax.Position;
    
    % Get axes limits
    xlim = ax.XLim;
    ylim = ax.YLim;
    
    % Normalize data coordinates within axes
    xn = (xData - xlim(1)) / (xlim(2) - xlim(1));
    yn = (yData - ylim(1)) / (ylim(2) - ylim(1));
    
    % Convert to figure normalized coordinates
    xn = axPos(1) + xn * axPos(3);
    yn = axPos(2) + yn * axPos(4);
end
