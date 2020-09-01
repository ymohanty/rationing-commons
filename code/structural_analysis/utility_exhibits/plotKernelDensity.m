function [ output_args ] = plotKernelDensity( y, x, xLabelString, bw, file )
%plotKernelDensity Plot kernel density of data
% INPUTS
%   y - Variable for which to plot density
%   x - Points at which to plot
%   xlabel - Label of the horizontal axis
%   file - File in which to print the plot
%
% OUTPUTS
%   A .pdf figure plotting the density of y.

%% Formatting options
textProp = {'fontsize'    , 22, ...
            'FontName'    , 'Times New Roman'};
labProp  = {'fontsize'    , 18, ...
            'FontName'    , textProp{4}};

%% Data to plot
[ fy ] = ksdensity( y, x, 'bandwidth', bw );

        
%% Plot PDF 
plot(x,fy,'b-' ,'LineWidth',2);  
hold on;

% Figure formatting
set(gcf, 'Color'       , 'w' );
set(gca, labProp{:}, ...
         'Box'         , 'off'              , ...
         'LineWidth'   , 1.5                , ...
         'PlotBoxAspectRatio', [1 0.5 0.5]);  
     
% Axis labels
xlabel(xLabelString,textProp{:},'Interpreter','latex');
ylabel('Probability density',textProp{:},'Interpreter','latex');
hold off;

%% Export figure to file
if file
    fprintf(1,'Writing %s to file ...',file);
    export_fig(file,'-painters','-m2');
    fprintf(1,' complete.\n');
end

end

