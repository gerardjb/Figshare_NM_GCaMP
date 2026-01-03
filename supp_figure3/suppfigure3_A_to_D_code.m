function suppfigure3_A_to_D_code
%%%
% Plots of effects of magnesium and ionic strength on steady-state
% fluorescence properties as in the indicated figure
%%%

% Close any open plots
close all

% Open data files
d = fileparts(mfilename("fullpath"));
t_names = ["20220301_KMOPS_Internal_MG_Rf study.ods",...
    "20220301_KMOPS_Internal_MG_Rf study_2.ods"];
T = readtable(fullfile(d,t_names(1)),'VariableNamingRule','preserve');
T2 = readtable(fullfile(d,t_names(2)),'VariableNamingRule','preserve');

% Data setup
% Get wavelengths and column heads
lambda = T{:,1};
headers = T.Properties.VariableNames;
headers2 = T2.Properties.VariableNames;
% Strip all lambda columns
T(:,cellfun(@(x) contains(x,'X'),headers)) = [];headers(cellfun(@(x) contains(x,'X'),headers)) = [];
T2(:,cellfun(@(x) contains(x,'X'),headers2)) = [];headers2(cellfun(@(x) contains(x,'X'),headers2)) = [];
bckgnd = mean(T{:,cellfun(@(x) contains(x,'blank'),headers)},2);

% Fix any textual typos in the column headers
patStart = {'Int0','Int0.5','Int1','Int1.5','Int2'};
for i = 1:length(patStart)
    for ii = 1:length(headers)
        targStr = [patStart{i},'_'];
        p = strfind(headers{ii},targStr);
        if p
            headers{ii} = [headers{ii}(1:p-2+length(targStr))...
                ,'Mg',headers{ii}(p-1+length(targStr):end)];
        end
    end
end

% Building Rf matrix as Const x Buffer x Temp
Const = {'G6f','jG7f','jG8f'};
Buffer = {'KMOPS','Int0Mg','Int0.5Mg','Int1Mg','Int1.5Mg','Int2Mg'};

Rfs = cell(length(Const),length(Buffer),2);
apoCts = cell(length(Const),length(Buffer),2);
satCts = cell(length(Const),length(Buffer),2);
Traces = cell(length(Const),length(Buffer),2);

for i=1:length(Const)
    goodConst = cellfun(@(x) contains(x,Const{i}),headers);
    goodConst2 = cellfun(@(x) contains(x,Const{i}),headers2);
    for j=1:length(Buffer)
        goodBuffer = cellfun(@(x) contains(x,Buffer{j}),headers);
        goodBuffer2 = cellfun(@(x) contains(x,Buffer{j}),headers2);
        for k = 1:2
            if k==1
                goodTemp = cellfun(@(x) ~contains(x,'37C'),headers);
                goodTemp2 = cellfun(@(x) ~contains(x,'37C'),headers2);
            elseif k==2
                goodTemp = cellfun(@(x) contains(x,'37C'),headers);
                goodTemp2 = cellfun(@(x) contains(x,'37C'),headers2);
            end
            thisApoSpec = [T{:,goodConst&goodBuffer&goodTemp&cellfun(@(x) contains(x,'0mMCa'),headers)},...
                T2{:,goodConst2&goodBuffer2&goodTemp2&cellfun(@(x) contains(x,'0mMCa'),headers2)}]-bckgnd;
            thisSatSpec = [T{:,goodConst&goodBuffer&goodTemp&cellfun(@(x) contains(x,'1.7mMCa'),headers)},...
                T2{:,goodConst2&goodBuffer2&goodTemp2&cellfun(@(x) contains(x,'1.7mMCa'),headers2)}]-bckgnd;
            
            thisApo = sum(thisApoSpec(lambda>=500&lambda<=550,:));
            thisSat = sum(thisSatSpec(lambda>=500&lambda<=550,:));
            Rfs{i,j,k} = thisSat./...
                thisApo;
            apoCts{i,j,k} = thisApo;
            satCts{i,j,k} = thisSat;
            Traces{i,j,k} = [thisApoSpec,thisSatSpec];

        end
    end%j(Buffer)
end%i(Const)

x = 1;

%% Make figure
%Full layout
sizer = [9,4];
hF = figure;hold on;set(gca,'tickdir','out');
set(hF,'Paperunits','inches',...
    'Papersize',sizer,...
    'Paperposition',[0,0,sizer],...
    'Units','inches',...
    'Position',[2,2,sizer]);
%Nesting of panels
%Outer
nRows = 5;
nCols = 7;
tOut = tiledlayout(hF,nRows,nCols);
%Inner for spectra, summed counts, and Rf effects
hAx = nexttile(tOut,[nRows,2]);hAx.Visible = 'off';
hAx2 = nexttile(tOut,3,[nRows-2,nCols-2]);hAx2.Visible = 'off';
hAx3 = nexttile(tOut,(nRows-2)*nCols+3,[2,nCols-2]);hAx3.Visible = 'off';
hP = uipanel(hF, 'Position', hAx.OuterPosition, 'BorderWidth', 0.1,'backgroundcolor',[1,1,1],'bordertype','none');
hP2 = uipanel(hF,'Position', hAx2.OuterPosition, 'BorderWidth', 0.1,'backgroundcolor',[1,1,1],'bordertype','none');
hP3 = uipanel(hF,'Position', hAx3.OuterPosition, 'BorderWidth', 0.1,'backgroundcolor',[1,1,1],'bordertype','none');
tIn = tiledlayout(hP,3,2,'TileSpacing','compact','Padding','compact');
tIn2 = tiledlayout(hP2,1,2);
tIn3 = tiledlayout(hP3,1,3,'TileSpacing','compact','Padding','compact');

%Spectra panels
%Get axes limits for spectra
yMax = max(cellfun(@(x) max(x(:)),Traces),[],'all');
BufferSub = [1,length(Buffer)];
linStyle = {'--','-'};
tit = {'KMOPS',{'Internal +','2 mM Mg^{2+}'}};
for i = 1:length(Const)
    col = pickGCaMPcolorsMS(Const{i});
    for j = 1:2
        nexttile(tIn);hold on;
        for k = 1
            nTraces = size(Traces{i,BufferSub(j),1},2)/2;
            plot(lambda,mean(Traces{i,BufferSub(j),1}(:,1:nTraces),2),...
                'color',col,'linestyle',linStyle{1});
            plot(lambda,mean(Traces{i,BufferSub(j),1}(:,nTraces+1:end),2),...
                'color',col,'linestyle',linStyle{2});
        end%k(Temps)
        %Add title to G6f plots (the top ones)
        if i==1
            title(tit{j});
        end
        %Add construct names
        if j==1
            ylabel(GCaMPalias(Const{i}),'color',col);
            %NOTE: current hard coding
            set(gca,'ytick',[0,2e5,4e5],'yticklabel',{'0','2','4'});
        %remove excess axis labels
        else
            set(gca,'yticklabel','');
        end
        if i~=3
            set(gca,'xticklabel','');
        end
        axis tight;
        
        set(gca,'ylim',[0,yMax])
    end%j(Buffer)
end%i(Const)
xlabel(tIn,'Wavelength (nm)');
ylabel(tIn,'Counts (10^5 photons)');

% Rf panels
cts = {apoCts,satCts};
offset = [-0.08,0,0.08];
ylimEnds = [3e5,4e6];
tit = {'0 \muM Ca^{2+}','saturating Ca^{2+}'};
for i = 1:2
    nexttile(tIn2);hold on;
    for j = 1:length(Const)
        col = pickGCaMPcolorsMS(Const{j});
        avg = cellfun(@mean,cts{i}(j,2:end,1));
        err = cellfun(@std,cts{i}(j,2:end,1));
        plot([1:(length(Buffer)-1)]+offset(j),avg,'Color',col,'marker','.','markersize',8);
        arrayfun(@(x,y,z) plot([x+offset(j),x+offset(j)],...
            [y-z,y+z],'Color',col,'linewidth',1.1),1:(length(Buffer)-1),avg,err);
        if i==1
            text(length(Buffer)-1+2*offset(3),avg(end),Const{j},'color',col);
        end
    end%j(Const)
    title(tit(i))
    xlabel('[Mg^{2+}] (mM)')
    set(gca,'xlim',[0.5,(length(Buffer)-1)+0.5],...
        'xtick',1:(length(Buffer)-1),...
        'xticklabel',[compose('%0.1f',0:0.5:2)],...'K',
        'xticklabelrotation',0,...
        'ylim',[0,ylimEnds(i)],...
        'ytick',[0,ylimEnds(i)/2,ylimEnds(i)],...
        'yticklabels',compose('%0.1f',[0,ylimEnds(i)/2,ylimEnds(i)]/1e5));
end%i (apo/sat)
%xlabel(tIn2,'[Mg^{2+}] (mM)')
ylabel(tIn2,{'Counts', '(10^5 photons)'})

% Effects of different conditions: temperature, ionic strength, magnesium

norm2temp = cell2mat(Rfs(:,:,2))./cellfun(@mean,Rfs(:,:,1));
norm2ion = cellfun(@mean,Rfs(:,2,:))./cellfun(@mean,Rfs(:,1,:));
norm2mg = cellfun(@mean,Rfs(:,3:end,:))./repmat(cellfun(@mean,Rfs(:,1,:)),1,4,1);
expCond = {norm2temp,norm2ion,norm2mg};
expLabels = {{'22^oC','37^oC'},{'KMOPS','Internal'},{'no Mg^{2+}','>0 mM Mg^{2+}'}};
tit = {'Temperature','Ionic strength','Mg^{2+}'};
for i = 1:3
    nexttile(tIn3);hold on;
    for j = 1:length(Const)
        col = pickGCaMPcolorsMS(Const{j});
        avg = mean(expCond{i}(j,:));
        err = std(expCond{i}(j,:));
        %mean experimental condition effect on Rf
        plot([1+offset(j),2+offset(j)],[1,avg],...
            'color',col,'marker','.','markersize',8);
        %Errorbars of experiemental condition effect on Rf
        plot([2+offset(j),2+offset(j)],[avg-err,avg+err],...
            'color',col,'linewidth',1.1);
    end%j(Const)
    set(gca,'ylim',[0,1],'xlim',[0.75,2.25],...
        'xtick',[1,2],'xticklabel',expLabels{i},'xticklabelrotation',0);
    title(tit{i});
end%i(experimental condition)
ylabel(tIn3,{'Dynamic range','(normalized)'});
tIn3.TileSpacing = 'loose';

%% plot dynamic range under various conditions
% figure;
% posf = get(gcf,'position');
% set(gcf,'position',[posf(1:2),posf(3)*0.5,posf(4)]);
sizer = [1.5,3.5];
hF = figure;hold on;set(gca,'tickdir','out');
set(hF,'Paperunits','inches',...
    'Papersize',sizer,...
    'Paperposition',[0,0,sizer],...
    'Units','inches',...
    'Position',[2,2,sizer]);
consts = {'G6f','jG7f','jG8f'};
cols = arrayfun(@(x) hex2rgb(pickGCaMPcolorsMS(consts{x})),1:3,'UniformOutput',false);
cols = cat(1,cols{:});
scatter([1,2,3],[Rfs{1,4,2},Rfs{2,4,2},Rfs{3,4,2}],[20,20,20],cols,'filled');
pos = get(gca,'position');
set(gca,'xlim',[0.5,3.5],'ylim',[0,20],...
    'xtick',1:3,'xticklabel',consts)%,...
    %'position',[pos(1:2),pos(3)*0.5,pos(4)]);

ylabel('R_f')
title('37^oC, [Mg^{2+}] 1mM')