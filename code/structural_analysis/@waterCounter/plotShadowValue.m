function [ ] = plotShadowValue( obj, file, price_pigou, plotAtMeanObs )
%plotShadowValue Plot distribution of the shadow value of the ration across
% farmers and plots
%   
% INPUT :
%  obj         Counterfactual object in Pigouvian regime
%  price_opt   Optimal price
%
% OUTPUT :
%              Writes plot to file
if nargin < 2
    file = 0;
end

if nargin < 4
    plotAtMeanObs = false;
end

%% Formatting options
textProp = {'fontsize'    , 20, ...
            'FontName'    , 'Times New Roman'};
labProp  = {'fontsize'    , 18, ...
            'FontName'    , textProp{4}};
        
%% Data to plot

obj = obj.shadowValueOfRation;
sv = obj.fmplot.lambda_con_h + 0.90;

fprintf(1,'The shadow value of the ration has . . . \n');
fprintf(1,'\t\tMean: %4.2f\n',mean(sv));
fprintf(1,'\t\tMedian: %4.2f\n',median(sv));
fprintf(1,'\t\tStandard deviation: %4.2f\n',std(sv));

if plotAtMeanObs
    % Shadow value of ration with mean for observable characteristics
    obj = obj.shadowValueAtMean;
    svu = obj.fmplot.lambda_con_h_mean + 0.90;

    fprintf(1,'Setting observables at their mean, the shadow value has . . . \n');
    fprintf(1,'\t\tMean: %4.2f\n',mean(svu));
    fprintf(1,'\t\tMedian: %4.2f\n',median(svu));
    fprintf(1,'\t\tStandard deviation: %4.2f\n',std(svu));
end

%% Kernel density estimation on a grid

% Range over which to plot density
x = [ -2:0.25:50 ]';
fx = ksdensity( sv, x, 'bandwidth',0.2);

if plotAtMeanObs
    fy = ksdensity( svu, x, 'bandwidth',0.2);
end
    
%% Plot PDF first
f0 = figure;
plot(x,fx,'k-' ,'LineWidth',1.5);  
hold on;

yTickVector = [0:0.02:0.10];

if plotAtMeanObs
    plot(x,fy,'k--' ,'LineWidth',1.5);
    yTickVector = [0:0.05:0.15];
end
    
ylim([0 max(yTickVector)]);

% Figure formatting
set(gcf, 'Color'       , 'w' , ...
    'position', [0 0 600 500]);
set(gca, textProp{:}, ...
         'Box'         , 'off'              , ...
         'XTick'       , [-50:10:50]        , ...
         'YTick'       , yTickVector        , ...
         'LineWidth'   , 1.5                );  
     
% Axis labels
xlabel('Shadow cost of ration (INR/kWh)',textProp{:},'Interpreter','latex')
ylabel('Probability density',textProp{:},'Interpreter','latex')

% priceGap1 = obj.policy.power_cost - obj.policy.power_price;
% priceGap2 = price_pigou - obj.policy.power_price;

priceGap1 = obj.policy.power_cost;
priceGap2 = price_pigou;

% Vertical line
yl = ylim;
ylim manual; 
plot([priceGap1,priceGap1],[0,yl(2)],'--','LineWidth',1.5,'Color','red');
plot([priceGap2,priceGap2],[0,yl(2)],'--','LineWidth',1.5,'Color','red');

% Report share of farmers above twice the ration
share_below_sc = mean(sv < price_pigou);
share_above_2x = mean(sv > 2*price_pigou);

fprintf(1,['A share %3.2f of farmer-crops have shadow values below ', ...
    'social marginal cost.\n'],share_below_sc);

fprintf(1,['A share %3.2f of farmer-crops have shadow values above ', ...
    'twice the social marginal cost.\n'],share_above_2x);

% Text labels for vertical lines
text(priceGap1,0.94*yl(2),'Private cost ',textProp{:},...
    'HorizontalAlignment','right','Interpreter','latex');
text(priceGap1,0.88*yl(2),'$= c_E$ ',textProp{:},...
    'HorizontalAlignment','right','Interpreter','latex');

text(priceGap2+0.5,0.94*yl(2),'   Social marginal cost ',textProp{:},...
    'HorizontalAlignment','left','Interpreter','latex');
text(priceGap2+0.5,0.88*yl(2),' $\approx c_E + \frac{\rho}{\overline{D}} \lambda_W$ ',textProp{:},...
    'HorizontalAlignment','left','Interpreter','latex');

if plotAtMeanObs
    legend('Density with variation in unobservable productivity and observables',...
        'Density with variation in unobservable productivity only',...
        'Location','southoutside',...
        'Orientation','vertical');
    legend BOXOFF;
end

hold off;

%% Export figure to file
export_fig(f0,file);

end