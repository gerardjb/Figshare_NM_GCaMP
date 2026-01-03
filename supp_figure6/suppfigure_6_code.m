function suppfigure_6_code
%%%
% Plots of model fits to stopped flow and bouton data with model states
% separated by contribution type as in the indicated figure.
%%%

% Close any open plots
close all

% Collect data files
d = fileparts(mfilename("fullpath"));
sf_data = fullfile(d,"..","Shared_data","stoppedFlowTraces.mat");
bouton_data = fullfile(d,"..","Shared_data","gDbase.mat");
f_s = ["best_G6f_params.json",...
    "best_jG7f_params.json",...
    "best_jG8f_params.json"];
consts = ["GCaMP6f","jGCaMP7f","jGCaMP8f"];

% Figure setups
% sf_rise
sizer_sf = [4.2,3.4];
f_sf_rise = figure;
set(f_sf_rise,'Paperunits','inches',...
    'Papersize',sizer_sf,...
    'Paperposition',[0,0,sizer_sf],...
    'Units','inches',...
    'Position',[1,1,sizer_sf]);
f_sf_decay = figure;
set(f_sf_decay,'Paperunits','inches',...
    'Papersize',sizer_sf,...
    'Paperposition',[0,0,sizer_sf],...
    'Units','inches',...
    'Position',[1,1,sizer_sf]);
tile_outer_sf_rise = tiledlayout(f_sf_rise,1,3,"TileSpacing","loose");
tile_outer_sf_decay = tiledlayout(f_sf_decay,1,3,"TileSpacing","loose");
sf_tilesets = {tile_outer_sf_rise,tile_outer_sf_decay};
% bouton
sizer_bouton = [4.3,3.4];
f_bouton = figure;
set(f_bouton,'Paperunits','inches',...
    'Papersize',sizer_bouton,...
    'Paperposition',[0,0,sizer_bouton],...
    'Units','inches',...
    'Position',[1,1,sizer_bouton]);
tile_outer_bouton = tiledlayout(f_bouton,1,3,"TileSpacing","loose");
% bouton states
%sizer_bouton_states = [4.3,3.4];
f_bouton_states = figure;
set(f_bouton_states,'Paperunits','inches',...
    'Papersize',sizer_bouton,...
    'Paperposition',[0,0,sizer_bouton],...
    'Units','inches',...
    'Position',[1,1,sizer_bouton]);
tile_outer_bouton_states = tiledlayout(f_bouton_states,1,3,"TileSpacing","loose");

%Plots
% colormap
m_col = [validatecolor(pickGCaMPcolorsMS('biophys_{MC')),0.8];
cmap = [hex2rgb(pickGCaMPcolorsMS('G6f'));...
    hex2rgb(pickGCaMPcolorsMS('jG7f'));...
    hex2rgb(pickGCaMPcolorsMS('jG8f'))];
state_cmap = [hex2rgb(pickGCaMPcolorsMS('fast'));...
    hex2rgb(pickGCaMPcolorsMS('slow'));...
    hex2rgb(pickGCaMPcolorsMS('blank'))];
% lines and text
lin_wid_data = 0.8;
lin_wid_fit = 1.3;
txt_size = 10;
ticklengths = [0.03,0.003];
% limits
xlims_sf = [0,400];
xtick_sf = [0,200,400];
ylims_sf = {[0,0.6],[0,0.9],[0,0.6];...
    [0,1],[0,1],[0,1]};%appropriate ylims for the different constructs
bouton_xlim = [-50,300];
% scale bars
bouton_xval = 100;
bouton_yval = [0.5,0.7,0.2];


% Data handling
% states
fast_states = [3,4];
slow_states = [6,7,9];
non_states = [5];
state_types = {fast_states,slow_states,non_states};
state_names = {'Fast fluorescent','Slow fluorescent',{'Slow,','non-fluorescent'}};
state_col_names = ["fast","slow","blank"];
% SF trace selection
goodTrace = {[6,1],[6,1],[6,1]};
% Bouton fits
spikes = {0,[0,10],[0,20],[0,50],[0,100]};

%% Looping over constructs
% General data handling
% load sf
load(sf_data,"processedTraces");
% load bouton data
load(bouton_data,"gData");


for i_const = 1:3
    % Set GCaMP parameters
    json_out = jsondecode(fileread(fullfile(d,f_s(i_const))));
    Gparams = json_out.indicator.Gparams;
    const_idx = find({processedTraces{1}.const}==consts(i_const));


    %% Stopped flow fig stuff
    % Loop over the rise and decay trace
    for i_dir = 1:2
        % this data
        pts = processedTraces{i_dir}(const_idx).logSelectPts;
        t = processedTraces{i_dir}(const_idx).time(pts,goodTrace{i_const}(i_dir));
        F = processedTraces{i_dir}(const_idx).traces(pts,goodTrace{i_const}(i_dir));
        ca = processedTraces{i_dir}(const_idx).calcium(goodTrace{i_const}(i_dir))*10^-9*Gparams(end);%with conversion to M and alpha factor from parameter set
        if i_dir == 1;ca_vec = [2e-8,ca];elseif i_dir == 2;ca_vec = [1e-5,ca];end
        [sim_F, states, sat_state] = Fitting_function_eig_WD_simple6_wStates(ca_vec,Gparams(1:end-1),t');
        
        % this const tile
        tile_inner_sf = tiledlayout(sf_tilesets{i_dir},5,1,'tilespacing','compact');
        tile_inner_sf.Layout.Tile = i_const;

        % Plots
        % trace overlay
        nexttile(tile_inner_sf,1,[2,1]);hold on;
        plot(t*1000,F,'Color',cmap(i_const,:),'linewidth',lin_wid_data);
        plot(t*1000,sim_F,'Color',m_col,'LineWidth',lin_wid_fit);
        title(consts(i_const),'Color',pickGCaMPcolorsMS(consts(i_const)),'FontName','arial','FontSize',10);
        set(gca,'xlim',xlims_sf,'xtick',xtick_sf,'xticklabels',[],...
            'tickdir','out','ticklength',ticklengths,'linewidth',1);
        ylabel('Normalized F','FontName','arial','FontSize',10)
        % states
        % fast
        nexttile(tile_inner_sf,3,[1,1]);hold on;
        plot(t*1000,sum(states(fast_states,:),1)./sat_state,...
            'color',pickGCaMPcolorsMS('fast'),'linewidth',lin_wid_fit);
        set(gca,'xlim',xlims_sf,'xtick',xtick_sf,'xticklabels',[],'ylim',ylims_sf{i_dir,i_const},...
            'tickdir','out','ticklength',ticklengths,'linewidth',1);
        if i_const==1
            text(max(xlim),mean(ylim),"Fast fluorescent",...
                'color',pickGCaMPcolorsMS('fast'),"HorizontalAlignment","center","FontSize",10,'FontName','arial');
        end
        % slow
        nexttile(tile_inner_sf,4,[1,1]);hold on;
        plot(t*1000,sum(states(slow_states,:),1)./sat_state,...
            'color',pickGCaMPcolorsMS('slow'),'linewidth',lin_wid_fit);
        if i_const==1;ylabel({'State','occupancy'},'fontsize',10,'fontname','arial');end
        set(gca,'xlim',xlims_sf,'xtick',xtick_sf,'xticklabels',[],'ylim',ylims_sf{i_dir,i_const},...
            'tickdir','out','ticklength',ticklengths,'linewidth',1);
        if i_const==1
            text(max(xlim),mean(ylim),"Slow fluorescent",...
                'color',pickGCaMPcolorsMS('slow'),"HorizontalAlignment","center","FontSize",10,'FontName','arial');
        end
        % non
        nexttile(tile_inner_sf,5,[1,1]);hold on;
        plot(t*1000,sum(states(non_states,:),1),.../sat_state,...
            'color',pickGCaMPcolorsMS('blank'),'linewidth',lin_wid_fit);
        set(gca,'xlim',xlims_sf,'xtick',xtick_sf,'xticklabelrotation',0,'ylim',[0,1],...
            'tickdir','out','ticklength',ticklengths,'linewidth',1);
        if i_const==1
            text(max(xlim),mean(ylim),{"Slow","non-fluorescent"},...
                'color',pickGCaMPcolorsMS('blank'),"HorizontalAlignment","center","FontSize",10,'FontName','arial');
        end

    end% i_dir - rise or decay

    %% Bouton figure
    % tile
    tile_inner_bouton = tiledlayout(tile_outer_bouton,5,1,"TileSpacing","none");
    tile_inner_bouton.Layout.Tile = i_const;

    % Plot format
    bouton_ylim = [-0.02,max(max(gData(i_const).PPRtraces.normF))+0.05];

    % Loop over spikes for plotting
    for i_spike = 1:length(spikes)
        nexttile(tile_inner_bouton,i_spike,[1,1]);hold on;
        plot(gData(i_const).PPRtraces.time(:,i_spike)*1000,gData(i_const).PPRtraces.normF(:,i_spike),...
            'color',cmap(i_const,:),'linewidth',lin_wid_data);
        plot(gData(i_const).PPRtraces.time(:,i_spike)*1000,gData(i_const).PPRtraces.dff_hat(:,i_spike),...
            'color',m_col,'linewidth',lin_wid_fit);
        arrayfun(@(x) plot([x,x],bouton_ylim,'k--','linewidth',0.3),spikes{i_spike});
        plot(bouton_xlim,[0,0],'k--','LineWidth',1);
        axis off;
        set(gca,'xlim',bouton_xlim,'ylim',bouton_ylim)
        if i_spike==1
            title(consts(i_const),'Color',cmap(i_const,:),'FontName','arial','FontSize',10);
            makeTSscaleBar(gca,lefty=false,upsidedown=true,...
                xFrac=1/2,xVal=bouton_xval,xText=[num2str(bouton_xval),' ms'],xPush=0.05,...
                yFrac=1/2,yVal=bouton_yval(i_const),yText=[num2str(bouton_yval(i_const)),' ',greek_char("Delta"),'F/F'],...
                font='arial',fontSize=txt_size);
        end
    end

    %% Bouton states fig stuff
    % Tile
    tile_inner_states = tiledlayout(tile_outer_bouton_states,length(state_types),1,'tilespacing','tight');
    tile_inner_states.Layout.Tile = i_const;

    % Loop over spikes for plotting data
    % General data handling
    if i_const==3;dt=200e-6;else;dt=20e-6;end
    time = gData(i_const).PPRtraces.time(:,1);
    sim_time = time(1):dt:time(end);
    state_sum =  mean(sum(gData(i_const).PPRtraces.states{1},2));
    % set limits
    max_f_states = max(cellfun(@(y) ...
        max([max(sum(y(:,slow_states),2)),max(sum(y(:,fast_states),2))]),...
        gData(i_const).PPRtraces.states))/state_sum;
    ylims_states = {[0,max_f_states],[0,max_f_states],[0,1]};

    % loop over state types
    for i_state = 1:length(state_types)
        % state type data handling
        states = cellfun(@(y) ...
            sum(interp1(sim_time,y(:,state_types{i_state}),time),2),...
            gData(i_const).PPRtraces.states,'UniformOutput',false);
        states = cat(2,states{:});

        % plot into tile
        nexttile(tile_inner_states,i_state,[1,1]);hold on;
        plot(time*1000,states./state_sum,'color',state_cmap(i_state,:),'linewidth',lin_wid_fit);
        if i_state<3
            set(gca,'xtick',[0,150,300],'xticklabels',[],'ylim',ylims_states{i_state},...
                'tickdir','out','ticklength',ticklengths,'linewidth',1);
        else
            set(gca,'xtick',[0,150,300],'xticklabelrotation',0,'ylim',ylims_states{i_state},...
                'tickdir','out','ticklength',ticklengths,'linewidth',1);
        end
        if i_state==1
            title(consts(i_const),'color',cmap(i_const,:),"FontName","arial","FontSize",10);
        end
        if i_const==1
            text(max(xlim),mean(ylim),state_names{i_state},...
                'color',pickGCaMPcolorsMS(state_col_names(i_state)),"HorizontalAlignment","center","FontSize",10,'FontName','arial');
        end
        set(gca,'fontname','arial','fontsize',10)
    end

end

% Finish plots
% SF
title(tile_outer_sf_rise,['Model fit (  ) 0.05 step to 0.5 ',greek_char("mu"),'M  rise'],'FontSize',12,'FontName','arial');
xlabel(tile_outer_sf_rise,'Time (ms)','fontname','arial','fontsize',10)
title(tile_outer_sf_decay,['Model fit (  ) from 10 to 0.01 ',greek_char("mu"),'M  decay'],'FontSize',12,'FontName','arial');
xlabel(tile_outer_sf_decay,'Time (ms)','fontname','arial','fontsize',10)
% bouton fits
title(tile_outer_bouton,{'Model fit (  ) to bouton','Paired protocol'},'FontSize',12,'FontName','arial')
% bouton states
title(tile_outer_bouton_states,{'Model states,','Paired protocol'},'FontSize',12,'FontName','arial');
xlabel(tile_outer_bouton_states,'Time (ms)',"fontname",'arial','fontsize',10);
ylabel(tile_outer_bouton_states,'State occupancy',"fontname",'arial','fontsize',10);

