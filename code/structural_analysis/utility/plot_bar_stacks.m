function [] = plot_bar_stacks(stackData, groupLabels, optfig, axislabs, graphType, filename)
% Plot a set of stacked bars, but group them according to labels provided.
%
% Params: 
%      stackData is a 3D matrix (i.e., stackData(i, j, k) => (Group, Stack, StackElement)) 
%      groupLabels is a CELL type (i.e., { 'a', 1 , 20, 'because' };)
%      optfig is a struct of figure options
%      axislabs is a cell array containing the Axis label names and ticks
%       
%
% Copyright 2011 Evan Bollig (bollig at scs DOT fsu ANOTHERDOT edu)
%  Modified by Yashaswi Mohanty (2020)
%
% 
NumGroupsPerAxis = size(stackData, 1);
NumStacksPerGroup = size(stackData, 2);

if NumStacksPerGroup > 2
    error("ERROR: Please supply two stacks per group.")
end

[~,fontname,~,lw,folder,color,style,marker,~,axfontsize,axlabelfontsize,~] = fn_optfig(optfig);

% Count off the number of bins
groupBins = 1:NumGroupsPerAxis;
MaxGroupWidth = 0.7; % Fraction of 1. If 1, then we have all bars in groups touching
groupOffset = MaxGroupWidth/NumGroupsPerAxis;
f0 = figure('Renderer', 'painters', 'Position', [10 10 700 500]);

% Color the axes black and red
left_color = [0 0 0];
right_color = [1 0 0];
set(f0,'defaultAxesColorOrder',[right_color; left_color]);
hold on; 
for i=1:NumStacksPerGroup
    
    % Separate axes for rations and prices
    if i == 1
        yyaxis left
        ylabel(axislabs{1},'FontName', fontname, 'FontSize', axlabelfontsize);
        yticks(axislabs{2})
    else
        yyaxis right
        ylabel(axislabs{4}, 'FontName', fontname, 'FontSize', axlabelfontsize);
        yticks(axislabs{5})
    end
    
    Y = squeeze(stackData(:,i,:));
 
    % Center the bars:
    
    internalPosCount = i - ((NumStacksPerGroup+1) / 2);
    
    % Offset the group draw positions:
    groupDrawPos = (internalPosCount)* (groupOffset) + groupBins;
    
    % Color the graphs and separate price by color for price > 6.2
    h(i,:) = bar(Y, 'stacked');           
    
    set(h(i,:),'BarWidth',groupOffset);
    set(h(i,:),'XData',groupDrawPos);
    
    h(i,2).FaceColor = 'flat';
    h(i,2).CData = [0.9 0.9 0.9];
    
        
end

% Make opp cost border thick
set(h(2,:),'LineWidth', 2.5);

% Set axis limits
yyaxis left
ylim(axislabs{3})

yyaxis right
ylim(axislabs{6})

xlim([groupDrawPos(1)-0.5, groupDrawPos(end)+0.25])

hold off;

if strcmp(graphType,'regime')
    if stackData(NumGroupsPerAxis,NumStacksPerGroup,2) > 0 
        legend([h(1,1),h(2,1),h(2,2)],'Ration',...
            'Price',...
            'Opportunity cost of water',...
            'Location','southoutside',...
            'Orientation','horizontal',...
            'FontName','Times New Roman',...
            'fontsize',24);
    else
        legend([h(1,1),h(2,1)],'Ration',...
            'Price',...
            'Location','southoutside',...
            'Orientation','horizontal',...
            'FontName','Times New Roman',...
            'fontsize',24);
    end
else 
    legend([h(1,1),h(2,1)],'Prop. of farmers who gain','Mean loss if loss', ...
        'Location','southoutside',...
            'Orientation','vertical',...
            'FontName','Times New Roman',...
            'fontsize',24);
end

legend boxoff;

% Set tick mode
set(gca,'XTickMode','manual');
set(gca,'XTick',groupBins);
set(gca,'LineWidth',2.5);
set(gca,'XTickLabelMode','manual');
%set(gca, 'XTickLength', [0 0]);
set(gca,'XTickLabel',groupLabels);
set(gca,'FontName',fontname,'FontSize',26)
%set(gca, 'Xcolor', 'black')

fig = gcf;
fig.PaperPositionMode = 'auto';
fig_pos = fig.PaperPosition;
fig.PaperSize = [fig_pos(3) fig_pos(4)];
print(f0,'-dpdf','-painters','-noui','-r600', [folder, filename, '.pdf']);
end 
