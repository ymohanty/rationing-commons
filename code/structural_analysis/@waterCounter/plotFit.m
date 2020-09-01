function [ ] = plotFit( obj, file_stub )
% plotFit plot the fit of a counterfactual with histograms of inputs and
%         outputs
%
% INPUT :
%  obj          waterModel object in which TFP is estimated
%  write        dummy for whether to write the bid object to a file
%
% OUTPUT :
%               Writes plot to file

%% Extract data and predictions for log output and all log inputs
vars = {'output','land','labor','capital','water'};

dataTable = obj.model.data.clean(:,['revenue' vars(2:end)]);
dataTable.Properties.VariableNames = vars;
cntrTable = obj.fmplot(:,vars);


%% Plot kernel density plots

% Parameters common to all plots
N       = 500;
pctiles = [ 0.1 99.9 ]; % Percentiles of data to plot

% Loop over variables
for i = 1:length(vars)
    fprintf(1,['Plotting density of log ',vars{i}]);
    
    % Set common range of plot
    rangeData = prctile(table2array(dataTable(:,vars{i})),pctiles);
    rangeCntr = prctile(table2array(cntrTable(:,vars{i})),pctiles);
    range     = [ min(rangeData(1),rangeCntr(1)) ...
                  max(rangeData(2),rangeCntr(2)) ];
    bw        = (range(2)-range(1))/20;
    
    % Plot data
    x      = linspace(range(1),range(2),N);
    y      = table2array(dataTable(:,vars{i}));
    xlabel = ['Log of ',vars{i},' in data'];
    file   = [file_stub,'_data_',vars{i},'.pdf'];
    plotKernelDensity(y,x,xlabel,bw,file);
       
    % Plot counterfactual
    y      = table2array(cntrTable(:,vars{i}));
    xlabel = ['Log of ',vars{i},' in counterfactual'];
    file   = [file_stub,'_counter_',vars{i},'.pdf'];
    plotKernelDensity(y,x,xlabel,bw,file);
    
end

end
