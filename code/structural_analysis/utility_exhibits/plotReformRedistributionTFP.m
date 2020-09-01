function [ ] = plotReformRedistributionTFP( counters, file )
% plotReformRedistribution Plot distributional effects of reform from
%     rationing regime to Pigouvian regime
%
% INPUT :
%  counters     cell array of counterfactuals to compare
%  file         name of file to write plot
%
% OUTPUT :
%               Writes plot to file

%% Formatting options
textProp = {'fontsize'    , 18, ...
            'FontName'    , 'Times New Roman'};
labProp  = {'fontsize'    , 18, ...
            'FontName'    , textProp{4}};
                
%% Data to plot
%    Goal to compare farmer-level change in profit:
%      Pigouvian regime - Rationing regime

% Quantiles at which to plot value
tau = [ 4:4:100 ];

deltaOutput = counters{6}.farmer.output - ...
              counters{4}.farmer.output;
deltaOutputPct = 100* deltaOutput ./ counters{4}.farmer.output;

deltaProfit = counters{6}.farmer.profit - ...
              counters{4}.farmer.profit;
deltaProfitPct = 100* deltaProfit ./ counters{4}.farmer.profit;

% Deciles of productivity distribution
tfp        = counters{4}.farmer.omega_Eit;
quantiles  = prctile(tfp,tau);
tfp_qtile = repmat(tfp,1,length(tau)) > ...
             repmat(quantiles,length(tfp),1);
tfp_qtile = sum(tfp_qtile,2) + 1;
tabulate(tfp_qtile);

% Keep if profit and output exist
keep = ~isnan(counters{4}.farmer.output) & ...
       ~isnan(counters{4}.farmer.profit) & ...
       ~isinf(counters{6}.farmer.output) & ...
       ~isinf(counters{6}.farmer.output) & ...
       counters{4}.farmer.output ~= 0    & ...
       counters{4}.farmer.profit ~= 0;

% Data to plot
deltaOutputBin    = accumarray(tfp_qtile(keep),deltaOutput(keep),[],@mean);
deltaOutputPctBin = accumarray(tfp_qtile(keep),deltaOutputPct(keep),[],@median);

deltaProfitBin    = accumarray(tfp_qtile(keep),deltaProfit(keep),[],@mean);
deltaProfitPctBin = accumarray(tfp_qtile(keep),deltaProfitPct(keep),[],@median);

%% Absolute change
plot(tau/10,deltaProfitBin,'b-','LineWidth',2);  
hold on;
plot(tau/10,deltaOutputBin,'b--' ,'LineWidth',2);  

% Figure formatting
set(gcf, 'Color'       , 'w' );
set(gca, labProp{:}, ...
         'Box'         , 'off'              , ...
         'LineWidth'   , 1.5                , ...
         'XTick'       , [1:1:10]           , ...
         'PlotBoxAspectRatio', [1 0.75 0.75]);  
     
% Axis labels
xlabel('TFP decile',textProp{:},'Interpreter','latex')
ylabel('Pigouvian - Rationing (INR thousands)',textProp{:},'Interpreter','latex')

legend('Profit','Output',...
        'Location','southoutside',...
        'Orientation','horizontal',...
        'FontName','Times New Roman',...
        'fontsize',18);
legend boxoff;

% Horizontal line
plot([0,10],[0,0],'-','LineWidth',1.5,'Color',[0.2 0.2 0.2]);
hold off;

% Export figure to file
if file
    fprintf(1,'Writing %s to file ...',file);
    export_fig(file,'-painters','-m2');
    fprintf(1,' complete.\n');
end

clf;

%% Percent change
plot(tau/10,deltaProfitPctBin,'b-','LineWidth',2);  
hold on;
plot(tau/10,deltaOutputPctBin,'b--' ,'LineWidth',2);  

% Figure formatting
set(gcf, 'Color'       , 'w' );
set(gca, labProp{:}, ...
         'Box'         , 'off'              , ...
         'LineWidth'   , 1.5                , ...
         'XTick'       , [1:1:10]           , ...
         'PlotBoxAspectRatio', [1 0.75 0.75]);  
     
% Axis labels
xlabel('TFP decile',textProp{:},'Interpreter','latex')
ylabel('Pigouvian - Rationing (median $\%\Delta$)',textProp{:},...
    'Interpreter','latex')

legend('Profit','Output',...
        'Location','southoutside',...
        'Orientation','horizontal',...
        'FontName','Times New Roman',...
        'fontsize',18);
legend boxoff;

% Horizontal line
plot([0,10],[0,0],':','LineWidth',1.5,'Color',[0.2 0.2 0.2]);
hold off;

% Export figure to file
if file
    file = strrep(file,'.pdf','_pct.pdf');
    fprintf(1,'Writing %s to file ...',file);
    export_fig(file,'-painters','-m2');
    fprintf(1,' complete.\n');
end


end
