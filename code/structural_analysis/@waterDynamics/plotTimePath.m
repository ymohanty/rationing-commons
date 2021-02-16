function plotTimePath(obj, type, both, T, filename, optfig)
%% Plot the time path of water extracted by the farmer
% 
% INPUTS:
%   type: One of {'power','water','depth'}
%   both: Plot both pigouvian and rationing regime
%   T: vector of time
%   W_t: Vector of water extraction ('000 liter/yr)
%   optfig: Struct of figure paramaters
%   sdo: Name of the SDO
% 
% OUTPUTS:
%       
%

%% Get data

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
    

% Select series to plot
switch type
    case 'power'
        path = H_t;
        lab = '$H_t^{*}$';
        scale = 4;
        ystep = 6;
    case 'water'
        path = W_t;
        lab = '$W_t^{*}$';
        scale = 1/100;
        ystep = 100;
    case 'depth'
        path = D_t;
        lab = '$D_t$';
        scale = 1/100;
        ystep = 40;
    otherwise
        error('Type has to be one of "power", "water", or "depth"');
end

%% Plot

% Plot 
f0 = figure;
p = plot(0:T-1,path,'Color','black','LineWidth',optfig.axisweight);

% Set second plot dashed
if both
    p(2).LineStyle = '--';
end

% Set axis limits
xlim([0 T-1])

if strcmp(type,'power')
    ymin = 0;
    ymax = 24;
    ylim([ymin ymax]);
else
    ymin = floor(min(path,[],'all')*scale)/scale;
    ymax = ceil(max(path,[],'all')*scale)/scale;
    ylim([ymin ymax]);
end

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

% Title
titleString = sprintf(' $\\beta$: %1.2f, $\\alpha_W$: %1.2f',...
    obj.beta,obj.alpha_w);
title(titleString,optfig.textProp{:},'Interpreter','latex','FontName',optfig.fontname, 'FontSize', optfig.axlabelfontsize);
     
% Axis labels
xlabel('$t$','interpreter', 'latex', 'FontName', optfig.fontname, 'FontSize', optfig.axlabelfontsize);
ylabel(lab,'interpreter', 'latex', 'FontName', optfig.fontname, 'FontSize', optfig.axlabelfontsize);

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
