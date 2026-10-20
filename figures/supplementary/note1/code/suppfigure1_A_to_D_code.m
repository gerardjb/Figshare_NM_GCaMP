function suppfigure1_A_to_D_code(mode)
%%%
% Plots of complex, biexponential decay of jGCaMP8f bouton responses as in
% the indicated figure
%%%

% Default publication path consumes CSVs, without refitting.
if nargin < 1 || ~strcmpi(string(mode),"original")
    renderNote1CanonicalCsv("A_D");
    return
end

% Close any open plots
close all

% Open data files
d = fullfile(fileparts(mfilename("fullpath")),'..','inputs');
load(projectFile('shared','inputs','gDbase.mat'))

% Get data for specific const to show
const = 'jG8f';
constIdx = nominal({gData.const})==GCaMPalias(const);
bouton2show = 2;

% Set up plot to run in the loop here
ff = figure;
sizerSum = [8.5,4];
set(ff,'Paperunits','inches',...
    'Papersize',sizerSum,...
    'Paperposition',[0,0,sizerSum],...
    'Units','inches',...
    'Position',[4,2,sizerSum]);
% tile things
nCols = 3;
t_outer = tiledlayout(ff,1,nCols,"TileSpacing","loose");
t_traces = tiledlayout(t_outer,2,1,'Tilespacing','compact');
t_fits = tiledlayout(t_outer,3,1,'Tilespacing','tight');
t_summary = tiledlayout(t_outer,3,1,"Tilespacing","tight");

% cmap across the different numbers of spikes consitent with figure 1
% (i.e., #C58B9F) and colors for exp stuff
col = hex2rgb(pickGCaMPcolorsMS(const));
cmap = [col;...
    adjustSaturation((tint_rgb(col,1.25)),0.3);...
    adjustSaturation((tint_rgb(col,1.55)),0.15)];
spike_cols = {[0,0,0],[0.8,0.8,0.8]};

% Matices to hold the models and gofs
every_model = {};

for targBouton = 1:length(gData(constIdx).traces1_2_10.Data)
    % Set up data to fit
    normF = gData(constIdx).traces1_2_10.Data{targBouton};
    t = gData(constIdx).traces1_2_10.ts{targBouton};
    spikes = {0,[0,0.01],0:0.01:0.09};
    
    % If this is the structure we want to target, add trace panels here
    if targBouton==bouton2show
        nexttile(t_traces);hold on;
        xlims = [-0.11,0.6];
        % stacked traces tile
        flipF = fliplr(normF);flip_cmap = flipud(cmap);
        arrayfun(@(x) plot(t(:,x),flipF(:,x),...
            'Color',flip_cmap(x,:),'LineWidth',1),1:3);
        plot(xlim,[0,0],'k--','LineWidth',2);
        %color for spikes
        spikes_plt = {0,0.01:0.01:0.09};
        cellfun(@(y,blks) arrayfun(@(x) plot([x,x],ylim,'k--','Color',blks,'LineWidth',0.4),y),spikes_plt,spike_cols);
        set(gca,xlim=xlims,ylim=[-0.05,1])
        xscale = 0.1;yscale = 0.2;
        makeTSscaleBar(gca,"upsidedown",true,"xfrac",1/2,"yFrac",1/2,"lefty",false,...
            "xVal",xscale,"xText",[num2str(1000*xscale),' ms'],...
            "yVal",yscale,"yText",[num2str(yscale),' ',greek_char("Delta"),'F/F'],...
            "font",'arial','fontSize',10)
        axis off;
        title('1-2-10 protocol','FontName','arial','FontSize',12)
        set(gca,'FontName','arial','fontsize',10)
        
        % normalized traces for kinetics tile
        nexttile(t_traces);hold on;
        for i = 1:size(normF,2)
            plot(t-repmat(max(spikes{i}),size(t,1),1),...%subtract time of last spike
                smoothdata(normF(:,i),"movmean",9)./max(smoothdata(normF(:,i),"movmean",9)),...
                "Color",cmap(i,:),linewidth=1);
        end
        set(gca,xlim=xlims,ylim=[-0.05,1])
        xscale = 0.1;yscale = 0.2;
        makeTSscaleBar(gca,"upsidedown",true,"xfrac",1/2,"yFrac",1/2,"lefty",false,...
            "xVal",xscale,"xText",[num2str(1000*xscale),' ms'],...
            "yVal",yscale,"yText",[num2str(yscale),' ',greek_char("Delta"),'F/F'],...
            "font",'arial','fontSize',10)
        % spike position and colors
        spikes_plt = {0,-0.09:0.01:-0.01};spike_cols = {[0,0,0],[0.8,0.8,0.8]};
        cellfun(@(y,blks) arrayfun(@(x) plot([x,x],ylim,'k--','Color',blks,'LineWidth',0.4),y),spikes_plt,spike_cols);
        plot(xlim,[0,0],'k--','LineWidth',2);
        axis off;
        title({'Normalized and aligned','to last spike'},'FontName','arial','FontSize',12)
        set(gca,'FontName','arial','fontsize',10)
    end
    
    % Now fitting exponential components
    starts = [0.2,-30,0.01,-1];
    for trial = 1:size(normF,2)
        % Get fits and check which model was best
        [models,gofs,maxIdx] = fitDecayForGCaMPcell2(t(:,trial),normF(:,trial),starts);
        best_model = models;
        sub_m1 = @(x) best_model.a*exp(best_model.b*x) + best_model.c + best_model.e;
        sub_m2 = @(x) best_model.c*exp(best_model.d*x) + best_model.e;

        % load the data from the fit structure into a matrix sized:
        % bouton x trial
        every_model{targBouton,trial} = best_model;
        
        % Tiles for fits if target bouton
        if targBouton==bouton2show
            t_fits.Layout.Tile = 2;
            nexttile(t_fits);hold on;
            xlims = [-0.01,0.8];
            % add fit tile
            thisT = t(:,trial)-t(maxIdx);
            sm_F = smoothdata(normF(:,trial),"movmean",9);
            plot(thisT,sm_F,'Color',cmap(trial,:),'LineWidth',1.8);
            %plot(thisT(maxIdx:end),best_model(thisT(maxIdx:end)))
            set(gca,'xlim',xlims)
            % Now adding on the fits
            pad = 0.01; %how much to show to either side of the exp contributor
            t_change = -1/best_model.b*4;
            t1_idx = thisT>0 & thisT<=t_change + pad;t2_idx = thisT>t_change - pad;
            plot(thisT(t1_idx),sub_m1(thisT(t1_idx)),'color',[spike_cols{1},0.8],'LineWidth',1.5);
            plot(thisT(t2_idx),sub_m2(thisT(t2_idx)),'Color',[spike_cols{2},0.9],'LineWidth',1.5);
            plot(xlim,[best_model.e,best_model.e],'k--','LineWidth',2)
            plot([0,0],ylim,'k--')
            yl = ylabel([num2str(length(spikes{trial})),' spike']);
            yl.Visible = "on";
            yl.Position = [yl.Position(1) + 0.06, yl.Position(2), yl.Position(3)];
            axis off;
            % Adding the text descriptions
            perc1 = (best_model.a + best_model.e)/(best_model.a + best_model.c + best_model.e)*100;
            perc2 = (best_model.c + best_model.e)/(best_model.a + best_model.c + best_model.e)*100;            
            tau1 = -1/best_model.b*1000;tau2 = -1/best_model.d*1000;
            txt1 = {['\tau_1 = ',num2str(tau1,'%.0f'),' ms, ',num2str(perc1,2),'%'],...
                ['\color[rgb]{0.6,0.6,0.6}\tau_2 = ', num2str(tau2,'%.0f'),' ms']};
            text(mean(xlim)*0.3,max(ylim)*0.7,txt1)

        end
        
    end
end

%% Plot for panel D
% Collect and plot summary statistics from the models
tau1s = cellfun(@(x) -1/x.b*1000,every_model);
tau2s = cellfun(@(x) -1/x.d*1000,every_model);
perc2s = cellfun(@(x) 100*(x.c + x.e)/(x.a + x.c + x.e),every_model);

% Add plots
ticklengths = [0.04,0.02];
t_summary.Layout.Tile = 3;
nexttile(t_summary);hold on;
% tau1
plot(repmat([1,2,10],size(tau1s,1),1)',tau1s',"Color",[spike_cols{1},0.5],"LineWidth",0.3);
plot([1,2,10],mean(tau1s,1),"Color",spike_cols{1},"LineWidth",1.5)
arrayfun(@(x,y1,y2) plot([x,x],[y1,y2],"Color",spike_cols{1},"LineWidth",1),[1,2,10],mean(tau1s,1)+sem(tau1s,[],1),mean(tau1s,1)-sem(tau1s,[],1))
ylabel('\tau_1 (ms)')
set(gca,'TickDir','out','LineWidth',1,'TickLength',ticklengths,...
    'fontname','arial','fontsize',10,'xlim',[0,11],'xtick',[1,2,10],'XTickLabel',[])
% tau 2
nexttile(t_summary);hold on;
plot(repmat([1,2,10],size(tau2s,1),1)',tau2s',"Color",[spike_cols{2}],"LineWidth",0.3);
plot([1,2,10],mean(tau2s,1),"color",spike_cols{2},"LineWidth",2)
arrayfun(@(x,y1,y2) plot([x,x],[y1,y2],"Color",spike_cols{2},"LineWidth",1),[1,2,10],mean(tau2s,1)+sem(tau2s,[],1),mean(tau2s,1)-sem(tau2s,[],1))
ylabel('\tau_2 (ms)')
set(gca,'TickDir','out','LineWidth',1,'TickLength',ticklengths,...
    'fontname','arial','fontsize',10,'xlim',[0,11],'xtick',[1,2,10],'XTickLabel',[])
% perc2
nexttile(t_summary);hold on;
plot(repmat([1,2,10],size(perc2s,1),1)',perc2s',"Color",[spike_cols{2}],"LineWidth",0.3);
plot([1,2,10],mean(perc2s,1),"color",spike_cols{2},"LineWidth",2)
arrayfun(@(x,y1,y2) plot([x,x],[y1,y2],"Color",spike_cols{2},"LineWidth",1),[1,2,10],mean(perc2s,1)+sem(perc2s,[],1),mean(perc2s,1)-sem(perc2s,[],1))
ylabel('% from \tau_2')
set(gca,'TickDir','out','LineWidth',1,'TickLength',ticklengths,...
    'xtick',[1,2,10],'xlim',[0,11],...
    'fontname','arial','fontsize',10)
xlabel('spike number')

saveFigureOutputs("supp_figure1","suppfigure1_A_to_D",ff);
end

function [models,gofs,maxIdx] = fitDecayForGCaMPcell2(t,F,st)
%%%
% This is an update to the original in which I consider more models in the
% context of the 8f dataset
%
%   Inputs:
%       t - time vector
%       F - Fluorescence vector
%       st - initialization of the exp2 fit params
%
%   Outputs:
%       fp - fit object of type a*exp(b*t) + c*exp(d*t) + e

%nargs
if nargin<3
    st = [0.7,-3,0.2,-0.1];
end

% Defining the model
exp2_b = fittype(@(a,b,c,d,e,t) a*exp(b*t) + c*exp(d*t) + e,'independent','t');

% Get max from smoothed data
F_smooth = smooth(F,9);
[~,maxIdx] = max(F_smooth);
lastIdx = find(t-t(maxIdx)>1.9,1)-1;
if isempty(lastIdx);lastIdx = length(F)-maxIdx;end

% Init and bounds for exp1 or exp2
ub2 = [inf,0,inf,-0.3];
ub2_b = [ub2,0.015];
lb2 = [0,-inf,0,st(2)];
lb2_b = [lb2,-0.005];
st2 = st;
st2_b = [st2,0];


tt = t(maxIdx:lastIdx)-t(maxIdx);
FF = F_smooth(maxIdx:lastIdx);%
weights = ones(1,length(FF));

% Model fits
[fp2_b,fp2_b_gof] = fit(tt,FF,exp2_b,'start',st2_b,'upper',ub2_b,'lower',lb2_b,'weights',weights);

% Setting up model comparisons using adjrsq
gofs = fp2_b_gof.adjrsquare;
models = fp2_b;


end
