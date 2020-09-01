function [ ] = plotPlannersObjective( planner, pointsToPlot )
% plotReformRedistribution Plot distributional effects of reform from
%     rationing regime to Pigouvian regime
%
% INPUT :
%  planner      Planner object with counterfactual embedded therein
%  pointsToPlot Where to evaluate the objective function
%
% OUTPUT :
%               Writes plot to file

%% Formatting options
textProp = {'fontsize'    , 18, ...
            'FontName'    , 'Times New Roman'};
labProp  = {'fontsize'    , 18, ...
            'FontName'    , textProp{4}};
                
%% Data to plot
S = zeros(length(pointsToPlot),1);
for i = 1:length(pointsToPlot)   
    S(i) = planner.plannersObjective( pointsToPlot(i) );
end
   
%% Create plot
plot(pointsToPlot,S,'b-','LineWidth',2);  
hold on;

% Figure formatting
set(gcf, 'Color'       , 'w' );
set(gca, labProp{:}, ...
         'Box'         , 'off'              , ...
         'LineWidth'   , 1.5                , ...
         'PlotBoxAspectRatio', [1 0.75 0.75]);  
     
% Axis labels
xlabel('Policy instrument',textProp{:},'Interpreter','latex')
ylabel('Surplus (INR thousands)',textProp{:},'Interpreter','latex')
hold off;

% Export figure to file
% if file
%     fprintf(1,'Writing %s to file ...',file);
%     export_fig(file,'-painters','-m2');
%     fprintf(1,' complete.\n');
% end

end
