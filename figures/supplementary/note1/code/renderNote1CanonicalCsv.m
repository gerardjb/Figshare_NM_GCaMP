function fig = renderNote1CanonicalCsv(whichPart,outputDirectory)
% Publication rendering; no data fitting, kernels or simulations run.
% A_D curves are explicitly in published PDF display coordinates, not invented
% full-precision physical fit values. E_G arrays retain native physical units.
base=fileparts(mfilename('fullpath'));d=fullfile(base,'..','source_data');
fmt=jsondecode(fileread(fullfile(base,'note1_display_format.json')));
whichPart=upper(string(whichPart));
if whichPart=="A_D"
    T=readtable(fullfile(d,'A_D_reference_plot_paths.csv'),'TextType','string');
    labels=readtable(fullfile(d,'C_reference_fit_labels.csv'),'TextType','string');
    fig=figure('Units','inches','Position',[1,1,8.5,4], ...
        'PaperUnits','inches','PaperSize',[8.5,4],'PaperPosition',[0,0,8.5,4]);
    ax=axes(fig,'Position',[0.03,0.06,0.94,0.90]);hold(ax,'on');
    for i=1:numel(fmt.A_D.path_styles)
        s=fmt.A_D.path_styles(i);select=T.series_id==s.id;
        color=s.color;lw=max(0.3,min(s.width,1.5));
        % Individual structure trajectories retain the original gray appearance.
        if string(s.panel)=="d" && lw<0.7;color=.65+.35*color;end
        plot(ax,T.reference_plot_x(select),T.reference_plot_y(select), ...
            'Color',color,'LineWidth',lw,'LineStyle',s.line_style,'Tag','referenceDisplayPath');
    end
    axis(ax,[10,550,290,560]);axis(ax,'off');
    labelText(ax,85,548,'1-2-10 protocol',9,'center');
    labelText(ax,85,416,{'Normalized and aligned','to last spike'},9,'center');
    y=[518,430,351];y2=[501,413,334];labelY=[500,416,337];
    for i=1:3
        labelText(ax,231,y(i),sprintf('\\tau_1 = %d ms, %d%%',labels.tau1_ms(i),labels.fast_component_percent(i)),9,'left');
        h=labelText(ax,231,y2(i),sprintf('\\tau_2 = %d ms',labels.tau2_ms(i)),9,'left');h.Color=[.6,.6,.6];
        h=labelText(ax,183,labelY(i),sprintf('%d spike',labels.spikes(i)),8,'center');h.Rotation=90;
    end
    % The graphical rulers retain the published scale meanings. Their placement
    % is typography only; scientific curves above come solely from the CSV.
    for y=[499.374,365.874]
        labelText(ax,95.219,y+6,'100 ms',8,'center');
        labelText(ax,106.106,y-8.143,['0.2 ',char(916),'F/F'],8,'left');
    end
    h=labelText(ax,355,517,'\tau_1 (ms)',8,'center');h.Rotation=90;
    h=labelText(ax,355,438,'\tau_2 (ms)',8,'center');h.Rotation=90;
    h=labelText(ax,355,361,'% from \tau_2',8,'center');h.Rotation=90;
    tickValues(ax,[492.115,507.477,522.839,538.2],[40,60,80,100]);
    tickValues(ax,[405.22,437.72,470.22],[0,2000,4000]);
    tickValues(ax,[328.22,360.97,393.72],[0,20,40]);
    tickX=[409.231,419.413,500.868];spikes=[1,2,10];
    for i=1:3;labelText(ax,tickX(i),319,num2str(spikes(i)),8,'center');end
    labelText(ax,455,300,'spike number',9,'center');
    stem='suppfigure1_A_to_D';
else
    assert(whichPart=="E_G",'Note1:part','Expected A_D or E_G.');
    T=readtable(fullfile(d,'E_G_confirmed_native_series.csv'),'TextType','string');
    fig=figure('Units','inches','Position',[1,1,8.5,4.2], ...
        'PaperUnits','inches','PaperSize',[8.5,4.2],'PaperPosition',[0,0,8.5,4.2]);
    positions=[.76,.12,.14,.28;.76,.61,.14,.28;.50,.12,.14,.28; ...
        .50,.61,.14,.28;.28,.12,.14,.28;.06,.12,.14,.28; ...
        .28,.61,.14,.28;.06,.61,.14,.28];
    for a=1:8
        f=fmt.E_G.axes(a);ax=axes(fig,'Position',positions(a,:));hold(ax,'on');handles=gobjects(1,numel(f.styles));
        for k=numel(f.styles):-1:1
            s=f.styles(k);select=T.axis_id==a & T.series_id==s.series_id;
            assert(any(select),'Note1:emptyCurve','Canonical curve is missing.');x=T.x(select);y=T.y(select);
            if string(s.type)=="scatter"
                handles(k)=scatter(ax,x,y,22,'k',s.Marker,'LineWidth',.75,'MarkerFaceColor','none','Tag','canonicalNumericSeries');
            else
                handles(k)=plot(ax,x,y,'Color',s.Color,'LineStyle',s.LineStyle, ...
                    'LineWidth',min(s.LineWidth,.75),'Tag','canonicalNumericSeries');
            end
        end
        set(ax,'XLim',f.xlim,'YLim',f.ylim,'XScale',f.xscale,'YScale',f.yscale, ...
            'FontName','arial','FontSize',8,'TickDir','out');
        if a<=2
            xlabel(ax,f.xlabel,'FontSize',8);ylabel(ax,f.ylabel,'FontSize',8);set(ax,'XTick',[1,1.5]);
            if a==2
                circle=find(arrayfun(@(s)string(s.Marker)=="o",f.styles));
                triangle=find(arrayfun(@(s)string(s.Marker)=="^",f.styles));
                lg=legend(ax,handles([circle,triangle]),{'Bouton','Somata'},'Location','none','FontSize',8);
                lg.Position=[.91,.73,.085,.12];lg.Box='off';ax.Position=positions(a,:);
                title(lg,'Structure','FontSize',9);
            end
        else
            axis(ax,'off');title(ax,f.title,'FontName','arial','FontSize',9,'FontWeight','normal');
            for k=1:numel(f.texts)
                q=f.texts(k);st=string(q.String);
                if isempty(st)||all(strlength(st)==0)||string(q.Visible)~="on";continue;end
                if isequal(st,string(f.title))||isequal(st,string(f.xlabel))||isequal(st,string(f.ylabel));continue;end
                ha='left';va='middle';if any(contains(st,'ms'));ha='center';va='bottom';end
                text(ax,q.Position(1),q.Position(2),q.String,'FontName','arial','FontSize',8, ...
                    'HorizontalAlignment',ha,'VerticalAlignment',va);
            end
        end
    end
    annotation(fig,'textbox',[.02,.91,.45,.06],'String','Linear kernel supra-linear example', ...
        'EdgeColor','none','HorizontalAlignment','center','FontName','arial','FontSize',10);
    annotation(fig,'textbox',[.02,.42,.45,.06],'String','Linear kernel saturating example', ...
        'EdgeColor','none','HorizontalAlignment','center','FontName','arial','FontSize',10);
    stem='suppfigure1_E_to_G';
end
if nargin>1 && ~isempty(outputDirectory)
    if ~isfolder(outputDirectory);mkdir(outputDirectory);end
    stem=fullfile(outputDirectory,stem);
    exportgraphics(fig,[stem,'.pdf'],'ContentType','vector','BackgroundColor','white');
    exportgraphics(fig,[stem,'.png'],'Resolution',150,'BackgroundColor','white');
    savefig(fig,[stem,'.fig']);
else
    saveFigureOutputs('supp_figure1',stem,fig);
end
end

function h=labelText(ax,x,y,label,size,align)
h=text(ax,x,y,label,'FontName','arial','FontSize',size, ...
    'HorizontalAlignment',align,'VerticalAlignment','middle','Interpreter','tex');
end

function tickValues(ax,y,values)
for i=1:numel(y);labelText(ax,391,y(i),num2str(values(i)),8,'right');end
end
