function [] = scatterValue(obj, xval, yval, xscale, yscale, xlab, ylab, series, wins, loess, filename, optfig)
%SCATTERVALUE Scatter shadow value of ration against profit

%% Get data
% Calculate shadow value of ration
obj = obj.shadowValueOfRation;

% Select correct series
switch series
    case 'sim'
        data = obj.fmplot;
    case 'fp'
        data = varfun(@nanmean, obj.fmplot, 'GroupingVariables','farmer_plot_id');
        xval = ['nanmean_' xval];
        yval = ['nanmean_' yval];
    case 'agg'
        data = obj.outcomes;
    otherwise
        error('The parameter ''series'' one of ''sim'',''fp'',or ''agg''');
end

% Get series
xval = data{:,xval};
yval = data{:,yval};
if strcmp(xval,'lambda_con_h') || strcmp(xval,'nanmean_lambda_con_h')
    xval = xval + 0.9;
elseif strcmp(yval,'lambda_con_h') || strcmp(yval,'nanmean_lambda_con_h')
    yval = yval + 0.9;
end


% Winsorize the data at right tail if requested
if wins
    vals = rmoutliers([xval yval],'percentiles',[1 98]);
    xval = vals(:,1);
    yval = vals(:,2);
end

% Kernel regression to smooth data
if loess
    [~,bHat] = nadaraya_watson(xval,yval,20);
    X    = linspace(min(xval),max(xval));
    bSm  = arrayfun(bHat,X);
end

% Limits
xmin = floor(min(xval)*xscale)/xscale;
xmax = ceil(max(xval)*xscale)/xscale;

ymin  = floor(min(yval)*yscale)/yscale;
ymax = ceil(max(yval)*yscale)/yscale;

%% Plot
f0 = figure; 

% Scatter plot
scatter(xval,yval);

% Loess plot
if loess
    hold on;
    plot(X,bSm,'r-','LineWidth',2);
end
    
% Axis limits
xlim([xmin xmax]);
ylim([ymin ymax]);

% Axis labels
xlabel(xlab,'interpreter', 'latex', 'FontName', optfig.fontname, 'FontSize', optfig.axlabelfontsize);
ylabel(ylab,'interpreter', 'latex', 'FontName', optfig.fontname, 'FontSize', optfig.axlabelfontsize);

% Set figure properties
set(gcf, 'Color'       , 'w',...
    'position',[0 0 500 500]);
set(gca, optfig.labProp{:}, ...
         'Box'         , 'off'              , ...
         'LineWidth'   ,  optfig.axisweight );
     
% Set ticks
xticks(xmin:1/xscale:xmax);
yticks(ymin:1/yscale:ymax);


%% Print
export_fig(f0,filename);

end

