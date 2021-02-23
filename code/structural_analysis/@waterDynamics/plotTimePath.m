function plotTimePath(obj, type, both, T, filename, optfig)
%% Plot the time path of water extracted by the farmer
% 
% INPUTS:
%   type: One of {'power','water','depth'}
%   both: Plot both pigouvian and rationing regime
%   series: cell array of series to plot
%   T: vector of time
%   W_t: Vector of water extraction ('000 liter/yr)
%   optfig: Struct of figure paramaters
%   sdo: Name of the SDO
% 
% OUTPUTS:
%       
%

%% Get data

% Check if there are two series
if length(type) == 2
    [type, type2] = type{:};
else
    type = type{:};
end
    

% Make sure that gamma estimates exist
if isempty(obj.gamma_hat)
    error('Please estimate the groundwater law of motion')
end

% Project paths from model
[~,H_t,W_t,D_t] = obj.projectDepth('forwards', T, obj.D_0, obj.gamma_hat);

if both
    % Set up new waterDynamics object with rationing policy
    wd = obj;
    switch obj.policy.regime
        case 'pigouvian'
            wd.policy = waterPolicy('rationing');
            leglabels = {'Pigouvian','Rationing'};
        case 'rationing'
            wd.policy = waterPolicy('pigouvian');
            leglabels = {'Rationing','Pigouvian'};
    end
    wd = wd.assignGroundwaterConditions;
    
    % Estimate law of motion
    wd.gamma_hat = wd.estimateLawOfMotion;
    
    % Project paths
    [~,H_t_2, W_t_2, D_t_2] = wd.projectDepth('forwards', T, obj.D_0, obj.gamma_hat);
    
    % Concatenate vectors
    H_t = [H_t' H_t_2']';
    W_t = [W_t' W_t_2']';
    D_t = [D_t' D_t_2']';         
end
    

% Get series to plot
[path, lab, scale, ystep] = getSeriesFormat(type,H_t,W_t,D_t);
if exist('type2','var')
    [path2, lab2, scale2, ystep2] = getSeriesFormat(type2,H_t,W_t,D_t);
end
        

%% Plot

% Plot 
f0 = figure;

% Set x-axis limit
xlim([0 T-1])
set(gca,'XTick', [0:T/10:T],optfig.labProp{:}, ...
         'Box'         , 'off'              , ...
         'LineWidth'   ,  optfig.axisweight);

% If there are two different types of series to plot
if exist('type2','var')
    yyaxis left;
    ax = gca;
    ax.YAxis(1).Color = [0 0 0];
end

% Plot series 
p = plotOneSeries(T, path, type, both, lab, scale, ystep, 'black', optfig);

% Plot second series if it exists
if exist('type2','var')
    yyaxis right;
    b = plotOneSeries(T, path2, type2, both, lab2, scale2, ystep2, 'red', optfig);
    ax = gca;
    ax.YAxis(2).Color = [1 0 0];
end

% Title
titleString = sprintf(' $\\beta$: %1.2f, $\\alpha_W$: %1.2f',...
    obj.beta,obj.alpha_w);
title(titleString,optfig.textProp{:},'Interpreter','latex','FontName',optfig.fontname, 'FontSize', optfig.axlabelfontsize);

% Xlabel
xlabel('Year','interpreter', 'latex', 'FontName', optfig.fontname, 'FontSize', optfig.axlabelfontsize);

% Legend
if both
    legend([p(1) p(2)], leglabels{:},...
        'Location','southoutside',...
        'Orientation','vertical',...
        optfig.legProp{:});
    
    legend boxoff;
end

%% Export figure to file

% Crop whitespace 
fig = gcf;
fig.PaperPositionMode = 'auto';
fig_pos = fig.PaperPosition;
fig.PaperSize = [fig_pos(3) fig_pos(4)];

ax = gca;
outerpos = ax.OuterPosition;
ti = ax.TightInset;
left = outerpos(1) + ti(1);
bottom = outerpos(2) + ti(2);
ax_width = outerpos(3) - ti(1) - ti(3);
ax_height = outerpos(4) - ti(2) - ti(4);
ax.Position = [left bottom ax_width ax_height];

% Write to disk
fprintf(1,'Writing %s to file ...\n',filename);
print(f0,'-dpdf','-painters','-noui','-r600', filename);
        
    
end

function [path, lab, scale, ystep ] = getSeriesFormat(type,H_t,W_t,D_t)
    switch type
        case 'power'
            path = H_t;
            lab = 'Power use (INR/kWh)';
            scale = 4;
            ystep = 6;
        case 'water'
            path = W_t;
            lab = 'Water use (''000s liter)';
            scale = 1/100;
            ystep = 100;
        case 'depth'
            path = D_t;
            lab = 'Well depth (feet)';
            scale = 1/100;
            ystep = 40;
        otherwise
            error('Type has to be one of "power", "water", or "depth"');
    end
end

function [ p ] = plotOneSeries(T, path, type, both, lab, scale, ystep, color, optfig)

% Plot
p = plot(0:T-1,path,'Color',color,'LineWidth',optfig.axisweight);

% Set second plot dashed if two regimes
if both
    p(2).LineStyle = '--';
end

% Set y-axis limits
if strcmp(type,'power')
    ymin = 0;
    ymax = 24;
    ylim([ymin ymax]);
else
    ymin = floor(min(path,[],'all')*scale)/scale;
    ymax = ceil(max(path,[],'all')*scale)/scale;
    ylim([ymin ymax]);
end

% Axis labels
ylabel(lab,'interpreter', 'latex', 'FontName', optfig.fontname, 'FontSize', optfig.axlabelfontsize);

% Set figure properties
set(gcf, 'Color'       , 'w',...
    'position',[0 0 500 500]);
set(gca, optfig.labProp{:}, ...
         'Box'         , 'off'              , ...
         'LineWidth'   ,  optfig.axisweight , ...
         'YTick'       , [ymin:ystep:ymax]      , ...
         'XTick'       , [0:T/10:T]);

if strcmp(type,'depth')
    set(gca,'YDir','reverse');
end


end
