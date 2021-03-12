function [] = plotCounterFactualInputUse(counters, series, input, wins, scale, label, filename, optfig)
%PLOTCOUNTERFACTUALINPUTUSE Summary of this function goes here
%   Detailed explanation goes here

%% Get data

% Get counterfactual states
rationing = counters('rationing');
pigouvian = counters('pigouvian');

% Get correct data
switch series
    case 'sim'
        rationing = rationing.fmplot;
        pigouvian = pigouvian.fmplot;
    case 'fp'
        rationing = varfun(@nanmean, rationing.fmplot, 'GroupingVariables','farmer_plot_id');
        pigouvian = varfun(@nanmean, pigouvian.fmplot, 'GroupingVariables','farmer_plot_id');
        input = [ 'nanmean_' input];
end

% Get values
xval = rationing{:,input};
yval = pigouvian{:,input};

if wins
    vals = rmoutliers([xval yval], 'percentile', [0.5 99.5]);
    xval = vals(:,1);
    yval = vals(:,2);
end

% Label strings
xlab = [ label ' under rationing'];
ylab = [ label ' under Pigouvian pricing'];

% Axis limits
mini = floor(min([xval yval], [], 'all')* scale) / scale ;
mini = min(0,mini);
if strcmp(input, 'Hours') | strcmp(input, 'nanmean_Hours')
    maxi = floor(max([xval yval],[],'all') * scale) / scale;
else
    maxi = ceil(max([xval yval],[],'all') * scale) / scale;
end


%% Plot
f0 = figure;

% Main plot
scatter(xval,yval);

% Axis limits
xlim([mini maxi]);
ylim([mini maxi]);
ticklabs = mini:1/scale:maxi;

% Reference line (45 degree)
eq_line = refline([1 0]);
eq_line.LineStyle = '--';
eq_line.Color = 'black';
eq_line.LineWidth = optfig.axisweight;

% Formatting
set(gcf, 'Color'       , 'w',...
    'position',[0 0 500 500]);
set(gca, optfig.labProp{:}, ...
         'Box'         , 'off'              , ...
         'LineWidth'   ,  optfig.axisweight)
xticks(ticklabs);
yticks(ticklabs);

% Axis labels
xlabel(xlab,'interpreter', 'latex', 'FontName', optfig.fontname, 'FontSize', optfig.axlabelfontsize);
ylabel(ylab,'interpreter', 'latex', 'FontName', optfig.fontname, 'FontSize', optfig.axlabelfontsize);

%% Print
export_fig(f0,filename);

end

