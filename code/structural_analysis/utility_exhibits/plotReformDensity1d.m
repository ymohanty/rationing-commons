function [ ] = plotReformDensity1d( counters, file )
%plotReformDensity2d Plot 2-D distribution of land size and the change in
%  profits due to reform
%   
% INPUT :
%  obj         type model object with estimates of 2-D types
%
% OUTPUT :
%              Writes plot to file
if nargin < 2
    file = 0;
end

%% Formatting options
textProp = {'fontsize'    , 18, ...
            'FontName'    , 'Times New Roman'};
labProp  = {'fontsize'    , 18, ...
            'FontName'    , textProp{4}};
        
%% Data to plot

% Change in profit at fmplot X simulation level
deltaProfit = counters{2}.fmplot.profit - ...
              counters{1}.fmplot.profit;
% deltaProfitPct = 100* deltaProfit ./ counters{1}.fmplot.profit;

% Deciles of land size distribution
tau        = [ 25:25:100 ];
land       = counters{1}.fmplot.Land;
quantiles  = prctile(land,tau);
land_qtile = repmat(land,1,length(quantiles)) > ...
             repmat(quantiles,length(land),1);       
land_qtile = sum(land_qtile,2) + 1;
tabulate(land_qtile);
display(accumarray(land_qtile,land,[],@mean));

% Remove missing
x = [ land deltaProfit ];
x = x( ~any(isnan(x),2), : );

%% Kernel density estimation on a grid

% Range over which to plot density
xi_profit = [ -50:0.25:50 ]';
fxi       = zeros(length(xi_profit),length(tau));
bkeven    = zeros(length(tau),1);

for i=1:length(tau)
    fxi(:,i) = ksdensity( deltaProfit(land_qtile==i), xi_profit, ...
                        'bandwidth',2 );
    bkeven(i) = mean( deltaProfit(land_qtile==i) > 0 );
end
              
%% Plot PDF first
plot(xi_profit,fxi(:,1),'k-' ,'LineWidth',1.5);  
hold on;
plot(xi_profit,fxi(:,2),'k--' ,'LineWidth',1.5);  
plot(xi_profit,fxi(:,3),'k:' ,'LineWidth',1.5);  
plot(xi_profit,fxi(:,4),'k-.' ,'LineWidth',1.5);  

% Figure formatting
set(gcf, 'Color'       , 'w' );
set(gca, textProp{:}, ...
         'Box'         , 'off'              , ...
         'XTick'       , [-50:10:50]        , ...
         'LineWidth'   , 1.5                );  
     
% Axis labels
xlabel('Change in Profit (Pigouvian - Rationing) (INR thousands)',textProp{:},'Interpreter','latex')
ylabel('Probability density',textProp{:},'Interpreter','latex')

legend(sprintf('1st quartile of land: %2.0f%% positive',100*bkeven(1)),...
       sprintf('2nd quartile of land: %2.0f%% positive',100*bkeven(2)),...
       sprintf('3rd quartile of land: %2.0f%% positive',100*bkeven(3)),...
       sprintf('4th quartile of land: %2.0f%% positive',100*bkeven(4)),...
        'Location','southoutside',...
        'Orientation','vertical',...
        'FontName','Times New Roman',...
        'fontsize',18);
legend boxoff;

% Vertical line
yl = ylim;
ylim manual; 
plot([0,0],[0,yl(2)],'-','LineWidth',1,'Color',[0.1 0.1 0.1]);
hold off;

%% Export figure to file
if file
    fprintf(1,'Writing %s to file ...',file);
    export_fig(file,'-painters','-m2');
    fprintf(1,' complete.\n');
end