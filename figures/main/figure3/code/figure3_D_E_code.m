function figure3_D_E_code
%%%
% Plots of model fits to bouton data with model states shown as in the
% indicated figure
%%%

% Close any open plots
close all

% Open data files
d = fullfile(fileparts(mfilename("fullpath")),'..','source_data');

% For data selection, naming
consts = ["jGCaMP8f"];
i_const = 3;% i.e., 8f
exps = ["PPRtraces","traces1_2_10"];
% Reconstruct only the plotted trace view from the shared canonical CSVs.
gData = struct;
gData(3).PPRtraces = readBoutonCSV(d,"D_PPRtraces_",5);
gData(3).traces1_2_10 = readBoutonCSV(d,"D_traces1_2__",3);
stateGroups = ["fast_fluorescent","slow_fluorescent","slow_nonfluorescent"];


%-- Data and state handling --
% Bouton fits
spikes = {{0,[0,10],[0,20],[0,50],[0,100]},{[0],[0,10],[0:10:90]}};
% states
fast_states = [3,4];
slow_states = [6,7,9];
non_states = [5];
state_types = {fast_states,slow_states,non_states};
state_names = {'Fast fluorescent','Slow fluorescent',{'Slow,','non-fluorescent'}};
state_col_names = ["fast","slow","blank"];


%-- Figure setups --
% General
% Plot colors
m_col = [validatecolor(pickGCaMPcolorsMS('biophys_{MC')),0.8];
cmap = hex2rgb(pickGCaMPcolorsMS('jG8f'));
state_cmap = [hex2rgb(pickGCaMPcolorsMS('fast'));...
    hex2rgb(pickGCaMPcolorsMS('slow'));...
    hex2rgb(pickGCaMPcolorsMS('blank'))];
% lines and text
lin_wid_data = 0.8;
lin_wid_fit = 1.3;
txt_size = 10;
ticklengths = [0.03,0.003];
bouton_xlim = {[-50,300],[-50,500]};
% scale bars
bouton_xval = 100;
bouton_yval = [0.5,0.7,0.2];

% bouton
sizer_bouton = [4.3,3.4];
f_bouton = figure;
set(f_bouton,'Paperunits','inches',...
    'Papersize',sizer_bouton,...
    'Paperposition',[0,0,sizer_bouton],...
    'Units','inches',...
    'Position',[1,1,sizer_bouton]);
tile_outer_bouton = tiledlayout(f_bouton,1,2,"TileSpacing","loose");

% bouton states
f_bouton_states = figure;
set(f_bouton_states,'Paperunits','inches',...
    'Papersize',sizer_bouton,...
    'Paperposition',[0,0,sizer_bouton],...
    'Units','inches',...
    'Position',[1,1,sizer_bouton]);
tile_outer_bouton_states = tiledlayout(f_bouton_states,1,2,"TileSpacing","loose");

for i_exp = 1:length(exps)
    %% Bouton figure
    % tile
    tile_inner_bouton = tiledlayout(tile_outer_bouton,...
        size(gData(i_const).(exps(i_exp)).normF,2),1,"TileSpacing","none");
    tile_inner_bouton.Layout.Tile = i_exp;

    % Plot format
    bouton_ylim = [-0.02,max(max(gData(i_const).(exps(i_exp)).normF))+0.05];

    % Loop over spikes for plotting
    for i_spike = 1:length(spikes{i_exp})
        % Update inner tile position 
        nexttile(tile_inner_bouton,i_spike,[1,1]);hold on;

        % Plot data, fits
        plot(gData(i_const).(exps(i_exp)).time(:,i_spike)*1000,gData(i_const).(exps(i_exp)).normF(:,i_spike),...
            'color',cmap,'linewidth',lin_wid_data);
        plot(gData(i_const).(exps(i_exp)).time(:,i_spike)*1000,gData(i_const).(exps(i_exp)).dff_hat(:,i_spike),...
            'color',m_col,'linewidth',lin_wid_fit);
        arrayfun(@(x) plot([x,x],bouton_ylim,'k--','linewidth',0.3),spikes{i_exp}{i_spike});
        plot(bouton_xlim{i_exp},[0,0],'k--','LineWidth',1);
        axis off;

        % Plot format
        set(gca,'xlim',bouton_xlim{i_exp},'ylim',bouton_ylim)

        % Add scale bar to upper most plot
        if i_spike==1
            title(consts(1),'Color',cmap,'FontName','arial','FontSize',10);
            makeTSscaleBar(gca,lefty=false,upsidedown=true,...
                xFrac=1/2,xVal=bouton_xval,xText=[num2str(bouton_xval),' ms'],xPush=0.05,...
                yFrac=1/2,yVal=bouton_yval(i_const),yText=[num2str(bouton_yval(i_const)),' ',greek_char("Delta"),'F/F'],...
                font='arial',fontSize=txt_size);
        end
    end

    %% Bouton states figure
    % Tile
    tile_inner_states = tiledlayout(tile_outer_bouton_states,length(state_types),1,'tilespacing','tight');
    tile_inner_states.Layout.Tile = i_exp;

    % Loop over spikes for plotting data
    grouped = readtable(fullfile(d,"Figure3_E_"+exps(i_exp)+"_grouped_states.csv"),...
        'VariableNamingRule','preserve');

    % loop over state types
    for i_state = 1:length(state_types)
        % The grouped CSV holds the existing interpolated state sums.
        % Preserve state amounts; do not renormalize or refit these curves.
        [time,states] = readGroupedState(grouped,stateGroups(i_state));

        % plot into tile
        nexttile(tile_inner_states,i_state,[1,1]);hold on;
%        plot(time*1000,states./state_sum,'color',state_cmap(i_state,:),'linewidth',lin_wid_fit);
        plot(time,states,'color',state_cmap(i_state,:),'linewidth',lin_wid_fit);

        if i_exp==1
            set(gca,'xtick',[0,150,300],...'ylim',ylims_states{i_state},...
                'tickdir','out','ticklength',ticklengths,'linewidth',1);
        else
            set(gca,'xtick',[0,250,500],'xticklabelrotation',0,...'ylim',ylims_states{i_state},...
                'tickdir','out','ticklength',ticklengths,'linewidth',1);
        end
        if i_state==1
            title(consts(1),'color',cmap,"FontName","arial","FontSize",10);
        end
        if i_exp==2
            text(max(xlim),mean(ylim),state_names{i_state},...
                'color',pickGCaMPcolorsMS(state_col_names(i_state)),"HorizontalAlignment","center","FontSize",10,'FontName','arial');
        end

        % Plot format
        set(gca,'fontname','arial','fontsize',10)
        set(gca,'xlim',bouton_xlim{i_exp})
    end

end

saveFigureOutputs("figure3","figure3_D_E");


end

function data = readBoutonCSV(folder,stub,count)
data = struct('time',[],'normF',[],'dff_hat',[]);
for k = 1:count
    files = dir(fullfile(folder,"*_"+stub+string(k)+".csv"));
    assert(numel(files)==1,'Expected exactly one canonical bouton CSV: %s',stub+string(k));
    tbl = readtable(fullfile(files(1).folder,files(1).name),'VariableNamingRule','preserve');
    tbl = sortrows(tbl,'source_row_index');
    if k==1
        data.time = nan(height(tbl),count);
        data.normF = data.time; data.dff_hat = data.time;
    end
    assert(height(tbl)==size(data.time,1),'Bouton CSV row counts differ.');
    data.time(:,k) = tbl.time/1000; % Existing plot converts seconds to ms.
    data.normF(:,k) = tbl.observed;
    data.dff_hat(:,k) = tbl.existing_model_fit;
end
end

function [time,states] = readGroupedState(tbl,group)
rows = tbl(string(tbl.state_group)==group,:);
protocols = unique(rows.protocol_index,'stable');
time = []; states = [];
for k = 1:numel(protocols)
    one = sortrows(rows(rows.protocol_index==protocols(k),:),'time_ms');
    if k==1
        time = one.time_ms;
        states = nan(height(one),numel(protocols));
    else
        assert(isequaln(time,one.time_ms),'Grouped-state CSV time grids differ.');
    end
    states(:,k) = one.state_amount;
end
end
